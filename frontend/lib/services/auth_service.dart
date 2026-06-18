import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Session? get currentSession => _supabase.auth.currentSession;

  String? get accessToken => currentSession?.accessToken;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with email and password (Supabase native email auth).
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// Sign in with Clerk via Supabase OAuth.
  /// Clerk is configured as a third-party provider in Supabase Auth settings.
  Future<bool> signInWithClerk() async {
    return await _supabase.auth.signInWithOAuth(
      const OAuthProvider('clerk'),
    );
  }

  /// Sign out and clear session.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Recover session from stored refresh token (auto-handled by supabase_flutter).
  Future<Session?> recoverSession() async {
    final session = _supabase.auth.currentSession;
    return session;
  }
}
