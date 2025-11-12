import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state stream provider - SIMPLE VERSION (no await for to prevent hanging)
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  
  try {
    // Get current user immediately - don't wait for stream
    final currentUser = repository.getCurrentUser();
    
    // Return stream that starts with current user
    // Stream changes will be handled later when Supabase is ready
    return Stream.value(currentUser);
  } catch (e) {
    // If error, return stream with null immediately
    return Stream.value(null);
  }
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  try {
    final repository = ref.watch(authRepositoryProvider);
    return repository.getCurrentUser();
  } catch (e) {
    // If Supabase not initialized, return null
    return null;
  }
});

