import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import '../services/poster_ocr.dart';
import '../services/storage_service.dart';

class AdminField {
  const AdminField(this.key, this.label, {this.multiline = false});
  final String key;
  final String label;
  final bool multiline;
}

class AdminCollectionPage extends StatelessWidget {
  const AdminCollectionPage({
    super.key,
    required this.title,
    required this.collection,
    required this.icon,
    required this.fields,
    this.readOnly = false,
    this.scanPoster = false,
  });

  final String title;
  final String collection;
  final IconData icon;
  final List<AdminField> fields;
  final bool readOnly;
  final bool scanPoster;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: readOnly
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: Text('Add $title'),
              ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.instance.collection(collection),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _message(Icons.cloud_off_outlined, 'Unable to load $title. Check Firestore rules.');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return _message(icon, 'No $title found.');
            return ListView.separated(
              padding: const EdgeInsets.all(28),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _card(context, docs[index]),
            );
          },
        ),
      );

  Widget _message(IconData messageIcon, String message) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(messageIcon, size: 56, color: const Color(0xff7137e9)),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: Color(0xff747a96))),
        ]),
      );

  Widget _card(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final heading = fields.isEmpty ? document.id : '${data[fields.first.key] ?? 'Untitled'}';
    final details = fields.skip(1).map((field) => data[field.key]).whereType<Object>().map((value) => '$value').where((value) => value.isNotEmpty).join(' • ');
    final poster = data['posterBytes'] as String?;
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: poster == null || poster.isEmpty ? null : () => _showPoster(context, poster, heading),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: poster == null || poster.isEmpty
            ? CircleAvatar(backgroundColor: const Color(0x197137e9), child: Icon(icon, color: const Color(0xff7137e9)))
            : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(base64Decode(poster), width: 52, height: 52, fit: BoxFit.cover)),
        title: Text(heading, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: details.isEmpty ? null : Padding(padding: const EdgeInsets.only(top: 5), child: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis)),
        trailing: readOnly ? null : Wrap(children: [IconButton(tooltip: 'Edit', onPressed: () => _edit(context, document: document), icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: 'Delete', onPressed: () => _delete(context, document), icon: const Icon(Icons.delete_outline, color: Colors.redAccent))]),
      ),
    );
  }

  void _showPoster(BuildContext context, String encodedImage, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(children: [
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close)),
              ]),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.memory(base64Decode(encodedImage), fit: BoxFit.contain),
              ),
            ),
            const Padding(padding: EdgeInsets.all(12), child: Text('Pinch or scroll to zoom', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
          ]),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, {QueryDocumentSnapshot<Map<String, dynamic>>? document}) async {
    final controllers = {for (final field in fields) field.key: TextEditingController(text: document?.data()[field.key]?.toString() ?? '')};
    var isExtracting = false;
    XFile? poster;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(document == null ? 'Add $title' : 'Edit $title'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (scanPoster && document == null) ...[
                    OutlinedButton.icon(
                      onPressed: isExtracting
                          ? null
                          : () async {
                              setDialogState(() => isExtracting = true);
                              final result = await _extractTextFromPoster(context);
                              poster = result.$2;
                              if (result.$1 != null) {
                                final lines = result.$1!
                                    .split(RegExp(r'\r?\n'))
                                    .where((line) => line.trim().isNotEmpty)
                                    .toList();
                                if (lines.isNotEmpty) controllers['title']?.text = lines.first.trim();
                                controllers['message']?.text = result.$1!;
                              }
                              if (dialogContext.mounted) {
                                setDialogState(() => isExtracting = false);
                              }
                            },
                      icon: isExtracting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_search_outlined),
                      label: Text(isExtracting ? 'Extracting text…' : 'Add poster image and extract text'),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 14),
                      child: Text(
                        'Choose a poster image. Its text will appear in the fields below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xff64709c)),
                      ),
                    ),
                  ],
                  if (poster != null) Padding(padding: const EdgeInsets.only(bottom: 14), child: FutureBuilder<Uint8List>(future: poster!.readAsBytes(), builder: (_, image) => image.hasData ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(image.data!, height: 140, width: double.infinity, fit: BoxFit.cover)) : const LinearProgressIndicator())),
                  ...fields.map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextField(
                        controller: controllers[field.key],
                        minLines: field.multiline ? 3 : 1,
                        maxLines: field.multiline ? 5 : 1,
                        decoration: InputDecoration(
                          labelText: field.label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (save != true || !context.mounted) { for (final controller in controllers.values) { controller.dispose(); } return; }
    final data = {for (final field in fields) field.key: controllers[field.key]!.text.trim()};
    if (poster != null) data['posterBytes'] = base64Encode(await poster!.readAsBytes());
    if (data.values.any((value) => value.isEmpty)) { _snack(context, 'Please complete every field.', error: true); } else { try { if (document == null) { await FirestoreService.instance.createDocument(collection, data); } else { await FirestoreService.instance.updateDocument(collection, document.id, data); } if (context.mounted) _snack(context, '$title saved.'); } on FirebaseException catch (e) { if (context.mounted) _snack(context, e.code == 'permission-denied' ? 'You do not have permission to change this item.' : 'Could not save this item.', error: true); } }
    for (final controller in controllers.values) { controller.dispose(); }
  }

  Future<(String?, XFile?)> _extractTextFromPoster(BuildContext context) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null || !context.mounted) return (null, null);

      final text = (await extractPosterText(image.path)).trim();
      if (text.isEmpty && context.mounted) {
        _snack(context, 'No text was detected. Try a clearer poster image.', error: true);
      }
      return (text.isEmpty ? null : text, image);
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'Could not read the poster image. Try another image.', error: true);
      }
      return (null, null);
    }
  }

  Future<void> _delete(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> document) async {
    final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Delete item?'), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete'))]));
    if (confirm != true) return;
    try { await FirestoreService.instance.deleteDocument(collection, document.id); if (context.mounted) _snack(context, '$title deleted.'); } on FirebaseException catch (_) { if (context.mounted) _snack(context, 'Could not delete this item.', error: true); }
  }

  void _snack(BuildContext context, String message, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700));
}

class AdminQueriesPage extends StatefulWidget {
  const AdminQueriesPage({super.key});
  @override
  State<AdminQueriesPage> createState() => _AdminQueriesPageState();
}

class _AdminQueriesPageState extends State<AdminQueriesPage> {
  final _search = TextEditingController();
  String _filter = 'All';
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirestoreService.instance.collection('student_queries'),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Unable to load student queries. Check Firestore rules.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final all = snapshot.data!.docs;
      final text = _search.text.trim().toLowerCase();
      String normalized(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final status = '${doc.data()['status'] ?? 'open'}'.toLowerCase();
        return status == 'open' ? 'new' : status;
      }
      final visible = all.where((doc) {
        final data = doc.data();
        final matchesFilter = _filter == 'All' || normalized(doc) == _filter.toLowerCase();
        return matchesFilter && '${data['subject'] ?? ''} ${data['message'] ?? ''} ${data['studentName'] ?? ''}'.toLowerCase().contains(text);
      }).toList();
      int count(String status) => all.where((doc) => normalized(doc) == status).length;
      return Container(color: const Color(0xFFF9F9FF), child: ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [_metric('${count('new')}', 'New', const Color(0xFFEF4444)), const SizedBox(width: 7), _metric('${count('pending')}', 'Pending', const Color(0xFFF59E0B)), const SizedBox(width: 7), _metric('${count('in progress')}', 'Progress', const Color(0xFF7C3AED)), const SizedBox(width: 7), _metric('${count('resolved')}', 'Today', const Color(0xFF16A34A))]),
        const SizedBox(height: 11),
        TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 18), hintText: 'Search student or query…', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDD6FE))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDD6FE))))),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'New', 'Pending', 'Assigned', 'In Progress', 'Resolved'].map(_chip).toList())),
        const SizedBox(height: 10),
        if (visible.isEmpty) const Padding(padding: EdgeInsets.only(top: 35), child: Center(child: Text('No queries match this filter.', style: TextStyle(color: Color(0xFF64748B))))) else ...visible.map(_queryCard),
      ]));
    },
  );

  Widget _metric(String value, String label, Color color) => Expanded(child: Container(height: 62, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E1FF))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))])));
  Widget _chip(String label) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(label, style: const TextStyle(fontSize: 10)), selected: _filter == label, onSelected: (_) => setState(() => _filter = label), selectedColor: const Color(0xFF4F46E5), labelStyle: TextStyle(color: _filter == label ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w700), side: const BorderSide(color: Color(0xFFDDD6FE)), visualDensity: VisualDensity.compact));
  Widget _queryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) { final data = doc.data(); final status = '${data['status'] ?? 'open'}'; final shown = status == 'open' ? 'New' : status; final color = status == 'resolved' ? const Color(0xFF16A34A) : status == 'in progress' ? const Color(0xFF7C3AED) : status == 'pending' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444); return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E1FF))), child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('${data['studentName'] ?? data['studentEmail'] ?? 'Student query'}', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800))), _tag(shown, color)]), Text('${data['subject'] ?? 'Query'}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))), const SizedBox(height: 9), Text('${data['message'] ?? ''}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))), const SizedBox(height: 10), Row(children: [_tag('${data['category'] ?? 'General'}', const Color(0xFF7C3AED)), const Spacer(), PopupMenuButton<String>(padding: EdgeInsets.zero, onSelected: (value) => FirestoreService.instance.updateDocument('student_queries', doc.id, {'status': value}), itemBuilder: (_) => const [PopupMenuItem(value: 'open', child: Text('Mark new')), PopupMenuItem(value: 'pending', child: Text('Mark pending')), PopupMenuItem(value: 'in progress', child: Text('Mark in progress')), PopupMenuItem(value: 'resolved', child: Text('Mark resolved'))])])]))); }
  Widget _tag(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)));
}

/// Mobile User Management screen matching the supplied Admin/Staff Figma frame.
/// Its cards, counts, search, and role filters always read the Firestore users collection.
class AdminUsersFigmaPage extends StatefulWidget {
  const AdminUsersFigmaPage({super.key});
  @override
  State<AdminUsersFigmaPage> createState() => _AdminUsersFigmaPageState();
}

/// Firestore-backed delivery view matching the supplied Notifications frame.
class AdminNotificationsFigmaPage extends StatefulWidget {
  const AdminNotificationsFigmaPage({super.key});
  @override
  State<AdminNotificationsFigmaPage> createState() => _AdminNotificationsFigmaPageState();
}

class AdminAnnouncementsFigmaPage extends StatefulWidget {
  const AdminAnnouncementsFigmaPage({super.key});
  @override
  State<AdminAnnouncementsFigmaPage> createState() => _AdminAnnouncementsFigmaPageState();
}

class AnnouncementInputMethodPage extends StatefulWidget {
  const AnnouncementInputMethodPage({super.key});
  @override
  State<AnnouncementInputMethodPage> createState() => _AnnouncementInputMethodPageState();
}

class _AnnouncementInputMethodPageState extends State<AnnouncementInputMethodPage> {
  static const _methods = [('Manual Text', 'Type announcement directly', Icons.edit_outlined), ('Image / Poster', 'Upload image, AI extracts info', Icons.image_outlined), ('PDF / Document', 'Upload document for AI analysis', Icons.description_outlined), ('Voice Input', 'Record and transcribe speech', Icons.mic_none_outlined)];
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9F9FF),
    body: SafeArea(child: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 14, 16, 12), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6D28D9)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), style: IconButton.styleFrom(backgroundColor: const Color(0x22FFFFFF))), const SizedBox(width: 8), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Create Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)), Text('Step 1 of 3: Input Method', style: TextStyle(color: Color(0xFFDDD6FE), fontSize: 10))])), TextButton(onPressed: () => Navigator.pop(context), child: const Text('Save Draft', style: TextStyle(color: Colors.white, fontSize: 10))) ]),
        const SizedBox(height: 12), const LinearProgressIndicator(value: .33, minHeight: 3, color: Color(0xFF7C3AED), backgroundColor: Color(0x557C3AED)),
      ])),
      Expanded(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Choose Input Method', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('How would you like to create this announcement?', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)), const SizedBox(height: 14),
        ...List.generate(_methods.length, (index) {
          final method = _methods[index];
          final selected = index == _selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _selected = index),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: selected ? const Color(0xFF7C3AED) : const Color(0xFFDDD6FE), width: selected ? 2 : 1)),
                child: Row(children: [
                  CircleAvatar(backgroundColor: const Color(0xFFF4F1FF), child: Icon(method.$3, color: const Color(0xFF7C3AED))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(method.$1, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(method.$2, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  ])),
                  if (selected) const Icon(Icons.check_circle, color: Color(0xFF7C3AED)),
                ]),
              ),
            ),
          );
        }),
        const Spacer(), Row(children: [OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back')), const SizedBox(width: 10), Expanded(child: FilledButton(onPressed: _continue, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), minimumSize: const Size(0, 48)), child: const Text('Continue → Content')))]),
      ]))),
    ])),
  );

  Future<void> _continue() async {
    if (_selected == 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice transcription will be connected next. Please use Manual Text, Image / Poster, or PDF / Document.')));
      return;
    }
    XFile? image;
    String extracted = '';
    if (_selected == 1) {
      image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null || !mounted) return;
      extracted = (await extractPosterText(image.path)).trim();
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AnnouncementContentPage(initialText: extracted, poster: image, inputMethod: _selected == 0 ? 'text' : _selected == 1 ? 'image' : 'pdf')));
  }
}

class AnnouncementContentPage extends StatefulWidget {
  const AnnouncementContentPage({super.key, required this.initialText, required this.inputMethod, this.poster});
  final String initialText;
  final String inputMethod;
  final XFile? poster;
  @override
  State<AnnouncementContentPage> createState() => _AnnouncementContentPageState();
}

class _AnnouncementContentPageState extends State<AnnouncementContentPage> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  String _category = 'General';
  String _priority = 'Medium';
  String _department = 'All Departments';
  String _audience = 'All Students';
  Uint8List? _attachmentBytes;
  String? _attachmentName;
  String? _attachmentType;
  @override
  void initState() { super.initState(); final lines = widget.initialText.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList(); _title.text = lines.isEmpty ? '' : lines.first; _message.text = widget.initialText; }
  @override
  void dispose() { _title.dispose(); _message.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9F9FF),
    body: SafeArea(child: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 14, 16, 12), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6D28D9)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))), child: Column(children: [Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), style: IconButton.styleFrom(backgroundColor: const Color(0x22FFFFFF))), const SizedBox(width: 8), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Create Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)), Text('Step 2 of 3: Content', style: TextStyle(color: Color(0xFFDDD6FE), fontSize: 10))])), const Text('Save Draft', style: TextStyle(color: Colors.white, fontSize: 10))]), const SizedBox(height: 12), const LinearProgressIndicator(value: .66, minHeight: 3, color: Color(0xFF7C3AED), backgroundColor: Color(0x557C3AED))])),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Announcement Details', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 14),
        _field('Title *', TextField(controller: _title, decoration: const InputDecoration(hintText: 'e.g., TCS Recruitment Drive 2025'))), const SizedBox(height: 13),
        _field('Description', TextField(controller: _message, minLines: 4, maxLines: 7, decoration: const InputDecoration(hintText: 'Enter full details of the announcement…'))), const SizedBox(height: 13),
        Row(children: [Expanded(child: _dropdown('Category', _category, const ['General', 'Placement', 'Exam', 'Cultural', 'Sports', 'Academic'], (value) => setState(() => _category = value))), const SizedBox(width: 10), Expanded(child: _dropdown('Priority', _priority, const ['Low', 'Medium', 'High', 'Urgent'], (value) => setState(() => _priority = value)))]), const SizedBox(height: 13),
        _dropdown('Target Department', _department, const ['All Departments', 'CSE', 'ECE', 'EEE', 'MECH', 'CIVIL', 'IT', 'MBA', 'MCA'], (value) => setState(() => _department = value)), const SizedBox(height: 13),
        _dropdown('Target Audience', _audience, const ['All Students', 'UG Students', 'PG Students', 'Final Year', '3rd Year', '2nd Year', '1st Year'], (value) => setState(() => _audience = value)), const SizedBox(height: 13),
        if (widget.inputMethod != 'text') ...[
        InkWell(
          onTap: _pickAttachment,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFEFFBFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7DD3FC))),
            child: Row(children: [
              const Icon(Icons.attach_file, color: Color(0xFF4F46E5)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_attachmentName ?? 'Add Attachments', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
                Text(_attachmentName == null ? (widget.inputMethod == 'pdf' ? 'PDF documents (optional)' : 'Images / posters (optional)') : _attachmentType ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ])),
              const Text('Browse', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        ],
        Row(children: [OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back')), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.auto_awesome, size: 16), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), minimumSize: const Size(0, 48)), label: const Text('Process with AI')))]),
      ]))),
    ])),
  );
  Widget _field(String label, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 6), child]);
  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> change) => _field(label, DropdownButtonFormField<String>(value: value, isExpanded: true, decoration: const InputDecoration(), items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (selected) => change(selected ?? value)));
  Future<void> _pickAttachment() async {
    final extensions = widget.inputMethod == 'pdf' ? ['pdf'] : ['jpg', 'jpeg', 'png', 'webp'];
    final pick = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: extensions, withData: true);
    if (pick == null || pick.files.single.bytes == null) return;
    setState(() {
      _attachmentBytes = pick.files.single.bytes;
      _attachmentName = pick.files.single.name;
      _attachmentType = pick.files.single.extension?.toUpperCase();
    });
  }
  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title and description.')));
      return;
    }
    final data = <String, dynamic>{
      'title': _title.text.trim(), 'message': _message.text.trim(), 'category': _category,
      'priority': _priority, 'department': _department, 'audience': _audience, 'status': 'published',
    };
    try {
      Uint8List? uploadBytes = _attachmentBytes;
      var uploadName = _attachmentName;
      var uploadType = _attachmentType;
      if (uploadBytes == null && widget.poster != null) {
        uploadBytes = await widget.poster!.readAsBytes();
        uploadName = widget.poster!.name;
        uploadType = widget.poster!.name.split('.').last.toUpperCase();
      }
      if (uploadBytes != null && uploadName != null && uploadType != null) {
        final image = const ['JPG', 'JPEG', 'PNG', 'WEBP'].contains(uploadType);
        final contentType = image ? 'image/${uploadType == 'JPG' ? 'jpeg' : uploadType.toLowerCase()}' : 'application/pdf';
        final url = await StorageService.instance.uploadAnnouncementAttachment(bytes: uploadBytes, filename: uploadName, contentType: contentType);
        data['attachmentUrl'] = url;
        data['attachmentName'] = uploadName;
        data['attachmentType'] = uploadType;
        if (image) data['posterUrl'] = url;
      }
      await FirestoreService.instance.createDocument('announcements', data);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseException catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not upload the attachment. Enable Firebase Storage and check its rules.')));
    }
  }
}

class _AdminAnnouncementsFigmaPageState extends State<AdminAnnouncementsFigmaPage> {
  final _search = TextEditingController();
  String _category = 'All Categories';
  String _status = 'All';
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirestoreService.instance.collection('announcements'),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Unable to load announcements. Check Firestore rules.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final query = _search.text.trim().toLowerCase();
      final docs = snapshot.data!.docs.where((doc) {
        final data = doc.data();
        final category = '${data['category'] ?? 'General'}';
        final status = '${data['status'] ?? 'published'}'.toLowerCase();
        final categoryOk = _category == 'All Categories' || _normalCategory(category) == _normalCategory(_category);
        final statusOk = _status == 'All' || status == _status.toLowerCase();
        return categoryOk && statusOk && '${data['title'] ?? ''} ${data['message'] ?? ''}'.toLowerCase().contains(query);
      }).toList();
      return Container(color: const Color(0xFFF9F9FF), child: Column(children: [
        Container(color: const Color(0xFF4F46E5), padding: const EdgeInsets.fromLTRB(14, 14, 14, 13), child: Row(children: [
          const CircleAvatar(radius: 17, backgroundColor: Color(0x227C3AED), child: Icon(Icons.menu, color: Colors.white, size: 18)),
          const SizedBox(width: 9), const Expanded(child: Text('Announcements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
          FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnnouncementInputMethodPage())), icon: const Icon(Icons.add, size: 14), label: const Text('Create'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, visualDensity: VisualDensity.compact)),
          const SizedBox(width: 7), const CircleAvatar(radius: 17, backgroundColor: Color(0x227C3AED), child: Icon(Icons.notifications_none, color: Colors.white, size: 18)),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
          TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 18), hintText: 'Search announcements…', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDD6FE))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDD6FE))))),
          const SizedBox(height: 9),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All Categories', 'General', 'Placement', 'Exam', 'Cultural', 'Sports', 'Academic'].map(_categoryChip).toList())),
          const SizedBox(height: 9),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['All', 'Published', 'Scheduled', 'Draft', 'Archived'].map(_statusTab).toList()),
          const Divider(height: 8, color: Color(0xFFDDD6FE)),
          if (docs.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No announcements match this filter.', style: TextStyle(color: Color(0xFF64748B))))) else ...docs.map(_announcementCard),
        ])),
      ]));
    },
  );

  Widget _categoryChip(String label) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(label, style: const TextStyle(fontSize: 10)), selected: _category == label, onSelected: (_) => setState(() => _category = label), selectedColor: const Color(0xFF7C3AED), labelStyle: TextStyle(color: _category == label ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w700), side: const BorderSide(color: Color(0xFFDDD6FE)), visualDensity: VisualDensity.compact));
  String _normalCategory(String value) {
    final category = value.trim().toLowerCase();
    return category.endsWith('s') ? category.substring(0, category.length - 1) : category;
  }
  Widget _statusTab(String label) => InkWell(onTap: () => setState(() => _status = label), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(label, style: TextStyle(fontSize: 10, color: _status == label ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8), fontWeight: _status == label ? FontWeight.w800 : FontWeight.w600))));
  Widget _announcementCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = '${data['status'] ?? 'published'}';
    final category = '${data['category'] ?? 'General'}';
    final priority = '${data['priority'] ?? 'Normal'}';
    final statusColor = status == 'published'
        ? const Color(0xFF16A34A)
        : status == 'scheduled'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF7C3AED);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E1FF))),
      child: InkWell(
        onTap: () => _editor(doc: doc),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('${data['title'] ?? 'Untitled announcement'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w800))),
              _tag(status, statusColor),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              _tag(category, const Color(0xFF7C3AED)),
              _tag(priority, const Color(0xFFF97316)),
              if (data['audience'] != null) _tag('${data['audience']}', const Color(0xFF64748B)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('by ${data['author'] ?? 'Administrator'}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))),
              Text('A${doc.id.substring(0, doc.id.length > 4 ? 4 : doc.id.length)}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontFamily: 'monospace')),
            ]),
          ]),
        ),
      ),
    );
  }
  Widget _tag(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)));
  Future<void> _editor({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) async {
    const categories = ['General', 'Placement', 'Exam', 'Cultural', 'Sports', 'Academic'];
    final data = doc?.data() ?? <String, dynamic>{};
    final title = TextEditingController(text: '${data['title'] ?? ''}');
    final message = TextEditingController(text: '${data['message'] ?? ''}');
    var category = _normalCategory('${data['category'] ?? 'General'}');
    category = categories.firstWhere((item) => _normalCategory(item) == category, orElse: () => 'General');
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(doc == null ? 'Create Announcement' : 'Edit Announcement'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: category, isExpanded: true, decoration: const InputDecoration(labelText: 'Category'), items: categories.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setDialogState(() => category = value ?? 'General')),
            const SizedBox(height: 12),
            TextField(controller: message, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Message')),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save'))],
        ),
      ),
    );
    if (save == true && title.text.trim().isNotEmpty && message.text.trim().isNotEmpty) {
      final value = {'title': title.text.trim(), 'message': message.text.trim(), 'category': category, 'status': data['status'] ?? 'published', 'priority': data['priority'] ?? 'Normal'};
      if (doc == null) { await FirestoreService.instance.createDocument('announcements', value); } else { await FirestoreService.instance.updateDocument('announcements', doc.id, value); }
    }
    title.dispose();
    message.dispose();
  }
}

class _AdminNotificationsFigmaPageState extends State<AdminNotificationsFigmaPage> {
  String _filter = 'Sent';

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirestoreService.instance.collection('notifications'),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Unable to load notifications. Check Firestore rules.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final all = snapshot.data!.docs;
      final visible = all.where((doc) {
        if (_filter == 'All') return true;
        return ('${doc.data()['status'] ?? 'sent'}').toLowerCase() == _filter.toLowerCase();
      }).toList();
      final delivered = all.fold<int>(0, (total, doc) => total + _number(doc.data()['delivered']));
      final read = all.fold<int>(0, (total, doc) => total + _number(doc.data()['read']));
      final failed = all.fold<int>(0, (total, doc) => total + _number(doc.data()['failed']));
      final rate = delivered == 0 ? '—' : '${((read / delivered) * 100).toStringAsFixed(0)}%';
      return Container(
        color: const Color(0xFFF9F9FF),
        child: Column(children: [
          Container(
            color: const Color(0xFF4F46E5),
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            child: const Row(children: [
              CircleAvatar(radius: 17, backgroundColor: Color(0x227C3AED), child: Icon(Icons.menu, color: Colors.white, size: 19)),
              SizedBox(width: 10), Expanded(child: Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
              CircleAvatar(radius: 17, backgroundColor: Color(0x227C3AED), child: Icon(Icons.notifications_none, color: Colors.white, size: 18)),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
            Row(children: [
              _metric('${all.length}', 'Total', const Color(0xFF4F46E5)), const SizedBox(width: 7),
              _metric(rate, 'Read Rate', const Color(0xFF16A34A)), const SizedBox(width: 7),
              _metric('$failed', 'Failed', const Color(0xFFEF4444)),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Sent', 'Scheduled', 'Failed', 'Delivered', 'All'].map(_filterChip).toList())),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 42), child: Center(child: Text('No notifications in this status.', style: TextStyle(color: Color(0xFF64748B)))))
            else
              ...visible.map((doc) => _notificationCard(doc)),
          ])),
        ]),
      );
    },
  );

  int _number(dynamic value) => value is int ? value : int.tryParse('${value ?? 0}') ?? 0;
  Widget _metric(String value, String label, Color color) => Expanded(child: Container(height: 64, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E1FF))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))])));
  Widget _filterChip(String value) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(value, style: const TextStyle(fontSize: 10)), selected: _filter == value, onSelected: (_) => setState(() => _filter = value), selectedColor: const Color(0xFF4F46E5), labelStyle: TextStyle(color: _filter == value ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w700), side: const BorderSide(color: Color(0xFFDDD6FE)), visualDensity: VisualDensity.compact));
  Widget _notificationCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final delivered = _number(data['delivered']);
    final read = _number(data['read']);
    final failed = _number(data['failed']);
    final progress = delivered == 0 ? 0.0 : (read / delivered).clamp(0.0, 1.0);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E1FF))),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _details(data),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CircleAvatar(backgroundColor: Color(0xFFF0EDFF), child: Icon(Icons.notifications_active_outlined, color: Color(0xFF7C3AED))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${data['title'] ?? 'Untitled notification'}', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('${data['message'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                Text('$delivered delivered', style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                Text('$read read', style: const TextStyle(fontSize: 10, color: Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
                Text('$failed failed', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress, minHeight: 5, borderRadius: BorderRadius.circular(8), color: const Color(0xFF7C3AED), backgroundColor: const Color(0xFFEDE9FE)),
            ])),
          ]),
        ),
      ),
    );
  }
  void _details(Map<String, dynamic> data) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text('${data['title'] ?? 'Notification'}'), content: Text('${data['message'] ?? 'No message'}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
}

class _AdminUsersFigmaPageState extends State<AdminUsersFigmaPage> {
  final _search = TextEditingController();
  String _role = 'All Roles';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirestoreService.instance.collection('users'),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Unable to load users. Check Firestore rules.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final users = snapshot.data!.docs;
      final active = users.where((doc) => doc.data()['active'] != false).length;
      final query = _search.text.trim().toLowerCase();
      final filtered = users.where((doc) {
        final data = doc.data();
        final role = '${data['role'] ?? ''}'.toLowerCase();
        final roleMatches = _role == 'All Roles' || role == _role.toLowerCase();
        final text = '${data['name'] ?? ''} ${data['email'] ?? ''}'.toLowerCase();
        return roleMatches && text.contains(query);
      }).toList();
      return Container(
        color: const Color(0xFFF9F9FF),
        child: Column(children: [
          Container(
            color: const Color(0xFF4F46E5),
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            child: Row(children: [
              Container(width: 34, height: 34, decoration: const BoxDecoration(color: Color(0x227C3AED), shape: BoxShape.circle), child: const Icon(Icons.menu, color: Colors.white, size: 19)),
              const SizedBox(width: 10), const Expanded(child: Text('User Management', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
              FilledButton.icon(onPressed: _addUser, icon: const Icon(Icons.add, size: 15), label: const Text('Add User'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, visualDensity: VisualDensity.compact)),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
            Row(children: [
              _metric('${users.length}', 'Total Users', const Color(0xFF4F46E5)), const SizedBox(width: 8),
              _metric('$active', 'Active', const Color(0xFF16A34A)), const SizedBox(width: 8),
              _metric('${users.length - active}', 'Inactive', const Color(0xFFEF4444)),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 19), hintText: 'Search by name or email…', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDD6FE))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDD6FE))))),
            const SizedBox(height: 10),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All Roles', 'Super', 'Admin', 'Staff', 'Student'].map(_roleChip).toList())),
            const SizedBox(height: 10),
            if (filtered.isEmpty) const Padding(padding: EdgeInsets.only(top: 42), child: Center(child: Text('No users match this search.', style: TextStyle(color: Color(0xFF64748B))))) else ...filtered.map(_userCard),
          ])),
        ]),
      );
    },
  );

  Widget _metric(String value, String label, Color color) => Expanded(child: Container(height: 64, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E1FF))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: TextStyle(color: color, fontSize: 21, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))])));
  Widget _roleChip(String role) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(role, style: const TextStyle(fontSize: 10)), selected: _role == role, onSelected: (_) => setState(() => _role = role), selectedColor: const Color(0xFF4F46E5), labelStyle: TextStyle(color: _role == role ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w700), side: const BorderSide(color: Color(0xFFDDD6FE)), visualDensity: VisualDensity.compact));
  Widget _userCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) { final data = doc.data(); final name = '${data['name'] ?? 'Unnamed user'}'; final email = '${data['email'] ?? ''}'; final role = '${data['role'] ?? 'User'}'; final department = '${data['department'] ?? ''}'; final active = data['active'] != false; return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E1FF))), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Row(children: [CircleAvatar(backgroundColor: const Color(0xFF7C3AED), child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800)), Text(email, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))])), Icon(Icons.circle, size: 10, color: active ? const Color(0xFF16A34A) : const Color(0xFF94A3B8))]), const SizedBox(height: 10), Row(children: [_badge(role), if (department.isNotEmpty) ...[const SizedBox(width: 6), _badge(department)]]), const Divider(height: 20), Row(children: [const Text('Last login: —', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))), const Spacer(), TextButton(onPressed: () => _editUser(doc), child: const Text('Edit', style: TextStyle(fontSize: 10))), const VerticalDivider(width: 1), TextButton(onPressed: () => _permissions(name), child: const Text('Permissions', style: TextStyle(fontSize: 10))), const VerticalDivider(width: 1), TextButton(onPressed: () => FirestoreService.instance.updateDocument('users', doc.id, {'active': !active}), child: Text(active ? 'Deactivate' : 'Activate', style: TextStyle(fontSize: 10, color: active ? Colors.red : Colors.green)))])]))); }
  Widget _badge(String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF0EDFF), borderRadius: BorderRadius.circular(99)), child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6D28D9), fontWeight: FontWeight.w700)));
  Future<void> _permissions(String name) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text('$name permissions'), content: const Text('Permissions are based on the role stored in this user’s Firestore profile.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  Future<void> _addUser() => _userEditor();
  Future<void> _editUser(QueryDocumentSnapshot<Map<String, dynamic>> doc) => _userEditor(doc: doc);
  Future<void> _userEditor({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final data = doc?.data() ?? <String, dynamic>{};
    final name = TextEditingController(text: '${data['name'] ?? ''}');
    final email = TextEditingController(text: '${data['email'] ?? ''}');
    final role = TextEditingController(text: '${data['role'] ?? ''}');
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(doc == null ? 'Add User' : 'Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: role, decoration: const InputDecoration(labelText: 'Role')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
        ],
      ),
    );
    if (save == true && name.text.trim().isNotEmpty && email.text.trim().isNotEmpty) {
      final value = {'name': name.text.trim(), 'email': email.text.trim(), 'role': role.text.trim(), 'active': doc?.data()['active'] ?? true};
      if (doc == null) {
        await FirestoreService.instance.createDocument('users', value);
      } else {
        await FirestoreService.instance.updateDocument('users', doc.id, value);
      }
    }
    name.dispose();
    email.dispose();
    role.dispose();
  }
}
