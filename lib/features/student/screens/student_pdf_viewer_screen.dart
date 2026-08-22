import 'package:flutter/material.dart';

class StudentPdfViewerScreen extends StatefulWidget {
  const StudentPdfViewerScreen({super.key, required this.title, required this.url});
  final String title;
  final String url;
  @override State<StudentPdfViewerScreen> createState() => _StudentPdfViewerScreenState();
}

class _StudentPdfViewerScreenState extends State<StudentPdfViewerScreen> {
  var zoom = 100;
  bool get _isPdf => Uri.tryParse(widget.url)?.path.toLowerCase().endsWith('.pdf') ?? false;
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF1A1A2E), appBar: AppBar(backgroundColor: const Color(0xFF16213E), foregroundColor: Colors.white, title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: const TextStyle(fontSize: 13)), Text(_isPdf ? 'PDF attachment' : 'Unsupported attachment', style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF)))]), actions: [IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download/open requires an approved document-viewer dependency.'))), icon: const Icon(Icons.download_outlined))]), body: Column(children: [Container(color: const Color(0xFF0F3460), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [IconButton(onPressed: () => setState(() => zoom = (zoom - 10).clamp(50, 200).toInt()), icon: const Icon(Icons.remove, color: Colors.white)), Text('$zoom%', style: const TextStyle(color: Colors.white)), IconButton(onPressed: () => setState(() => zoom = (zoom + 10).clamp(50, 200).toInt()), icon: const Icon(Icons.add, color: Colors.white))])), Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(_isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined, size: 64, color: Colors.white), const SizedBox(height: 16), Text(_isPdf ? 'PDF viewing requires a PDF viewer dependency.' : 'This attachment is not confirmed as a PDF.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(_isPdf ? 'The existing attachment URL is available, but no PDF package is configured to render it in-app.' : 'Use the source application only after its content type is confirmed.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xAAFFFFFF), height: 1.5)), const SizedBox(height: 12), SelectableText(widget.url, style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 11))])))]));
}
