import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final SupabaseClient? _supabase;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    SupabaseClient? supabase,
    GoogleSignIn? googleSignIn,
  })  : _supabase = supabase,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  SupabaseClient? get _clientOrNull {
    final client = _supabase;
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  SupabaseClient get _client {
    final client = _clientOrNull;
    if (client == null) {
      throw Exception(
        'Supabase not initialized. Please ensure Supabase.initialize() '
        'is called before using AuthRepository.',
      );
    }
    return client;
  }

  // Check if email already exists in profiles
  Future<bool> _checkEmailExists(String email) async {
    try {
      // Check in profiles table (case-insensitive)
      final existingUser = await _client
          .from('profiles')
          .select('email')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();
      
      return existingUser != null;
    } catch (e) {
      // If error checking, assume email doesn't exist (let Supabase handle it)
      return false;
    }
  }

  // Sign up with email and password
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Check if email already exists in profiles
      final emailExists = await _checkEmailExists(email);
      if (emailExists) {
        throw Exception('This email is already registered. Please sign in instead.');
      }

      // Try to signup
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: 'miqra://auth',
      );

      // Check if user was created
      if (response.user == null) {
        // User not created - could be duplicate email in auth.users
        // Try to sign in to check if user exists in auth.users
        try {
          final signInResponse = await _client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          
          // User exists in auth.users - check if profile exists
          if (signInResponse.user != null) {
            final profileExists = await _checkProfileExists(signInResponse.user!.id);
            if (profileExists) {
              // Profile exists - user should sign in (DUPLICATE EMAIL)
              throw Exception('This email is already registered. Please sign in instead.');
            } else {
              // Orphaned user: exists in auth.users but no profile
              // Create profile for existing user with provided fullName
              await _createUserProfile(signInResponse.user!, fullNameOverride: fullName);
              // Resend verification email if not verified
              if (!isEmailVerified(signInResponse.user!)) {
                await _client.auth.resend(
                  type: OtpType.signup,
                  email: email,
                  emailRedirectTo: 'miqra://auth',
                );
              }
              return signInResponse.user!;
            }
          }
        } on AuthException catch (signInError) {
          // Sign in failed - check error type
          final errorMsg = signInError.message.toLowerCase();
          
          // If "Invalid login credentials", email exists in auth.users but password wrong
          if (errorMsg.contains('invalid login') || 
              errorMsg.contains('invalid credentials') ||
              errorMsg.contains('email not confirmed')) {
            // Email exists in auth.users - check profile
            final emailExistsNow = await _checkEmailExists(email);
            if (emailExistsNow) {
              throw Exception('This email is already registered. Please sign in instead.');
            }
            // Email exists in auth.users but profile doesn't exist
            // This shouldn't happen, but handle it anyway
            throw Exception('This email is already registered. Please sign in instead.');
          }
          // Other auth errors - rethrow
          throw Exception('This email is already registered. Please sign in instead.');
        } catch (signInError) {
          // Non-auth errors - check if email exists in profiles
          final emailExistsNow = await _checkEmailExists(email);
          if (emailExistsNow) {
            throw Exception('This email is already registered. Please sign in instead.');
          }
          // If sign in fails with "Invalid login credentials", email exists in auth.users
          if (signInError.toString().toLowerCase().contains('invalid login') ||
              signInError.toString().toLowerCase().contains('invalid credentials')) {
            throw Exception('This email is already registered. Please sign in instead.');
          }
        }
        throw Exception('Failed to create user. Please try again.');
      }
      
      // User was created - check if email exists in profiles (race condition check)
      // This handles case where email was registered between our check and signup
      final emailExistsAfterSignup = await _checkEmailExists(email);
      if (emailExistsAfterSignup && response.user != null) {
        // Check if it's the same user or different user
        final existingProfile = await _client
            .from('profiles')
            .select('id')
            .eq('email', email.toLowerCase().trim())
            .maybeSingle();
        
        if (existingProfile != null && existingProfile['id'] != response.user!.id) {
          // Different user with same email - this shouldn't happen but handle it
          throw Exception('This email is already registered. Please sign in instead.');
        }
      }

      // Profile, settings, and streaks are auto-created by database trigger
      // Wait a bit for trigger to complete, then verify
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify profile was created by trigger
      final profileExists = await _checkProfileExists(response.user!.id);
      if (!profileExists) {
        // Only create manually if trigger failed (fallback)
        // This should rarely happen, but provides safety net
        try {
          await _createUserProfile(response.user!);
        } catch (e) {
          // If manual creation also fails, check one more time
          // (might be race condition)
          await Future.delayed(const Duration(milliseconds: 500));
          final stillNotExists = await _checkProfileExists(response.user!.id);
          if (stillNotExists) {
            rethrow; // Re-throw if profile really doesn't exist after retry
          }
        }
      }
      
      // Final check: verify email is not duplicate (double-check after profile creation)
      // This catches any edge cases where duplicate email might have been created
      final finalEmailCheck = await _client
          .from('profiles')
          .select('id, email')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();
      
      if (finalEmailCheck != null) {
        final profileId = finalEmailCheck['id'] as String?;
        // If profile exists but ID doesn't match, it's a duplicate
        if (profileId != null && profileId != response.user!.id) {
          throw Exception('This email is already registered. Please sign in instead.');
        }
      }

      return response.user!;
    } on AuthException catch (e) {
      // Handle Supabase auth errors (including duplicate email)
      final errorMsg = e.message.toLowerCase();
      if (errorMsg.contains('already registered') || 
          errorMsg.contains('already exists') ||
          errorMsg.contains('user already registered') ||
          errorMsg.contains('email address is already') ||
          errorMsg.contains('email already in use') ||
          errorMsg.contains('user with this email already exists')) {
        throw Exception('This email is already registered. Please sign in instead.');
      }
      throw Exception(e.message);
    } catch (e) {
      // Check error message for duplicate email patterns
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already registered') || 
          errorMsg.contains('already exists') ||
          errorMsg.contains('email already')) {
        throw Exception('This email is already registered. Please sign in instead.');
      }
      // Re-throw other errors
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to sign in');
    }

    return response.user!;
  }

  // Sign in with Google
  Future<User> signInWithGoogle() async {
    // Trigger Google Sign In flow
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign in cancelled');
    }

    // Get authentication details
    final googleAuth = await googleUser.authentication;

    // Sign in to Supabase with Google token
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken!,
    );

    if (response.user == null) {
      throw Exception('Failed to sign in with Google');
    }

    // Check if profile exists, if not create it
    final profileExists = await _checkProfileExists(response.user!.id);
    if (!profileExists) {
      await _createUserProfile(response.user!);
    }

    return response.user!;
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _client.auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Get current user
  User? getCurrentUser() {
    final client = _clientOrNull;
    if (client == null) return null;
    return client.auth.currentUser;
  }

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges {
    final client = _clientOrNull;
    if (client == null) {
      // Return stream with null session if Supabase not initialized
      return Stream.value(AuthState(AuthChangeEvent.initialSession, null));
    }
    // Return stream that starts with current session immediately
    return client.auth.onAuthStateChange;
  }

  // Check if profile exists
  Future<bool> _checkProfileExists(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Create user profile, settings, and streaks
  // Note: This is a fallback - database trigger should handle this automatically
  Future<void> _createUserProfile(User user, {String? fullNameOverride}) async {
    final userId = user.id;
    final email = user.email ?? '';
    final fullName = fullNameOverride ?? 
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        user.email?.split('@').first ??
        'User';

    // Check if profile already exists (might be created by trigger)
    final profileExists = await _checkProfileExists(userId);
    if (profileExists) {
      return; // Profile already exists, skip creation
    }

    // Create profile
    await _client.from('profiles').insert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'avatar_url': user.userMetadata?['avatar_url'] as String?,
    });

    // Create user settings with defaults (only if doesn't exist)
    try {
      await _client.from('user_settings').insert({
        'user_id': userId,
      });
    } catch (e) {
      // Ignore if already exists
    }

    // Create streaks with defaults (only if doesn't exist)
    try {
      await _client.from('streaks').insert({
        'user_id': userId,
      });
    } catch (e) {
      // Ignore if already exists
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'miqra://auth',
    );
  }

  // Check if user email is verified
  bool isEmailVerified(User user) {
    return user.emailConfirmedAt != null;
  }

  // Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    try {
      // Check if user exists and is already verified
      final currentUser = _client.auth.currentUser;
      if (currentUser != null && 
          currentUser.email == email && 
          isEmailVerified(currentUser)) {
        throw Exception('Your email is already verified. Please sign in.');
      }

      // Try to resend verification email
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'miqra://auth',
      );
    } on AuthException catch (e) {
      // Handle specific Supabase errors
      if (e.message.contains('already verified') || 
          e.message.contains('Email already confirmed')) {
        throw Exception('Your email is already verified. Please sign in.');
      }
      if (e.message.contains('not found') || 
          e.message.contains('does not exist')) {
        throw Exception('Email not found. Please sign up first.');
      }
      throw Exception('Failed to send verification email: ${e.message}');
    } catch (e) {
      // Re-throw with better message
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('already verified')) {
        throw Exception('Your email is already verified. Please sign in.');
      }
      throw Exception('Failed to send verification email. Please try again.');
    }
  }
}

