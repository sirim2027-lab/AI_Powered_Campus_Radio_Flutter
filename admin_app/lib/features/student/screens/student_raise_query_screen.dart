import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../services/firestore_service.dart';
import 'student_query_history_screen.dart';

class StudentRaiseQueryScreen extends StatefulWidget {
  const StudentRaiseQueryScreen({super.key, required this.uid});

  final String uid;

  @override
  State<StudentRaiseQueryScreen> createState() => _StudentRaiseQueryScreenState();
}

class _StudentRaiseQueryScreenState extends State<StudentRaiseQueryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.createStudentQuery(
        subject: _subject.text.trim(),
        message: _message.text.trim(),
        uid: widget.uid,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => StudentQueryHistoryScreen(uid: widget.uid),
        ),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your query has been submitted.')),
      );
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit your query.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF312E81),
          foregroundColor: Colors.white,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Raise a Query'),
              Text(
                'Tell us how we can help',
                style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
              ),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _subject,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'Brief subject of your query',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a subject'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _message,
                minLines: 5,
                maxLines: 7,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your query in detail',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a description'
                    : null,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Your submission includes only the subject and description. '
                  'Status updates appear in My Queries when available.',
                  style: TextStyle(
                    color: Color(0xFF3730A3),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.all(15),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Query'),
              ),
            ],
          ),
        ),
      );
}
