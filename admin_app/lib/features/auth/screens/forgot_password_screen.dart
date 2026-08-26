import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();

  var _loading = false;
  var _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthService.instance.sendPasswordResetEmail(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Unable to send password reset email.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: _sent ? _successContent() : _formContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _successContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFECFDF5),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 38,
            color: Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Check Your Email',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent password-reset instructions to ${_email.text.trim()}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }

  Widget _formContent() {
    return Form(
      key: _form,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_reset_outlined,
            size: 50,
            color: Color(0xFF4F46E5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Forgot Password?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your college email and we’ll send a Firebase password-reset link.',
            style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'College Email',
              prefixIcon: Icon(Icons.mail_outline),
              hintText: 'yourname@vemanait.edu.in',
            ),
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.all(15),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Reset Link'),
            ),
          ),
        ],
      ),
    );
  }
}