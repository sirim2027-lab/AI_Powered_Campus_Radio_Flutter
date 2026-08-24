import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app.dart';
import 'core/routes/app_routes.dart';
import 'core/services/auth_service.dart';
import 'firebase_options.dart';
import 'admin/admin_management_pages.dart';
import 'models/app_user.dart';
import 'services/firestore_service.dart';
import 'features/auth/screens/forgot_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const CampusRadioApp(
      loginBuilder: _loginBuilder,
      adminBuilder: _adminBuilder,
    ),
  );
}

Widget _loginBuilder(BuildContext context) => const CampusLoginPage();

Widget _adminBuilder(AppUser profile, {int initialIndex = 0}) =>
    AdminDashboard(role: profile.roleLabel, initialIndex: initialIndex);

// ============================================================
// LOGIN PAGE
// ============================================================

class CampusLoginPage extends StatefulWidget {
  const CampusLoginPage({super.key});

  @override
  State<CampusLoginPage> createState() => _CampusLoginPageState();
}

class _CampusLoginPageState extends State<CampusLoginPage> {
  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;
  bool isRegistering = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController regNameController = TextEditingController();
  final TextEditingController regEmailController = TextEditingController();
  final TextEditingController regPasswordController = TextEditingController();
  final TextEditingController regUsnController = TextEditingController();
  String regSemester = '1st Semester';

  static const purple = Color(0xFF513FE4);
  static const brightPurple = Color(0xFF7137E9);
  static const muted = Color(0xFF64709C);

  @override
  void initState() {
    super.initState();
    regEmailController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    regNameController.dispose();
    regEmailController.dispose();
    regPasswordController.dispose();
    regUsnController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter your college email and password.',
        isError: true,
      );
      return;
    }

    if (!email.toLowerCase().endsWith('@vemanait.edu.in')) {
      _showMessage(
        'Please use your official @vemanait.edu.in email.',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final profile = await AuthService.instance.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;
      if (profile.role == UserRole.student) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.student,
          arguments: profile,
        );
      } else if (profile.isStaff) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.admin,
          arguments: profile,
        );
      } else {
        _showMessage('Your account has no valid role. Please contact the administrator.', isError: true);
      }
    } on MissingProfileException {
      _showMessage('Your user profile is not set up yet. Please contact the administrator.', isError: true);
    } on MissingRoleException {
      _showMessage('Your account has no valid role. Please contact the administrator.', isError: true);
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Login failed.';
      }

      _showMessage(message, isError: true);
    } on FirebaseException catch (e) {
      final message = switch (e.code) {
        'permission-denied' =>
          'Firestore access is blocked. Ask the administrator to update Firestore security rules.',
        'unavailable' => 'Firestore is unavailable. Check your internet connection and try again.',
        'failed-precondition' =>
          'Firestore is not configured for this Firebase project yet. Please contact the administrator.',
        _ => e.message ?? 'Unable to load your role profile from Firestore.',
      };
      _showMessage(message, isError: true);
    } catch (e) {
      _showMessage(
        'Something went wrong. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Enter your college email first.',
        isError: true,
      );
      return;
    }

    try {
      await AuthService.instance.sendPasswordResetEmail(email);

      _showMessage(
        'Password reset email sent.',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(
        e.message ?? 'Unable to send reset email.',
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF201A67),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHero(),
                  Expanded(
                    child: isRegistering ? _buildRegisterCard() : _buildLoginCard(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    return Container(
      height: 207,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5142E5),
            Color(0xFF4938D9),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7A58F0),
                  Color(0xFF9A45E9),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              'V',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Vemana Institute',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'of Technology',
            style: TextStyle(
              color: Color(0xFFD8D4FF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Smart Campus Platform',
            style: TextStyle(
              color: Color(0xFF9CBAFF),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 15),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: Color(0xFF22E8AC),
                size: 7,
              ),
              SizedBox(width: 6),
              Text(
                'Secure • vemanait.edu.in',
                style: TextStyle(
                  color: Color(0xFFBCE8FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 27, 24, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFF),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campus Radio Login',
              style: TextStyle(
                color: purple,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in with your institutional credentials',
              style: TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'College Email',
              style: TextStyle(
                color: purple,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            _input(
              controller: emailController,
              hint: 'name@vemanait.edu.in',
              icon: Icons.mail_outline,
            ),

            const SizedBox(height: 13),

            const Text(
              'Password',
              style: TextStyle(
                color: purple,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            _input(
              controller: passwordController,
              hint: '••••••••••',
              icon: Icons.lock_outline,
              password: true,
            ),

            const SizedBox(height: 9),

            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value ?? false;
                      });
                    },
                    activeColor: purple,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Remember me',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: purple,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brightPurple,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    isRegistering = true;
                  });
                },
                child: const Text(
                  "Don't have an account? Register here",
                  style: TextStyle(
                    color: purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  String _getDepartmentFromUsn(String usn) {
    if (usn.length < 7) return 'General';
    final code = usn.substring(5, 7).toUpperCase();
    return switch (code) {
      'CS' => 'CSE',
      'DS' => 'Data Science',
      'EC' => 'ECE',
      'ME' => 'MECH',
      'CV' => 'CIVIL',
      'EE' => 'EEE',
      'IS' => 'ISE',
      _ => 'Other',
    };
  }

  Future<void> _register() async {
    final name = regNameController.text.trim();
    final email = regEmailController.text.trim();
    final password = regPasswordController.text;
    final usn = regUsnController.text.trim();

    final isAdmin = email.toLowerCase().startsWith('principal') ||
        email.toLowerCase().startsWith('hod.') ||
        email.toLowerCase() == 'admin@vemanait.edu.in';

    if (name.isEmpty || email.isEmpty || password.isEmpty || (!isAdmin && usn.isEmpty)) {
      _showMessage('Please fill in all fields.', isError: true);
      return;
    }

    if (!email.toLowerCase().endsWith('@vemanait.edu.in')) {
      _showMessage('Please use your official @vemanait.edu.in email.', isError: true);
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters long.', isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase Auth registration did not return a user.');
      }

      final Map<String, dynamic> profileData = {
        'uid': user.uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (isAdmin) {
        profileData['role'] = 'admin';
      } else {
        profileData['role'] = 'student';
        profileData['studentId'] = usn;
        profileData['department'] = _getDepartmentFromUsn(usn);
        profileData['semester'] = regSemester;
      }

      // Create the profile document directly in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(profileData);

      _showMessage('Registration successful!', isError: false);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Registration failed.', isError: true);
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildRegisterCard() {
    final emailVal = regEmailController.text.trim().toLowerCase();
    final isRegAdmin = emailVal.startsWith('principal') ||
        emailVal.startsWith('hod.') ||
        emailVal == 'admin@vemanait.edu.in';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFF),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRegAdmin ? 'Staff Registration' : 'Student Registration',
              style: const TextStyle(
                color: purple,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isRegAdmin
                  ? 'Create a staff/admin account for campus management'
                  : 'Create a student account using your college email',
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 15),

            const Text(
              'Full Name',
              style: TextStyle(
                color: purple,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            _input(
              controller: regNameController,
              hint: isRegAdmin ? 'e.g., Prof. John Doe' : 'e.g., Dhanushree S',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),

            const Text(
              'College Email',
              style: TextStyle(
                color: purple,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            _input(
              controller: regEmailController,
              hint: 'name.ds2023@vemanait.edu.in',
              icon: Icons.mail_outline,
            ),
            const SizedBox(height: 12),

            if (!isRegAdmin) ...[
              const Text(
                'USN (Student ID)',
                style: TextStyle(
                  color: purple,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              _input(
                controller: regUsnController,
                hint: 'e.g., 1VE23DS023',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),

              const Text(
                'Semester',
                style: TextStyle(
                  color: purple,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: regSemester,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
                  ),
                ),
                items: const [
                  '1st Semester', '2nd Semester', '3rd Semester', '4th Semester',
                  '5th Semester', '6th Semester', '7th Semester', '8th Semester'
                ]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => regSemester = val);
                },
              ),
              const SizedBox(height: 12),
            ],

            const Text(
              'Password',
              style: TextStyle(
                color: purple,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            _input(
              controller: regPasswordController,
              hint: '••••••••••',
              icon: Icons.lock_outline,
              password: true,
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brightPurple,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),

            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    isRegistering = false;
                  });
                },
                child: const Text(
                  "Already have an account? Login here",
                  style: TextStyle(
                    color: purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool password = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: password && obscurePassword,
      keyboardType:
          password ? TextInputType.text : TextInputType.emailAddress,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9B9AFF),
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF8D9BC4),
          size: 17,
        ),
        suffixIcon: password
            ? IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF8D9BC4),
                  size: 17,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFD1C8FF),
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: brightPurple,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }

}

// ============================================================
// ADMIN DASHBOARD
// ============================================================

class AdminDashboard extends StatefulWidget {
  final String role;
  final int initialIndex;

  const AdminDashboard({
    super.key,
    required this.role,
    this.initialIndex = 0,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  bool get _isDesktop => MediaQuery.sizeOf(context).width >= 760;
  final List<String> menuItems = [
    'Dashboard',
    'Announcements',
    'Student Queries',
    'Radio Programmes',
    'Departments',
    'Users',
    'Notifications',
    'Profile',
    'Settings',
    'Help & Support',
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard_outlined,
    Icons.campaign_outlined,
    Icons.question_answer_outlined,
    Icons.radio_outlined,
    Icons.business_outlined,
    Icons.people_outline,
    Icons.notifications_outlined,
    Icons.person_outline,
    Icons.settings_outlined,
    Icons.help_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      drawer: _isDesktop
          ? null
          : Drawer(
              width: 282,
              backgroundColor: const Color(0xFF201A67),
              child: _buildSidebar(permanent: false),
            ),
      drawerEnableOpenDragGesture: false,
      body: !_isDesktop && selectedIndex == 0
          ? _figmaMobileDashboard()
          : Row(
        children: [
          if (_isDesktop) _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
      bottomNavigationBar: _isDesktop ? null : _mobileBottomNav(),
    );
  }

  Widget _mobileBottomNav() {
    final destinations = const [
      (0, 'Home', Icons.home_outlined),
      (1, 'Announce', Icons.campaign_outlined),
      (2, 'Queries', Icons.question_answer_outlined),
      (6, 'Notifs', Icons.notifications_none),
      (7, 'Profile', Icons.person_outline),
    ];
    final selected = destinations.indexWhere((item) => item.$1 == selectedIndex);
    return StreamBuilder<int>(
      stream: FirestoreService.instance.count('student_queries'),
      builder: (context, snapshot) => SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFDDD6FE)))),
          child: Row(children: destinations.asMap().entries.map((entry) {
            final position = entry.key;
            final item = entry.value;
            final badgeCount = item.$1 == 2 ? (snapshot.data ?? 0) : 0;
            final active = position == (selected < 0 ? 0 : selected);
            final color = active ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8);
            final icon = Icon(item.$3, color: color);
            return Expanded(child: InkWell(onTap: () => setState(() => selectedIndex = item.$1), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [badgeCount > 0 ? Badge(label: Text('$badgeCount'), child: icon) : icon, const SizedBox(height: 3), Text(item.$2, style: TextStyle(fontSize: 10, color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w500))])));
          }).toList()),
        ),
      ),
    );
  }

  Widget _figmaMobileDashboard() => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _figmaDashboardHeader(),
            const SizedBox(height: 12),
            _figmaAnnouncementStats(),
            const SizedBox(height: 12),
            _figmaQueryStatus(),
            const SizedBox(height: 14),
            const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              childAspectRatio: .92,
              children: [
                _quickFigmaAction('Create\nAnnouncement', Icons.edit_outlined, 1),
                _quickFigmaAction('View Queries', Icons.forum_outlined, 2),
                _quickFigmaAction('Analytics', Icons.bar_chart_outlined, null, unavailableMessage: 'Analytics unavailable: no analytics data source is configured.'),
                _quickFigmaAction('IoT Devices', Icons.sensors_outlined, null, unavailableMessage: 'Endpoint management unavailable: no endpoint/device backend is configured.'),
                _quickFigmaAction('User\nManagement', Icons.people_outline, 5),
                _quickFigmaAction('System\nStatus', Icons.monitor_outlined, null, unavailableMessage: 'System monitoring unavailable: no monitoring backend is configured.'),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => selectedIndex = 1),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21D6)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: .28), blurRadius: 14, offset: const Offset(0, 6))]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: Colors.white), SizedBox(width: 8), Text('Create Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),
              ),
            ),
            const SizedBox(height: 14),
            _weeklyActivity(),
            const SizedBox(height: 16),
            Row(children: [const Text('Recent Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))), const Spacer(), TextButton(onPressed: () => setState(() => selectedIndex = 1), child: const Text('See All →', style: TextStyle(fontSize: 11)))]),
            _mobileRecentAnnouncements(),
            const SizedBox(height: 15),
            _mobileSystemStatus(),
          ]),
        ),
      );

  Widget _figmaDashboardHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
        decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4F46E5), Color(0xFF6D28D9)]), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Builder(builder: (context) => IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu, color: Colors.white, size: 19), style: IconButton.styleFrom(backgroundColor: const Color(0x22FFFFFF), minimumSize: const Size(34, 34)))),
            const Expanded(child: Center(child: Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)))),
            IconButton(onPressed: () => setState(() => selectedIndex = 6), icon: const Badge(label: Text('•'), child: Icon(Icons.notifications_none, color: Colors.white, size: 19)), style: IconButton.styleFrom(backgroundColor: const Color(0x22FFFFFF), minimumSize: const Size(34, 34))),
            const SizedBox(width: 6),
            GestureDetector(onTap: () => setState(() => selectedIndex = 7), child: CircleAvatar(radius: 17, backgroundColor: const Color(0xFF7C3AED), child: Text(widget.role.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)))),
          ]),
          const SizedBox(height: 11),
          const Text('Good Evening 👋', style: TextStyle(fontSize: 11, color: Color(0xFFBFDBFE))),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${widget.role} Administrator', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0x337C3AED), borderRadius: BorderRadius.circular(8)), child: Text(widget.role, style: const TextStyle(fontSize: 9, color: Color(0xFFE9D5FF), fontWeight: FontWeight.w700))), const SizedBox(width: 8), const Text('Administration', style: TextStyle(fontSize: 10, color: Color(0xFFBFDBFE)))])])), Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0x337C3AED), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(widget.role.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)))]),
          const SizedBox(height: 12),
          Row(children: [Text(_dateLabel(), style: const TextStyle(fontSize: 10, color: Color(0xFFBFDBFE))), const Spacer(), const Text('Endpoint backend unavailable', style: TextStyle(fontSize: 10, color: Color(0xFFFDE68A), fontWeight: FontWeight.w700))]),
        ]),
      );

  String _dateLabel() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _figmaAnnouncementStats() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.collection('announcements'),
        builder: (_, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          int withStatus(String status) => docs.where((doc) => '${doc.data()['status'] ?? 'published'}'.toLowerCase() == status).length;
          return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.55, children: [
            _figmaStat('${docs.length}', 'Total', Icons.campaign_outlined, const Color(0xFF4F46E5)),
            _figmaStat('${withStatus('published')}', 'Published', Icons.verified_outlined, const Color(0xFF7C3AED)),
            _figmaStat('${withStatus('scheduled')}', 'Scheduled', Icons.alarm_outlined, const Color(0xFFF59E0B)),
            _figmaStat('${withStatus('draft')}', 'Drafts', Icons.edit_note_outlined, const Color(0xFF8B5CF6)),
          ]);
        },
      );

  Widget _figmaStat(String value, String label, IconData icon, Color color) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE5E1FF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 17, color: color), const Spacer(), Text(value, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))]));

  Widget _figmaQueryStatus() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.collection('student_queries'),
        builder: (_, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          int status(String value) => docs.where((doc) => '${doc.data()['status'] ?? 'open'}'.toLowerCase() == value).length;
          return Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE5E1FF))), child: Column(children: [Row(children: [const Text('Query Status', style: TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w800)), const Spacer(), TextButton(onPressed: () => setState(() => selectedIndex = 2), child: const Text('View All →', style: TextStyle(fontSize: 10)))]), Row(children: [_queryMetric('${status('open')}', 'Pending', const Color(0xFFEF4444)), const SizedBox(width: 7), _queryMetric('${status('in progress')}', 'In Progress', const Color(0xFFF59E0B)), const SizedBox(width: 7), _queryMetric('${status('resolved')}', 'Resolved', const Color(0xFF16A34A))]) ]));
        },
      );

  Widget _queryMetric(String value, String label, Color color) => Expanded(child: Container(height: 66, decoration: BoxDecoration(color: const Color(0xFFFAFAFF), borderRadius: BorderRadius.circular(10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))])));
  Widget _quickFigmaAction(String label, IconData icon, int? destination, {String? unavailableMessage}) => InkWell(onTap: () { if (destination != null) { setState(() => selectedIndex = destination); } else if (unavailableMessage != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(unavailableMessage))); } }, borderRadius: BorderRadius.circular(13), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE5E1FF))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: destination == null ? const Color(0xFF94A3B8) : const Color(0xFF7C3AED)), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: destination == null ? const Color(0xFF64748B) : const Color(0xFF4F46E5), fontWeight: FontWeight.w700))])));

  Widget _weeklyActivity() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E1FF))),
        child: const Row(children: [Icon(Icons.bar_chart_outlined, color: Color(0xFF94A3B8)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Analytics unavailable', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('A time-series analytics data source is not configured yet.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))]))]),
      );

  Widget _mobileRecentAnnouncements() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.collection('announcements'),
        builder: (_, snapshot) {
          if (snapshot.hasError) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Recent announcements are unavailable.', style: TextStyle(color: Color(0xFF94A3B8)))));
          if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
          final docs = snapshot.data!.docs.take(4).toList();
          if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No announcements created yet.', style: TextStyle(color: Color(0xFF94A3B8)))));
          return Column(children: docs.map((doc) { final data = doc.data(); final status = '${data['status'] ?? 'published'}'; return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E1FF))), child: ListTile(onTap: () => setState(() => selectedIndex = 1), dense: true, title: Text('${data['title'] ?? 'Untitled announcement'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w800)), subtitle: Wrap(spacing: 5, children: [_tinyChip('${data['category'] ?? 'General'}', const Color(0xFF7C3AED)), _tinyChip('${data['priority'] ?? 'Normal'}', const Color(0xFFF59E0B))]), trailing: Text(status, style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)))); }).toList());
        },
      );

  Widget _tinyChip(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w700)));
  Widget _mobileSystemStatus() => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E1FF))), child: const Row(children: [Icon(Icons.monitor_heart_outlined, color: Color(0xFF94A3B8)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('System monitoring unavailable', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('No backend health or notification-delivery monitoring source is configured.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))]))]));

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar({bool permanent = true}) {
    return Container(
      width: permanent ? 245 : double.infinity,
      color: const Color(0xFF201A67),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),

            Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7A58F0),
                        Color(0xFF9A45E9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'V',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Campus Radio',
                      style: TextStyle(
                        color: Color(0xFFB8B2E8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 35),

            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final selected = selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: const Color(0xFF513FE4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Icon(
                        menuIcons[index],
                        color: selected
                            ? Colors.white
                            : const Color(0xFFB8B2E8),
                      ),
                      title: Text(
                        menuItems[index],
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFFD4D0F2),
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                        if (!permanent) Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),

            // ROLE
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF17134F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF7137E9),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'Administrator',
                          style: TextStyle(
                            color: Color(0xFF9B96C8),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: _buildSelectedPage(),
        ),
      ],
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: _isDesktop ? Colors.white : const Color(0xFF4F46E5),
      child: Row(
        children: [
          if (!_isDesktop)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Open menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            ),
          Text(
            menuItems[selectedIndex],
            style: TextStyle(
              color: _isDesktop ? const Color(0xFF28234F) : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Admin search unavailable',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Admin-wide search is unavailable: no Admin search workflow is configured.')),
            ),
            icon: Icon(
              Icons.search,
              color: _isDesktop ? const Color(0xFF555B78) : Colors.white,
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                selectedIndex = 6;
              });
            },
            icon: Icon(
              Icons.notifications_none,
              color: _isDesktop ? const Color(0xFF555B78) : Colors.white,
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: () => setState(() => selectedIndex = 7),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFF7137E9),
              child: Text(
                widget.role.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (_isDesktop) ...[
            const SizedBox(width: 10),
            Text(
              widget.role,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF414663),
              ),
            ),
            const SizedBox(width: 10),
          ],

          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminRecentUpdates() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.collection('announcements'),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Recent announcements are unavailable.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!.docs.take(4).toList();
          if (items.isEmpty) {
            return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF28234F))),
              SizedBox(height: 8),
              Text('No announcements have been created yet.', style: TextStyle(color: Color(0xFF747A96))),
            ]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recent announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF28234F))),
            const SizedBox(height: 10),
            ...items.map((document) {
              final data = document.data();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Color(0x197137E9), child: Icon(Icons.campaign_outlined, color: Color(0xFF7137E9))),
                title: Text('${data['title'] ?? 'Untitled announcement'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${data['message'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => setState(() => selectedIndex = 1),
              );
            }),
          ]);
        },
      ),
    );
  }

  // ============================================================
  // PAGE SWITCHING
  // ============================================================

  Widget _buildSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return _dashboardPage();

      case 1:
        return const AdminAnnouncementsFigmaPage();

      case 2:
        return const AdminQueriesPage();

      case 3:
        return const AdminCollectionPage(
          title: 'Radio Programmes',
          collection: 'radio_programmes',
          icon: Icons.radio_outlined,
          fields: [
            AdminField('title', 'Programme title'),
            AdminField('host', 'Host / presenter'),
            AdminField('schedule', 'Schedule (for example, Mon 10:00 AM)'),
            AdminField('description', 'Description', multiline: true),
          ],
        );

      case 4:
        return const AdminCollectionPage(
          title: 'Departments',
          collection: 'departments',
          icon: Icons.business_outlined,
          fields: [AdminField('name', 'Department name'), AdminField('description', 'Description', multiline: true)],
        );

      case 5:
        return const AdminUsersFigmaPage();

      case 6:
        return const AdminNotificationsFigmaPage();

      case 7:
        return _adminProfilePage();

      case 8:
        return _adminSettingsPage();

      case 9:
        return _adminHelpPage();

      default:
        return _dashboardPage();
    }
  }

  Widget _adminProfilePage() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE4E3F2))),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(radius: 42, backgroundColor: const Color(0xFF7137E9), child: Text(widget.role.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800))),
                  const SizedBox(height: 14),
                  Text('${widget.role} Administrator', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF28234F))),
                  const SizedBox(height: 4),
                  const Text('Campus Radio administration portal', style: TextStyle(color: Color(0xFF747A96))),
                  const SizedBox(height: 24),
                  const Divider(),
                  const ListTile(leading: Icon(Icons.verified_user_outlined, color: Color(0xFF7137E9)), title: Text('Role-based access'), subtitle: Text('Permissions are controlled through your Firestore user profile.')),
                  const ListTile(leading: Icon(Icons.cloud_done_outlined, color: Colors.green), title: Text('Live data connection'), subtitle: Text('Announcements, queries, and campus content update in real time.')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Logout')),
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _adminSettingsPage() => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE4E3F2))),
              child: Column(children: [
                const ListTile(title: Text('Admin settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), subtitle: Text('Preferences are not persisted in the current backend.')),
                const Divider(height: 1),
                const SwitchListTile(value: false, onChanged: null, secondary: Icon(Icons.notifications_active_outlined), title: Text('Desktop notifications'), subtitle: Text('Unavailable: no persisted alert-preference or delivery backend is configured.')),
                const SwitchListTile(value: false, onChanged: null, secondary: Icon(Icons.view_compact_outlined), title: Text('Compact data tables'), subtitle: Text('Unavailable: this display preference is not implemented or persisted.')),
                const ListTile(leading: Icon(Icons.security_outlined), title: Text('Security'), subtitle: Text('Authentication and roles are managed by Firebase Authentication and Firestore. Advanced privacy controls are not configured.')),
              ]),
            ),
          ),
        ),
      );

  Widget _adminHelpPage() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE4E3F2))),
              child: const Padding(
                padding: EdgeInsets.all(28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.help_outline, size: 42, color: Color(0xFF7137E9)),
                  SizedBox(height: 14),
                  Text('Help & Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF28234F))),
                  SizedBox(height: 10),
                  Text('Use Announcements to publish student updates, Student Queries to respond to students, and the campus content pages to maintain departments and radio programmes.', style: TextStyle(color: Color(0xFF747A96), height: 1.5)),
                  SizedBox(height: 20),
                  Text('Need access changes?', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Update the user role in the Firestore users collection. The next sign-in loads the new permissions.', style: TextStyle(color: Color(0xFF747A96))),
                ]),
              ),
            ),
          ),
        ),
      );

  // ============================================================
  // DASHBOARD PAGE
  // ============================================================

  Widget _dashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to the Admin Dashboard 👋',
            style: TextStyle(
              color: Color(0xFF28234F),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'You are logged in as ${widget.role} Administrator.',
            style: const TextStyle(
              color: Color(0xFF747A96),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 28),

          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _statCard(
                'Announcements',
                'announcements',
                Icons.campaign_outlined,
                const Color(0xFF7137E9),
                1,
              ),
              _statCard(
                'Student Queries',
                'student_queries',
                Icons.question_answer_outlined,
                Colors.orange,
                2,
              ),
              _statCard(
                'Radio Programmes',
                'radio_programmes',
                Icons.radio_outlined,
                Colors.pink,
                3,
              ),
              _statCard(
                'Departments',
                'departments',
                Icons.business_outlined,
                Colors.blue,
                4,
              ),
              _statCard(
                'Users',
                'users',
                Icons.people_outline,
                Colors.green,
                5,
              ),
            ],
          ),

          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus Radio',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF28234F),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'AI Powered Campus Radio administration panel.',
                  style: TextStyle(
                    color: Color(0xFF747A96),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Firebase Authentication is connected successfully.',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _adminRecentUpdates(),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(
    String title,
    String collection,
    IconData icon,
    Color color,
    int targetIndex,
  ) {
    return InkWell(
      onTap: () => setState(() => selectedIndex = targetIndex),
      borderRadius: BorderRadius.circular(15),
      child: Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          StreamBuilder<int>(
            stream: FirestoreService.instance.count(collection),
            builder: (context, snapshot) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.hasError ? '—' : '${snapshot.data ?? 0}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF28234F),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF747A96),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ============================================================
  // SIMPLE PAGE
  // ============================================================

  // ignore: unused_element
  Widget _simplePage({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 60,
              color: const Color(0xFF7137E9),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF28234F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF747A96),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'This module will be connected to the backend database next.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9297AD),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await AuthService.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}
