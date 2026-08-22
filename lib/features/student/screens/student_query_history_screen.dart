import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../models/student_query.dart';
import '../widgets/query_card.dart';
import 'student_query_detail_screen.dart';
import 'student_raise_query_screen.dart';

class StudentQueryHistoryScreen extends StatefulWidget {
  const StudentQueryHistoryScreen({super.key, required this.uid});
  final String uid;
  @override State<StudentQueryHistoryScreen> createState() => _StudentQueryHistoryScreenState();
}
class _StudentQueryHistoryScreenState extends State<StudentQueryHistoryScreen> {
  var _tab = 'all';
  var _search = '';
  @override Widget build(BuildContext context) => Column(children: [
    Container(padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF312E81), Color(0xFF4F46E5)])), child: Column(children: [
      Row(children: [const Expanded(child: Text('My Queries', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500))), OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentRaiseQueryScreen(uid: widget.uid))), icon: const Icon(Icons.add, color: Colors.white), label: const Text('New', style: TextStyle(color: Colors.white)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0x55FFFFFF))))]),
      const SizedBox(height: 14), TextField(onChanged: (value) => setState(() => _search = value), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(prefixIcon: Icon(Icons.search, color: Color(0x99FFFFFF)), hintText: 'Search queries', hintStyle: TextStyle(color: Color(0x99FFFFFF)), filled: true, fillColor: Color(0x1FFFFFFF), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0x33FFFFFF)))))
    ])),
    SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), children: ['all', 'pending', 'in-progress', 'resolved'].map((tab) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(tab == 'all' ? 'All' : tab == 'in-progress' ? 'Active' : '${tab[0].toUpperCase()}${tab.substring(1)}'), selected: _tab == tab, onSelected: (_) => setState(() => _tab = tab), selectedColor: const Color(0xFF4F46E5), labelStyle: TextStyle(color: _tab == tab ? Colors.white : const Color(0xFF6B7280), fontSize: 12), side: BorderSide.none))).toList())),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirestoreService.instance.studentQueriesFor(widget.uid), builder: (_, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Unable to load your queries.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final queries = snapshot.data!.docs.map(StudentQuery.fromDocument).where((query) => (_tab == 'all' || query.status.toLowerCase() == _tab) && '${query.subject} ${query.message}'.toLowerCase().contains(_search.toLowerCase())).toList();
      if (queries.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.forum_outlined, size: 44, color: Color(0xFF9CA3AF)), const SizedBox(height: 12), const Text('No queries found'), const SizedBox(height: 12), FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentRaiseQueryScreen(uid: widget.uid))), child: const Text('Raise a Query'))]));
      return ListView(padding: const EdgeInsets.all(16), children: queries.map((query) => QueryCard(query: query, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentQueryDetailScreen(query: query))))).toList());
    }))
  ]);
}
