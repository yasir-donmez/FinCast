import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supabase Authentication Service
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Stream of Auth State changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign Up with Email and Password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign In with Email and Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign In with Google
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // For mobile, you might need a redirectTo URL configured in Supabase
    );
  }

  /// Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

/// Riverpod Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Riverpod StreamProvider for Auth State
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
