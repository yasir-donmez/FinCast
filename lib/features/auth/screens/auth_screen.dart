import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/main_scaffold.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_constants.dart';
import '../../../shared/widgets/neu_button.dart';
import '../../../shared/widgets/neu_container.dart';
import '../../../shared/widgets/neu_text_field.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        await authService.signIn(email: email, password: password);
      } else {
        await authService.signUp(email: email, password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')),
          );
          setState(() => _isLogin = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Giriş Hatası: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Logo or Icon
                NeuContainer(
                  width: 100,
                  height: 100,
                  borderRadius: 50,
                  child: Center(
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: AppColors.getPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _isLogin ? 'Hoş Geldiniz' : 'Hesap Oluştur',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Devam etmek için giriş yapın' : 'Hemen sisteme dahil olun',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),

                // Form
                NeuTextField(
                  controller: _emailController,
                  hintText: 'E-posta',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                NeuTextField(
                  controller: _passwordController,
                  hintText: 'Şifre',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 40),

                // Submit Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : NeuButton(
                        onTap: _submit,
                        width: double.infinity,
                        isPrimary: true,
                        child: Text(
                          _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                          style: TextStyle(
                            color: AppColors.getTextPrimary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                const SizedBox(height: 32),

                // Google Button
                if (_isLogin) ...[
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.getTextSecondary(context).withValues(alpha: 0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Veya', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Expanded(child: Divider(color: AppColors.getTextSecondary(context).withValues(alpha: 0.2))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  NeuButton(
                    onTap: _signInWithGoogle,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, size: 28, color: AppColors.getTextPrimary(context)),
                        const SizedBox(width: 8),
                        const Text('Google ile Devam Et'),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainScaffold()),
                    );
                  },
                  child: Text(
                    'Giriş Yapmadan Devam Et',
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    _isLogin ? 'Hesabınız yok mu? Kayıt Olun' : 'Zaten hesabınız var mı? Giriş Yapın',
                    style: TextStyle(color: AppColors.getPrimary(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
