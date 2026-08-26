import 'package:flutter/material.dart';
import '../../auth/screens/forgot_password_screen.dart';
import 'student_about_screen.dart';
import 'student_help_screen.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});
  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  var _darkMode = false;
  var _pushNotifications = true;
  var _emailNotifications = true;
  var _urgentOnly = false;
  var _biometric = true;
  var _language = 'English';

  @override
  Widget build(BuildContext context) {
    final background = _darkMode ? const Color(0xFF111827) : const Color(0xFFF6F7FB);
    final card = _darkMode ? const Color(0xFF1F2937) : Colors.white;
    final text = _darkMode ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final muted = _darkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border = _darkMode ? Colors.white.withValues(alpha: .08) : Colors.black.withValues(alpha: .06);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF312E81),
        foregroundColor: Colors.white,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w500)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _section('Appearance', card, border, muted, [
          _toggle('Dark Mode', 'Switch to dark theme', Icons.dark_mode_outlined, _darkMode, (value) => setState(() => _darkMode = value), text, muted),
          ListTile(leading: const Icon(Icons.language_outlined), title: Text('Language', style: TextStyle(color: text, fontWeight: FontWeight.w600)), subtitle: Text(_language, style: TextStyle(color: muted)), trailing: DropdownButton<String>(value: _language, underline: const SizedBox.shrink(), items: const ['English', 'Hindi', 'Kannada'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (value) => setState(() => _language = value ?? _language))),
        ]),
        _section('Notifications', card, border, muted, [
          _toggle('Push Notifications', 'Receive app notifications', Icons.notifications_outlined, _pushNotifications, (value) => setState(() => _pushNotifications = value), text, muted),
          _toggle('Email Notifications', 'Receive email summaries', Icons.email_outlined, _emailNotifications, (value) => setState(() => _emailNotifications = value), text, muted),
          _toggle('Urgent Alerts Only', 'Only high-priority alerts', Icons.warning_amber_outlined, _urgentOnly, (value) => setState(() => _urgentOnly = value), text, muted),
        ]),
        _section('Security & Privacy', card, border, muted, [
          _toggle('Biometric Login', 'Use fingerprint to sign in', Icons.fingerprint, _biometric, (value) => setState(() => _biometric = value), text, muted),
          _link('Change Password', 'Update your password', Icons.key_outlined, text, muted, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()))),
          _link('Privacy Settings', 'Manage data & permissions', Icons.shield_outlined, text, muted, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy controls are not configured by the current backend.')))),
        ]),
        _section('About', card, border, muted, [
          _link('Help & Support', 'FAQs and contact', Icons.help_outline, text, muted, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentHelpScreen()))),
          _link('About App', 'Version & legal info', Icons.info_outline, text, muted, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentAboutScreen()))),
        ]),
      ]),
    );
  }

  Widget _section(String title, Color card, Color border, Color muted, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title.toUpperCase(), style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1))),
          DecoratedBox(decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)), child: Column(children: children)),
        ]),
      );

  Widget _toggle(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged, Color text, Color muted) => SwitchListTile(
        secondary: Icon(icon, color: muted), title: Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: TextStyle(color: muted, fontSize: 11)), value: value, onChanged: onChanged, activeThumbColor: const Color(0xFF4F46E5),
      );

  Widget _link(String title, String subtitle, IconData icon, Color text, Color muted, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: muted), title: Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: TextStyle(color: muted, fontSize: 11)), trailing: Icon(Icons.chevron_right, color: muted), onTap: onTap,
      );
}
