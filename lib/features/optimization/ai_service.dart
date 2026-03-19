import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/database/models/transaction_record.dart';
import '../../core/database/models/vault.dart';
import '../../core/database/models/financial_goal.dart';

/// Gemini AI entegrasyonu — Persona üretimi + Tasarruf stratejisi
class AiService {
  // API Key'i buraya güvenli şekilde alıyoruz.
  // Gerçek projede --dart-define veya .env dosyasından alınmalı.
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  static GenerativeModel? _model;

  static GenerativeModel _getModel() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Gemini API Key bulunamadı. '
        'flutter run --dart-define=GEMINI_API_KEY=your_key_here ile başlatın.',
      );
    }
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
      ),
    );
    return _model!;
  }

  /// API anahtarı var mı ve internet bağlantısı kurulabilir mi kontrol et
  static bool get isAvailable => _apiKey.isNotEmpty;

  // =====================
  // PERSONA ÜRETME
  // =====================

  /// Kullanıcının verilerinden finansal persona metni üretir.
  /// Analiz başında çağrılır, daha sonra onay alınırsa kaydedilir.
  static Future<String> generatePersona({
    required List<TransactionRecord> allTransactions,
    required List<Vault> vaults,
    List<FinancialGoal> previousGoals = const [],
  }) async {
    final model = _getModel();

    // Anonim özet hazırla
    final totalBalance = vaults.fold(0.0, (sum, v) => sum + v.balance);
    final incomes = allTransactions.where((t) => t.isIncome && !t.isArchived);
    final expenses = allTransactions.where((t) => !t.isIncome && !t.isArchived);

    final totalMonthlyIncome = incomes
        .where((t) => t.periodType == 2)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalMonthlyExpense = expenses
        .where((t) => t.periodType == 2)
        .fold(0.0, (sum, t) => sum + t.amount);

    final lockedCount = expenses.where((t) => t.isLocked).length;
    final flexibleCount = expenses.where((t) => !t.isLocked).length;

    // Kategori özetleri (anonim - sadece başlık ve tutar)
    final categoryMap = <String, double>{};
    for (final tx in expenses.where((t) => !t.isLocked)) {
      categoryMap[tx.title] = (categoryMap[tx.title] ?? 0) + tx.amount;
    }
    final topCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topStr = topCategories
        .take(5)
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(0)} TL')
        .join(', ');

    final prevApprovals = previousGoals.where((g) => g.userApproved == true).length;
    final prevRejections = previousGoals.where((g) => g.userApproved == false).length;

    final prompt = '''
Sen bir finansal koç yapay zekasısın. Aşağıdaki kullanıcı verilerini analiz et ve
kullanıcıyı yargılamayan, çok detaya inip onu tek bir harcamasından dolayı etiketlemeyen, 
yapıcı, vizyoner ve motive edici, 2-3 cümlelik bir "Finansal Kimlik" (Persona) metni yaz.

Veriler (anonim):
- Toplam bakiye: ${totalBalance.toStringAsFixed(0)} TL
- Aylık gelir: ${totalMonthlyIncome.toStringAsFixed(0)} TL
- Aylık gider (esnek): ${totalMonthlyExpense.toStringAsFixed(0)} TL
- Kilitli gider sayısı: $lockedCount, Esnek gider sayısı: $flexibleCount
- En öne çıkan gider kategorileri: $topStr
- Geçmiş onaylanan analiz sayısı: $prevApprovals
- Geçmiş reddedilen analiz sayısı: $prevRejections

KURALLAR:
1. Kullanıcının spesifik harcamalarıyla (örn: Fast Food, Oyun) ilgili kınayıcı, aşırı spesifik veya olumsuz çıkarımlar yapma.
2. Olayın büyük finansal resmine profesyonel bir koç gibi yaklaşarak genel ve motive edici bir profil çıkar.
3. Persona kısa olsun (~2-3 cümle), insansı, yapıcı ve umut verici olsun.

JSON formatında döndür: {"persona": "metin buraya"}
''';

    final response = await model.generateContent([Content.text(prompt)]).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('API isteği zaman aşımına uğradı (30s). Lütfen internet bağlantınızı kontrol edin.'),
    );
    final text = response.text ?? '{}';
    // JSON parse
    final jsonStr = text.contains('{') ? text : '{"persona": "$text"}';
    final cleaned = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();

    // Basit parse
    final match = RegExp(r'"persona"\s*:\s*"([^"]+)"').firstMatch(cleaned);
    return match?.group(1) ?? 'Finansal yolculuğun başlıyor. Hedeflerine adım adım yaklaşıyorsun.';
  }

  // =====================
  // STRATEJİ ÜRETME
  // =====================

  /// Matematiksel bağlam paketini alıp AI stratejisi üretir.
  /// Sadece tasarruf açığı varsa ve internet mevcutsa çağrılır.
  static Future<OptimizationResult> generateStrategy({
    required double requiredMonthlySaving,
    required List<CategoryContext> flexibleCategories,
    required List<String> rejectedCategories,
    required double targetAmount,
    required int monthsToGoal,
  }) async {
    final model = _getModel();

    final categoriesStr = flexibleCategories.map((c) {
      final minStr = c.minAmount != null ? ', min: ${c.minAmount!.toStringAsFixed(0)}' : '';
      final maxStr = c.maxAmount != null ? ', max: ${c.maxAmount!.toStringAsFixed(0)}' : '';
      final varStr = c.coefficientOfVariation != null
          ? ', değişkenlik: %${(c.coefficientOfVariation! * 100).toStringAsFixed(0)}'
          : '';
      String periodStr = '';
      if (c.periodType == 1) periodStr = ' (Haftalık)';
      if (c.periodType == 4) periodStr = ' (2 Haftada Bir)';
      if (c.periodType == 5) periodStr = ' (3 Haftada Bir)';
      if (c.periodType == 2) periodStr = ' (Aylık)';
      if (c.periodType == 6) periodStr = ' (3 Ayda Bir)';
      if (c.periodType == 7) periodStr = ' (6 Ayda Bir)';
      if (c.periodType == 3) periodStr = ' (Yıllık)';
      return '- ${c.name}$periodStr: tutar ${c.currentAmount.toStringAsFixed(0)} TL$minStr$maxStr$varStr (KategID: ${c.name})';
    }).join('\n');

    final rejectedStr = rejectedCategories.isEmpty
        ? 'Yok'
        : rejectedCategories.join(', ');

    final prompt = '''
Sen bir finansal optimizasyon yapay zekasısın. Kullanıcıya aylık tasarruf planı üret.

Veriler:
- Gereken aylık tasarruf: ${requiredMonthlySaving.toStringAsFixed(0)} TL
- Hedefe kalan ay: $monthsToGoal ay
- Kullanıcının daha önce reddettiği kategoriler: $rejectedStr

Kısılabilir harcama kategorileri:
$categoriesStr

KURALLAR:
1. Temel İhtiyaç Önceliği: Kira, Fatura, Market, Temizlik, Sağlık, Ulaşım gibi yaşamsal ve temel ihtiyaç kategorilerini en son kes. DİKKAT: Bu kalemleri asla tamamen sıfırlama veya 10, 50 gibi gerçek dışı, o ülkenin/para biriminin şartlarında yaşanılamaz tutarlara düşürme. Bir insanın aylık asgari hayatta kalma maliyetini düşün. Eğer bu kategoriler için "min" değeri verilmişse bu değer KESİN bir alt sınırdır (hard limit), altına kesinlikle inemezsin. Eğer "min" verilmemişse, verilen para birimi ve tutarlardaki genel yaşam standartlarına göre mantıklı ve gerçekçi bir alt sınır belirle ve o sınırda dur.
2. Lüks ve İsteklerin Kesilmesi: Fast Food, Oyun, Eğlence, Yemek, Abonelikler gibi isteğe bağlı harcamaları ilk önce kes. Hedefe ulaşmak için gerekiyorsa bunları çekinmeden 0'a indirebilirsin.
3. Gerçekçilik ve Yapıcılık: Gerekçe (reason) alanını doldururken aşırı spesifik veya yargılayıcı olma. Daha profesyonel, yapıcı ve stratejik ifadeler kullan. ("İsteğe bağlı bir harcama kalemi olduğu için öncelikli olarak kısıldı" vb.)
4. Değişkenlik Faktörü: Kişiye özgü düşün; değişken harcamalar (yüksek değişkenlik yüzdesi) daha kolay kesilebilir, tutarlı/sabit tutarlara ise son çare olarak dokun.
5. Periyot / Sıklık Değişimi Önerileri (ÖNEMLİ!): Eğer bir harcamanın periyodu düzenliyse, bunu sadece tutarı düşürerek değil, daha seyrek periyotlara taşıyarak da kısıtlama tavsiyesi verebilirsin. Yeni periyot sistemi: Haftada Bir(1), 2 Haftada Bir(4), 3 Haftada Bir(5), Ayda Bir(2), 3 Ayda Bir(6), 6 Ayda Bir(7), Yılda Bir(3), Günlük(8), 2 Günde Bir(9), 3 Günde Bir(10). Örneğin Haftalık 800 TL olan bir harcamayı "2 Haftada Bir 800 TL"ye veya "Aylık 1500 TL"ye uyarlayıp gerekçesine "Periyodu haftalıktan 2 haftada bire/aylığa çekerek tasarruf sağlandı" yazabilirsin. Değerleri hesaplarken yıllık tutarlar üzerinden matematiksel işlem yap.
6. Hata Yanıtı: Eğer kategoriler hiç kısılamayacak durumdaysa JSON formatında boş "cuts" döndür ve "coachMessage" kısmında açıklama yap.
7. Reddettiği kategoriler (kullanıcının kısmak istemediği) son çare olarak değerlendirilmelidir.
8. Toplamda gereken tasarrufu tam olarak karşıla; eksik veya fazla kesinti yapma.

JSON formatında döndür:
{
  "cuts": [
    {
      "category": "Kategori Adı", 
      "currentAmount": 0, 
      "suggestedAmount": 0, 
      "suggestedMin": 0,
      "suggestedMax": 0,
      "newPeriod": 2,
      "saving": 0, 
      "reason": "Kısa ve yapıcı gerekçe (örn: Haftalık gider, aylık periyoda çekilerek azaltıldı)"
    }
  ],
  "coachMessage": "2-3 cümle motive edici koç mesajı",
  "isFeasible": true
}
Not: Eğer periyot değişimi önermiyorsan "newPeriod" alanını işlemin mevcut periyoduyla aynı bırak. "suggestedMin" ve "suggestedMax" alanlarını, önerdiğin yeni tutar etrafında mantıklı bir esneklik payı (range) olarak belirle. Eğer işlem sabitse ikisini de "suggestedAmount" ile aynı yapabilirsin.
''';

    final response = await model.generateContent([Content.text(prompt)]).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('API isteği zaman aşımına uğradı (30s). Lütfen internet bağlantınızı kontrol edin.'),
    );
    final text = response.text ?? '{}';
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();

    return OptimizationResult.fromJson(cleaned);
  }
}

/// Bir kategori hakkında AI'ya gönderilecek bağlam bilgisi
class CategoryContext {
  final String name;
  final double currentAmount;
  final double? minAmount;
  final double? maxAmount;
  /// Varyasyon katsayısı: standart sapma / ortalama (0-1 arası; yüksek = değişken)
  final double? coefficientOfVariation;
  /// Periyot Tipi (0: Tek Seferlik, 1: Haftalık, 2: Aylık, 3: Yıllık)
  final int periodType;

  const CategoryContext({
    required this.name,
    required this.currentAmount,
    this.minAmount,
    this.maxAmount,
    this.coefficientOfVariation,
    this.periodType = 0,
  });
}

/// AI'dan gelen optimizasyon sonucu
class OptimizationResult {
  final List<CutSuggestion> cuts;
  final String coachMessage;
  final bool isFeasible;

  const OptimizationResult({
    required this.cuts,
    required this.coachMessage,
    required this.isFeasible,
  });

  factory OptimizationResult.fromJson(String jsonStr) {
    try {
      // Basit regex tabanlı parse (google_generative_ai JSON mode kullanıldığı için güvenli)
      final cutsMatch = RegExp(r'"cuts"\s*:\s*\[([^\]]*)\]', dotAll: true).firstMatch(jsonStr);
      final coachMatch = RegExp(r'"coachMessage"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
      final feasibleMatch = RegExp(r'"isFeasible"\s*:\s*(true|false)').firstMatch(jsonStr);

      final cuts = <CutSuggestion>[];
      if (cutsMatch != null) {
        final cutsStr = cutsMatch.group(1) ?? '';
        final categoryMatches = RegExp(
          r'"category"\s*:\s*"([^"]+)".*?"currentAmount"\s*:\s*([\d.]+).*?"suggestedAmount"\s*:\s*([\d.]+).*?"suggestedMin"\s*:\s*([\d.]+).*?"suggestedMax"\s*:\s*([\d.]+).*?"newPeriod"\s*:\s*(\d+).*?"saving"\s*:\s*([\d.]+).*?"reason"\s*:\s*"([^"]+)"',
          dotAll: true,
        ).allMatches(cutsStr);

        for (final m in categoryMatches) {
          cuts.add(CutSuggestion(
            category: m.group(1) ?? '',
            currentAmount: double.tryParse(m.group(2) ?? '0') ?? 0,
            suggestedAmount: double.tryParse(m.group(3) ?? '0') ?? 0,
            suggestedMin: double.tryParse(m.group(4) ?? '0'),
            suggestedMax: double.tryParse(m.group(5) ?? '0'),
            newPeriod: int.tryParse(m.group(6) ?? ''),
            saving: double.tryParse(m.group(7) ?? '0') ?? 0,
            reason: m.group(8) ?? '',
          ));
        }
      }

      return OptimizationResult(
        cuts: cuts,
        coachMessage: coachMatch?.group(1) ?? 'Hedefe adım adım yaklaşıyorsun!',
        isFeasible: feasibleMatch?.group(1) == 'true',
      );
    } catch (_) {
      return const OptimizationResult(
        cuts: [],
        coachMessage: 'Analiz tamamlandı. Hedefine ulaşmak için bazı düzenlemeler gerekiyor.',
        isFeasible: true,
      );
    }
  }
}

/// Bir kategoride yapılacak kesinti önerisi
class CutSuggestion {
  final String category;
  final double currentAmount;
  final double suggestedAmount;
  final double? suggestedMin;
  final double? suggestedMax;
  final int? newPeriod;
  final double saving;
  final String reason;

  const CutSuggestion({
    required this.category,
    required this.currentAmount,
    required this.suggestedAmount,
    this.suggestedMin,
    this.suggestedMax,
    this.newPeriod,
    required this.saving,
    required this.reason,
  });
}
