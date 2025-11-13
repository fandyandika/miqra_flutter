import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((_) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(supabaseClientProvider));
});

final authSessionProvider = StreamProvider<Session?>((ref) {
  return ref.read(authRepositoryProvider).onAuthState();
});

final authUserProvider = Provider<User?>((ref) {
  final async = ref.watch(authSessionProvider);
  return async.asData?.value?.user;
});
