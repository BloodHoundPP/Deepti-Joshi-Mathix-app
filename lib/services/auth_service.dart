import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  /// Get active Supabase client
  static SupabaseClient? get _client {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Whether Supabase Cloud Auth is configured and ready
  static bool get isCloudReady => _client != null;

  /// Get the current authenticated user from Supabase
  static User? get currentSupabaseUser => _client?.auth.currentUser;

  /// Check if teacher is currently logged in via Supabase Auth
  static Future<bool> isAuthenticated() async {
    return isCloudReady && _client?.auth.currentSession != null;
  }

  /// Get the display email for the teacher
  static Future<String> getTeacherEmail() async {
    if (isCloudReady && currentSupabaseUser?.email != null) {
      return currentSupabaseUser!.email!;
    }
    return '';
  }

  /// Stream of Supabase Auth state changes
  static Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  /// Sign in with Email and Password using Supabase Auth
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Database is not configured yet. Please check your Supabase credentials.');
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('Supabase Auth error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected sign in error: $e');
      rethrow;
    }
  }

  /// Sign up a new teacher with Email and Password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured yet. Please configure your .env file.');
    }

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName.trim(), 'role': 'teacher'}
            : {'role': 'teacher'},
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('Supabase SignUp error: ${e.message}');
      rethrow;
    }
  }

  /// Send password reset email to teacher
  static Future<void> sendPasswordResetEmail(String email) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured yet.');
    }

    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      rethrow;
    }
  }

  /// Sign out the current teacher
  static Future<void> signOut() async {
    try {
      if (isCloudReady) {
        await _client?.auth.signOut();
      }
    } catch (e) {
      debugPrint('Supabase sign out warning: $e');
    }
  }
}
