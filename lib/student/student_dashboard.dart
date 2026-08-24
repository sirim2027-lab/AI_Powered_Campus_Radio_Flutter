import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../core/routes/app_routes.dart';
import '../core/services/auth_service.dart';
import '../services/firestore_service.dart';
import '../features/student/screens/student_settings_screen.dart';
import '../features/student/screens/student_edit_profile_screen.dart';
import '../features/student/screens/student_help_screen.dart';
import '../features/student/screens/student_about_screen.dart';
import '../features/student/screens/student_announcements_screen.dart';
import '../features/student/models/student_announcement.dart';
import '../features/student/screens/student_announcement_detail_screen.dart';
import '../features/student/screens/student_notifications_screen.dart';
import '../features/student/screens/student_query_history_screen.dart';
import '../features/student/screens/student_raise_query_screen.dart';
import '../features/student/screens/radio/student_campus_radio_home_screen.dart';
import '../features/student/screens/department/student_department_spotlight_screen.dart';
import '../features/student/screens/voice/student_voice_home_screen.dart';

/// Figma Student Module shell. All collection data is supplied by Firestore.
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key, required this.user});
  final AppUser user;
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  static const navy = Color(0xFF312E81);
  static const indigo = Color(0xFF4F46E5);
  int index = 0;
  final dashboardSearch = TextEditingController();
  final labels = const ['Home', 'Announcements', 'Campus Radio', 'Departments', 'My Queries', 'Notifications', 'Profile'];
  final icons = const [Icons.home_outlined, Icons.campaign_outlined, Icons.radio_outlined, Icons.account_balance_outlined, Icons.question_answer_outlined, Icons.notifications_none, Icons.person_outline];
  bool get wide => MediaQuery.sizeOf(context).width >= 760;
  String get name => widget.user.name.trim().isEmpty ? 'Student' : widget.user.name.trim().split(' ').first;
  String get initial => name.substring(0, 1).toUpperCase();

  @override
  void dispose() {
    dashboardSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F7FB),
    drawer: wide ? null : drawer(),
    body: Row(children: [
      if (wide) SizedBox(width: 252, child: drawer(permanent: true)),
      Expanded(child: Column(children: [topBar(), Expanded(child: page())])),
    ]),
    bottomNavigationBar: wide ? null : NavigationBar(
      selectedIndex: [0, 1, 5, 4, 6].indexOf(index).clamp(0, 4).toInt(),
      onDestinationSelected: (value) => setState(() => index = const [0, 1, 5, 4, 6][value]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Announce'),
        NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Notifs'),
        NavigationDestination(icon: Icon(Icons.question_answer_outlined), selectedIcon: Icon(Icons.question_answer), label: 'Queries'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );

  Widget drawer({bool permanent = false}) => Drawer(
    elevation: permanent ? 0 : 16, backgroundColor: const Color(0xFF201A67),
    child: SafeArea(child: Column(children: [
      const Padding(padding: EdgeInsets.fromLTRB(18, 22, 18, 18), child: Row(children: [
        CircleAvatar(backgroundColor: Color(0xFF7C3AED), child: Icon(Icons.radio, color: Colors.white)), SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CampusConnect AI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)), Text('Student Module', style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11))])
      ])),
      Expanded(child: ListView.builder(itemCount: labels.length, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), child: ListTile(
        selected: index == i, selectedTileColor: indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        leading: Icon(icons[i], color: index == i ? Colors.white : const Color(0xFFC7D2FE)),
        title: Text(labels[i], style: TextStyle(color: index == i ? Colors.white : const Color(0xFFE0E7FF), fontWeight: index == i ? FontWeight.w700 : FontWeight.w500)),
        onTap: () { setState(() => index = i); if (!permanent) Navigator.pop(context); },
      )))),
      const Divider(color: Color(0xFF4C467C)),
      ListTile(leading: CircleAvatar(backgroundColor: indigo, child: Text(initial, style: const TextStyle(color: Colors.white))), title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), subtitle: const Text('Student', style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11))),
      ListTile(leading: const Icon(Icons.logout, color: Color(0xFFFCA5A5)), title: const Text('Logout', style: TextStyle(color: Colors.white)), onTap: logout), const SizedBox(height: 8),
    ])),
  );

  Widget topBar() => Container(height: 70, padding: const EdgeInsets.symmetric(horizontal: 18), color: Colors.white, child: Row(children: [
    if (!wide) Builder(builder: (context) => IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu))),
    Text(labels[index], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))), const Spacer(),
    IconButton(tooltip: 'Search campus updates', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentSearchPage())), icon: const Icon(Icons.search)),
    IconButton(onPressed: () => setState(() => index = 5), icon: const Badge(label: Text('5'), child: Icon(Icons.notifications_none))), const SizedBox(width: 6),
    GestureDetector(onTap: () => setState(() => index = 6), child: CircleAvatar(backgroundColor: indigo, child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
  ]));

  Widget page() => switch (index) {
    0 => home(),
    1 => const StudentAnnouncementsScreen(),
    2 => const StudentCampusRadioHomeScreen(),
    3 => const StudentDepartmentSpotlightScreen(),
    4 => StudentQueryHistoryScreen(uid: widget.user.uid),
    5 => const StudentNotificationsScreen(),
    _ => profile(),
  };

  Widget home() => SingleChildScrollView(child: Column(children: [
    Container(width: double.infinity, padding: EdgeInsets.fromLTRB(wide ? 32 : 20, 30, wide ? 32 : 20, 28), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [navy, indigo, Color(0xFF6D28D9)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1080), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Thursday, August 7, 2026', style: TextStyle(color: Colors.white.withValues(alpha: .65), fontSize: 12)), const SizedBox(height: 5), Text('Good morning, $name 👋', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)), const SizedBox(height: 20),
      Container(
        height: 46,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), border: Border.all(color: Colors.white.withValues(alpha: .2)), borderRadius: BorderRadius.circular(14)),
        child: TextField(
          controller: dashboardSearch,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Search announcements, events…',
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFCBD5E1)),
            suffixIcon: dashboardSearch.text.isEmpty ? null : IconButton(onPressed: () { dashboardSearch.clear(); setState(() {}); }, icon: const Icon(Icons.clear, color: Color(0xFFCBD5E1))),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    ]))),
    Padding(padding: EdgeInsets.all(wide ? 30 : 16), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1080), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      stats(),
      if (dashboardSearch.text.trim().isNotEmpty) ...[
        const SizedBox(height: 24),
        const Text('Search results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _LiveCollectionResults(collection: 'announcements', label: 'Announcements & events', icon: Icons.campaign_outlined, query: dashboardSearch.text),
        _LiveCollectionResults(collection: 'radio_programmes', label: 'Campus Radio programmes', icon: Icons.radio_outlined, query: dashboardSearch.text),
        _LiveCollectionResults(collection: 'departments', label: 'Departments', icon: Icons.account_balance_outlined, query: dashboardSearch.text),
      ] else ...[
        const SizedBox(height: 24), section('Latest Announcements', () => setState(() => index = 1)), preview('announcements', Icons.campaign_outlined, 'No announcements have been published yet.'), const SizedBox(height: 24), section('Campus Radio', () => setState(() => index = 2)), radioCard(), const SizedBox(height: 24), const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 12), quickAccess(),
      ],
    ]))),
  ]));

  Widget stats() => Row(children: [
    liveStat('Announcements', FirestoreService.instance.count('announcements'), Icons.campaign, indigo),
    const SizedBox(width: 10),
    liveStat('Programmes', FirestoreService.instance.count('radio_programmes'), Icons.radio, const Color(0xFF10B981)),
    const SizedBox(width: 10),
    liveStat('My Queries', FirestoreService.instance.studentQueriesFor(widget.user.uid).map((snapshot) => snapshot.size), Icons.forum, const Color(0xFFF59E0B)),
  ]);
  Widget liveStat(String label, Stream<int> count, IconData icon, Color color) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(children: [Icon(icon, color: color), const SizedBox(height: 5), StreamBuilder<int>(stream: count, builder: (_, snapshot) => Text(snapshot.hasError ? '—' : '${snapshot.data ?? 0}', style: TextStyle(fontSize: 21, color: color, fontWeight: FontWeight.w800))), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))])));
  Widget section(String title, VoidCallback action) => Row(children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const Spacer(), TextButton(onPressed: action, child: const Text('See all →'))]);
  Widget radioCard() => InkWell(onTap: () => setState(() => index = 2), borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F0C29), Color(0xFF302B63)]), borderRadius: BorderRadius.circular(20)), child: const Row(children: [CircleAvatar(radius: 24, backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.radio, color: Colors.white, size: 27)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('🔴 LIVE  ·  CAMPUS RADIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFCA5A5))), SizedBox(height: 4), Text('Campus Morning Brief', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)), Text('Next: Student Voice — 11:00 AM', style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11))])), CircleAvatar(backgroundColor: indigo, child: Icon(Icons.play_arrow, color: Colors.white))])));
  Widget quickAccess() {
    final data = <(String, IconData, int)>[
      ('My Announcements', Icons.campaign, 1),
      ('Campus Radio', Icons.radio, 2),
      ('Departments', Icons.account_balance, 3),
      ('Student Voice', Icons.mic, 4),
      ('Raise a Query', Icons.help_outline, 4),
      ('My Profile', Icons.person, 6),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: data.map((item) {
        return SizedBox(
          width: wide ? 245 : (MediaQuery.sizeOf(context).width - 42) / 2,
          child: InkWell(
            onTap: () {
              if (item.$1 == 'Student Voice') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentVoiceHomeScreen()));
                return;
              }
              if (item.$1 == 'Raise a Query') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => StudentRaiseQueryScreen(uid: widget.user.uid),
                ));
                return;
              }
              setState(() => index = item.$3);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Icon(item.$2, color: indigo),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget preview(String collection, IconData icon, String empty, {bool all = false}) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirestoreService.instance.collection(collection), builder: (_, snap) { if (snap.hasError) return message(Icons.cloud_off_outlined, 'This content is unavailable right now.'); if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())); final docs = all ? snap.data!.docs : snap.data!.docs.take(3).toList(); if (docs.isEmpty) return message(icon, empty); return Column(children: docs.map((d) => record(d, icon, collection: collection)).toList()); });
  Widget record(QueryDocumentSnapshot<Map<String, dynamic>> doc, IconData icon, {String? collection}) {
    final data = doc.data();
    final title = '${data['title'] ?? data['name'] ?? data['subject'] ?? 'Untitled'}';
    final detail = '${data['message'] ?? data['description'] ?? data['schedule'] ?? ''}';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E7EB))),
      child: ListTile(
        onTap: collection == 'announcements' ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentAnnouncementDetailScreen(announcement: StudentAnnouncement.fromDocument(doc)))) : () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(title), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [if (data['posterUrl'] != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network('${data['posterUrl']}', fit: BoxFit.contain))), Text(detail.isEmpty ? 'No further details are available.' : detail), if (data['attachmentUrl'] != null && data['posterUrl'] == null) Padding(padding: const EdgeInsets.only(top: 12), child: SelectableText('Attachment: ${data['attachmentName'] ?? 'Open file'}\n${data['attachmentUrl']}', style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5))))])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))])),
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(backgroundColor: const Color(0xFFEEF2FF), child: Icon(icon, color: indigo)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: detail.isEmpty ? null : Padding(padding: const EdgeInsets.only(top: 5), child: Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
  Widget message(IconData icon, String text) => Padding(padding: const EdgeInsets.all(35), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 50, color: const Color(0xFF9CA3AF)), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280)))])));
  Widget profile() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: indigo,
                child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 14),
              Text(widget.user.name.isEmpty ? 'Student' : widget.user.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              Text(widget.user.email, style: const TextStyle(color: Color(0xFF6B7280))),
              if (widget.user.department != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(widget.user.department!, style: const TextStyle(color: indigo, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentEditProfileScreen(user: widget.user))),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentSettingsScreen())),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Settings'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentHelpScreen())), icon: const Icon(Icons.help_outline), label: const Text('Help & Support')),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentAboutScreen())), icon: const Icon(Icons.info_outline), label: const Text('About App')),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: logout, icon: const Icon(Icons.logout), label: const Text('Logout')),
            ],
          ),
        ),
      ),
    ),
  );
  Future<void> logout() async {
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}

/// Live search for the collections that supply the Student Module. Firestore
/// streams refresh these results automatically when staff publish new content.
class StudentSearchPage extends StatefulWidget {
  const StudentSearchPage({super.key, this.title = 'Search campus updates'});
  final String title;

  @override
  State<StudentSearchPage> createState() => _StudentSearchPageState();
}

class _StudentSearchPageState extends State<StudentSearchPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F7FB),
    appBar: AppBar(
      title: Text(widget.title),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF111827),
      elevation: 0,
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _query,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search events, announcements, departments…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.text.isEmpty ? null : IconButton(onPressed: () { _query.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          ),
        ),
      ),
      Expanded(
        child: _query.text.trim().isEmpty
            ? const Center(child: Text('Search announcements, events, programmes, and departments.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))))
            : ListView(children: [
                _LiveCollectionResults(collection: 'announcements', label: 'Announcements & events', icon: Icons.campaign_outlined, query: _query.text),
                _LiveCollectionResults(collection: 'radio_programmes', label: 'Campus Radio programmes', icon: Icons.radio_outlined, query: _query.text),
                _LiveCollectionResults(collection: 'departments', label: 'Departments', icon: Icons.account_balance_outlined, query: _query.text),
              ]),
      ),
    ]),
  );
}

class _LiveCollectionResults extends StatelessWidget {
  const _LiveCollectionResults({required this.collection, required this.label, required this.icon, required this.query});
  final String collection;
  final String label;
  final IconData icon;
  final String query;

  bool _matches(Map<String, dynamic> value) {
    final needle = query.trim().toLowerCase();
    return ['title', 'name', 'subject', 'message', 'description', 'schedule', 'host']
        .map((key) => value[key]?.toString().toLowerCase() ?? '')
        .any((text) => text.contains(needle));
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirestoreService.instance.collection(collection),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
      final results = snapshot.data!.docs.where((doc) => _matches(doc.data())).toList();
      if (results.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF312E81))),
          const SizedBox(height: 8),
          ...results.map((doc) {
            final data = doc.data();
            final title = '${data['title'] ?? data['name'] ?? data['subject'] ?? 'Untitled'}';
            final detail = '${data['message'] ?? data['description'] ?? data['schedule'] ?? ''}';
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5E7EB))),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFEEF2FF), child: Icon(icon, color: const Color(0xFF4F46E5))),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: detail.isEmpty ? null : Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(detail.isEmpty ? 'No further details are available.' : detail), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))])),
              ),
            );
          }),
        ]),
      );
    },
  );
}
