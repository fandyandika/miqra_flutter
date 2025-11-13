import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';

void ensureLoggedInOrPrompt(
  BuildContext context,
  WidgetRef ref,
  VoidCallback onAllowed,
) {
  final user = ref.read(authUserProvider);
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Silakan login dulu untuk melanjutkan.')),
    );
    Future.microtask(() => context.push('/login'));
    return;
  }
  onAllowed();
}

