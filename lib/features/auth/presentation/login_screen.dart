import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle prefill email from extra parameter (when coming from register screen)
    final route = GoRouterState.of(context);
    final extra = route.extra as Map<String, dynamic>?;
    final prefillEmail = extra?['prefillEmail'] as String?;
    if (prefillEmail != null && prefillEmail.isNotEmpty && _email.text.isEmpty) {
      _email.text = prefillEmail;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.signInEmail(email: _email.text.trim(), password: _password.text);
      if (mounted) context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      // Ganti dengan scheme kamu setelah setup deep link:
      await auth.signInWithGoogle(redirectTo: 'com.miqra.app://login-callback');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google login gagal: $e')));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            AuthTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress),
            spacing,
            AuthTextField(controller: _password, label: 'Password', obscure: true),
            spacing,
            ElevatedButton(
              onPressed: _busy ? null : _loginEmail,
              child: _busy ? const CircularProgressIndicator() : const Text('Masuk'),
            ),
            spacing,
            OutlinedButton.icon(
              onPressed: _busy ? null : _loginGoogle,
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Masuk dengan Google'),
            ),
            spacing,
            TextButton(
              onPressed: () => context.push('/forgot'),
              child: const Text('Lupa password?'),
            ),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Buat akun baru'),
            ),
          ],
        ),
      ),
    );
  }
}
