import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<Session?> onAuthState() =>
      _client.auth.onAuthStateChange.map((e) => e.session);

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUpEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();

    // Fast, accurate pre-check via RPC (auth.users, case-insensitive)
    try {
      final exists = await _client.rpc('email_exists', params: {
        'p_email': normalizedEmail,
      }) as bool;
      if (exists) {
        throw AuthException('User already registered', statusCode: '400');
      }
    } catch (e) {
      // If RPC not found or fails, continue (Supabase/Auth flow will be next safety net)
      if (e is AuthException) rethrow;
    }

    try {
      final response = await _client.auth.signUp(email: email, password: password);

      // If Supabase returns null user, treat as duplicate/signup failed
      if (response.user == null) {
        throw AuthException('User already registered', statusCode: '400');
      }

      return response;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already') ||
          msg.contains('registered') ||
          msg.contains('exists') ||
          msg.contains('duplicate')) {
        throw AuthException('User already registered', statusCode: e.statusCode ?? '400');
      }
      rethrow;
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already') ||
          msg.contains('duplicate') ||
          msg.contains('unique constraint') ||
          e.code == '23505') {
        throw AuthException('User already registered', statusCode: '400');
      }
      rethrow;
    }
  }

  Future<AuthResponse> signInEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPasswordEmail({required String email}) {
    return _client.auth.resetPasswordForEmail(email);
  }

  // Magic Link (OTP) - untuk login/verifikasi tanpa password
  Future<void> signInWithOtp({
    required String email,
    String? redirectTo,
  }) {
    return _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo ?? 'com.miqra.app://login-callback',
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  // Google OAuth – membutuhkan setup deep link (lihat instruksi)
  Future<void> signInWithGoogle({String? redirectTo}) async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo, // ex: com.miqra.app://login-callback
    );
  }
}
