import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/typography.dart';
import '../../../../shared/widgets/miqra_components.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _registerEmail() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final email = _email.text.trim();
      
      final response = await auth.signUpEmail(email: email, password: _password.text);
      
      if (response.user == null) {
        if (!mounted) return;
        _showAlreadyRegisteredSheet(context, email);
        return;
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi sukses. Cek email verifikasi.')),
      );
      context.go('/login');
    } on AuthException catch (e) {
      if (!mounted) return;
      
      final msg = e.message.toLowerCase();
      final isDuplicate = msg.contains('user already registered') || 
                          msg.contains('already registered') ||
                          msg.contains('user already') ||
                          msg.contains('email already') ||
                          msg.contains('already exists');
      
      if (isDuplicate) {
        _showAlreadyRegisteredSheet(context, _email.text.trim());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal: ${e.message}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      
      final msg = e.message.toLowerCase();
      final isDuplicateError = msg.contains('already') || 
                               msg.contains('duplicate') ||
                               msg.contains('unique constraint') ||
                               e.code == '23505';
      
      if (isDuplicateError) {
        _showAlreadyRegisteredSheet(context, _email.text.trim());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal: ${e.message}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      final errorStr = e.toString().toLowerCase();
      final isDuplicateError = errorStr.contains('already') || 
                               errorStr.contains('duplicate') ||
                               errorStr.contains('unique constraint') ||
                               errorStr.contains('23505');
      
      if (isDuplicateError) {
        _showAlreadyRegisteredSheet(context, _email.text.trim());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAlreadyRegisteredSheet(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: MiqraSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email sudah terdaftar',
              style: MiqraTextStyles.headline,
            ),
            MiqraSpacing.gapXS,
            const Text('Pilih salah satu opsi di bawah agar bisa lanjut.'),
            MiqraSpacing.gapMD,
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login', extra: {'prefillEmail': email});
              },
              child: const Text('Masuk'),
            ),
            MiqraSpacing.gapXS,
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final auth = ref.read(authRepositoryProvider);
                  await auth.resetPasswordEmail(email: email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link reset dikirim. Cek email.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal kirim link: $e')),
                    );
                  }
                }
              },
              child: const Text('Reset Password'),
            ),
            MiqraSpacing.gapXS,
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final auth = ref.read(authRepositoryProvider);
                  await auth.signInWithOtp(email: email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Magic link dikirim. Cek email.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal kirim link: $e')),
                    );
                  }
                }
              },
              child: const Text('Kirim Ulang Verifikasi / Magic Link'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: MiqraSpacing.screenPadding,
        child: ListView(
          children: [
            AuthTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            MiqraSpacing.gapSM,
            AuthTextField(controller: _password, label: 'Password', obscure: true),
            MiqraSpacing.gapSM,
            ElevatedButton(
              onPressed: _busy ? null : _registerEmail,
              child: _busy ? const MiqraLoading.inline() : const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
