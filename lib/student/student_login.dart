import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';
import '../models/app_user.dart';
import '../services/user_role_service.dart';

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _message('Please enter your college email and password.');
      return;
    }
    setState(() => _loading = true);
    try {
      final profile = await UserRoleService.instance.signInAndLoadProfile(
        email: _email.text.trim(), password: _password.text,
      );
      if (profile.role != UserRole.student) {
        await FirebaseAuth.instance.signOut();
        throw const _StudentOnlyException();
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.student,
        (_) => false,
        arguments: profile,
      );
    } on FirebaseAuthException catch (e) {
      _message(_authMessage(e));
    } on MissingProfileException {
      _message('Your user profile is not set up yet. Please contact the administrator.');
    } on MissingRoleException {
      _message('Your account has no valid role. Please contact the administrator.');
    } on _StudentOnlyException {
      _message('This account is a staff account. Please use the Admin/Staff login.');
    } on FirebaseException catch (e) {
      _message(switch (e.code) {
        'permission-denied' => 'Firestore access is blocked. Ask the administrator to update Firestore security rules.',
        'unavailable' => 'Firestore is unavailable. Check your internet connection and try again.',
        'failed-precondition' => 'Firestore is not configured for this Firebase project yet. Please contact the administrator.',
        _ => e.message ?? 'Unable to load your role profile from Firestore.',
      });
    } catch (_) {
      _message('Unable to sign in. Check your internet connection and try again.');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  String _authMessage(FirebaseAuthException e) => switch (e.code) {
    'user-not-found' => 'No account found with this email.',
    'wrong-password' || 'invalid-credential' => 'Incorrect email or password.',
    'invalid-email' => 'Please enter a valid email address.',
    'network-request-failed' => 'Network error. Check your internet connection.',
    _ => e.message ?? 'Login failed. Please try again.',
  };
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red.shade700));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff6f7fb),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: SingleChildScrollView(child: Column(children: [
      Container(height: 210, width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xff312e81), Color(0xff4f46e5)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 31, backgroundColor: Color(0x33ffffff), child: Icon(Icons.school_outlined, color: Colors.white, size: 31)), SizedBox(height: 12),
        Text('VEMANA INSTITUTE OF TECHNOLOGY', style: TextStyle(color: Color(0xffe0e7ff), letterSpacing: 1.2, fontSize: 10, fontWeight: FontWeight.w700)),
      ])),
      Padding(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xff111827))),
        const SizedBox(height: 4), const Text('Sign in to your student account', style: TextStyle(color: Color(0xff6b7280))), const SizedBox(height: 28),
        _field('College email', _email, Icons.mail_outline, hint: 'yourname@vemanait.edu.in'), const SizedBox(height: 16),
        _field('Password', _password, Icons.lock_outline, password: true), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () async { if (_email.text.trim().isEmpty) { _message('Enter your college email first.'); return; } try { await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim()); _message('Password reset email sent.'); } on FirebaseAuthException catch (e) { _message(e.message ?? 'Unable to send reset email.'); } }, child: const Text('Forgot password?'))),
        const SizedBox(height: 10), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff4f46e5), foregroundColor: Colors.white), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign In →'))),
        const SizedBox(height: 16), Center(child: TextButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Admin or staff? Sign in here'))),
      ])),
    ])))),
  );

  Widget _field(String label, TextEditingController controller, IconData icon, {String? hint, bool password = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .5)), const SizedBox(height: 8), TextField(controller: controller, obscureText: password && _obscure, keyboardType: password ? TextInputType.text : TextInputType.emailAddress, decoration: InputDecoration(hintText: hint ?? 'Enter your password', prefixIcon: Icon(icon), suffixIcon: password ? IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)) : null, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffe5e7eb)))),)]);
}
class _StudentOnlyException implements Exception { const _StudentOnlyException(); }
