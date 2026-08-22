import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin/admin_management_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'models/app_user.dart';
import 'services/user_role_service.dart';
import 'student/student_dashboard.dart';
import 'student/student_login.dart';
import 'widgets/app_state_widgets.dart';

class CampusRadioApp extends StatelessWidget {
  const CampusRadioApp({super.key, required this.loginBuilder});
  final WidgetBuilder loginBuilder;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Campus Radio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _AuthSessionGate(loginBuilder: loginBuilder),
        onGenerateRoute: _route,
      );

  Route<dynamic> _route(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: loginBuilder, settings: settings);
      case AppRoutes.studentLogin:
        return MaterialPageRoute(
          builder: (_) => const StudentLoginPage(),
          settings: settings,
        );
      case AppRoutes.forgotPassword:
        // Password reset is handled by the login screen's existing action.
        return MaterialPageRoute(builder: loginBuilder, settings: settings);
      case AppRoutes.student:
        if (args is AppUser) return MaterialPageRoute(builder: (_) => StudentDashboard(user: args), settings: settings);
      case AppRoutes.admin:
        if (args is AppUser) return MaterialPageRoute(builder: (_) => AdminDashboard(role: args.roleLabel), settings: settings);
      case AppRoutes.adminAnnouncements:
        return MaterialPageRoute(builder: (_) => const AdminAnnouncementsFigmaPage(), settings: settings);
      case AppRoutes.adminQueries:
        return MaterialPageRoute(builder: (_) => const AdminQueriesPage(), settings: settings);
      case AppRoutes.adminNotifications:
        return MaterialPageRoute(builder: (_) => const AdminNotificationsFigmaPage(), settings: settings);
      case AppRoutes.adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUsersFigmaPage(), settings: settings);
      default:
        return MaterialPageRoute(builder: loginBuilder, settings: settings);
    }
  }
}

class _AuthSessionGate extends StatefulWidget {
  const _AuthSessionGate({required this.loginBuilder});
  final WidgetBuilder loginBuilder;

  @override
  State<_AuthSessionGate> createState() => _AuthSessionGateState();
}

class _AuthSessionGateState extends State<_AuthSessionGate> {
  late Future<AppUser?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<AppUser?> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return UserRoleService.instance.loadProfileForUid(user.uid);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const AppLoadingState();
          if (snapshot.hasError) return AppErrorState(message: 'Your account profile could not be loaded. Please contact the administrator or sign in again.', onRetry: () => setState(() => _profile = _loadProfile()));
          final profile = snapshot.data;
          if (profile == null) return widget.loginBuilder(context);
          if (profile.role == UserRole.student) return StudentDashboard(user: profile);
          if (profile.isStaff) return AdminDashboard(role: profile.roleLabel);
          return AppErrorState(message: 'Your account has no valid role.', onRetry: () => setState(() => _profile = _loadProfile()));
        },
      );
}
