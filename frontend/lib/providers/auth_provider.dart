import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final String? accessToken;

  bool get isAuthenticated => user != null && accessToken != null;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.accessToken,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    String? accessToken,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      accessToken: clearUser ? null : (accessToken ?? this.accessToken),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  StreamSubscription? _authSubscription;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initialize();
  }

  /// Listen to Supabase auth state changes and restore session on startup.
  void _initialize() {
    // Check if there's already an active session (app restart / token refresh)
    final currentUser = _authService.currentUser;
    final currentToken = _authService.accessToken;

    if (currentUser != null && currentToken != null) {
      state = state.copyWith(
        user: _mapSupabaseUser(currentUser),
        accessToken: currentToken,
      );
    }

    // Listen for auth changes (login, logout, token refresh)
    _authSubscription = _authService.authStateChanges.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (session?.user != null) {
          state = state.copyWith(
            user: _mapSupabaseUser(session!.user),
            accessToken: session.accessToken,
            isLoading: false,
            clearError: true,
          );
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthState();
      }
    });
  }

  /// Map Supabase User to our UserModel.
  UserModel _mapSupabaseUser(User user) {
    final metadata = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: metadata['full_name'] as String? ??
          metadata['name'] as String? ??
          '',
      avatarUrl: metadata['avatar_url'] as String? ??
          metadata['picture'] as String? ??
          '',
    );
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        state = state.copyWith(
          isLoading: false,
          user: _mapSupabaseUser(response.user!),
          accessToken: response.session!.accessToken,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed. Please check your credentials.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseAuthError(e),
      );
    }
  }

  /// Sign up with email and password.
  Future<void> signUpWithEmail(String email, String password, {String? fullName}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        if (response.session != null) {
          // Auto-confirmed (email confirmation disabled in Supabase)
          state = state.copyWith(
            isLoading: false,
            user: _mapSupabaseUser(response.user!),
            accessToken: response.session!.accessToken,
          );
        } else {
          // Email confirmation required
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Check your email to confirm your account.',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Signup failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseAuthError(e),
      );
    }
  }

  /// Sign in with Clerk via Supabase OAuth.
  Future<void> signInWithClerk() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _authService.signInWithClerk();
      if (!success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Clerk login was cancelled or failed.',
        );
      }
      // If success, the auth state listener will handle the rest
      // (Supabase redirects back and fires AuthChangeEvent.signedIn)
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseAuthError(e),
      );
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
    } catch (_) {}
    state = const AuthState();
  }

  /// Parse Supabase auth errors into user-friendly messages.
  String _parseAuthError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Please check your connection.';
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService();
  return AuthNotifier(authService);
});
