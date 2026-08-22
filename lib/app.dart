import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin/admin_management_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'models/app_user.dart';
import 'features/student/student_module.dart';
import 'widgets/app_state_widgets.dart';

class CampusRadioApp extends StatelessWidget {
  const CampusRadioApp({
    super.key,
    required this.loginBuilder,
    required this.adminBuilder,
  });

  final WidgetBuilder loginBuilder;
  final Widget Function(AppUser profile, {int initialIndex}) adminBuilder;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Campus Radio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _AuthSessionGate(
          loginBuilder: loginBuilder,
          adminBuilder: adminBuilder,
        ),
        onGenerateRoute: _route,
      );

  Route<dynamic> _route(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: loginBuilder, settings: settings);
      case AppRoutes.student:
        return _protectedRoute(
          settings: settings,
          allowedRoles: const {UserRole.student},
          builder: (profile) => StudentModule(user: profile),
        );
      case AppRoutes.admin:
        return _protectedRoute(
          settings: settings,
          allowedRoles: _staffRoles,
          builder: (profile) => adminBuilder(profile),
        );
      case AppRoutes.adminRadio:
        return _protectedRoute(
          settings: settings,
          allowedRoles: _staffRoles,
          builder: (profile) => adminBuilder(profile, initialIndex: 3),
        );
      case AppRoutes.adminDepartments:
        return _protectedRoute(
          settings: settings,
          allowedRoles: _staffRoles,
          builder: (profile) => adminBuilder(profile, initialIndex: 4),
        );
      case AppRoutes.adminSettings:
        return _protectedRoute(
          settings: settings,
          allowedRoles: _staffRoles,
          builder: (profile) => adminBuilder(profile, initialIndex: 8),
        );
      case AppRoutes.adminAnnouncements:
        return _protectedRoute(
          settings: settings,
          allowedRoles: _staffRoles,
          builder: (_) => const AdminAnnouncementsFigmaPage(),
        );
      case AppRoutes.adminQueries:
        return _protectedRoute(
          settings: settings,
          allowedRoles: _staffRoles,
          builder: (_) => const AdminQueriesPage(),
        );
      case AppRoutes.adminNotifications:
        return _protectedRoute(
          settings: settings,
          allowedRoles: _staffRoles,
          builder: (_) => const AdminNotificationsFigmaPage(),
        );
      case AppRoutes.adminUsers:
        return _protectedRoute(
          settings: settings,
          allowedRoles: _staffRoles,
          builder: (_) => const AdminUsersFigmaPage(),
        );
      default:
        return MaterialPageRoute(builder: loginBuilder, settings: settings);
    }
  }

  Route<dynamic> _protectedRoute({
    required RouteSettings settings,
    required Set<UserRole> allowedRoles,
    required Widget Function(AppUser profile) builder,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _RoleProtectedPage(
        allowedRoles: allowedRoles,
        builder: builder,
      ),
    );
  }
}

const _staffRoles = {
  UserRole.superAdmin,
  UserRole.admin,
  UserRole.staff,
};

class _AuthSessionGate extends StatelessWidget {
  const _AuthSessionGate({
    required this.loginBuilder,
    required this.adminBuilder,
  });

  final WidgetBuilder loginBuilder;
  final Widget Function(AppUser profile, {int initialIndex}) adminBuilder;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState();
          }

          final user = snapshot.data;
          if (user == null) return loginBuilder(context);
          return _ProfileGate(uid: user.uid, adminBuilder: adminBuilder);
        },
      );
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({required this.uid, required this.adminBuilder});

  final String uid;
  final Widget Function(AppUser profile, {int initialIndex}) adminBuilder;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<AppUser> _profile;

  @override
  void initState() {
    super.initState();
    _profile = AuthService.instance.loadProfileForUid(widget.uid);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState();
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message:
                  'Your account profile is missing or has an invalid role. Please contact the administrator.',
              actionLabel: 'Return to login',
              onRetry: _signOutAndReturnToLogin,
            );
          }

          final profile = snapshot.data!;
          if (profile.role == UserRole.student) {
            return StudentModule(user: profile);
          }
          if (profile.isStaff) {
            return widget.adminBuilder(profile);
          }
          return AppErrorState(
            message: 'Your account has no valid role.',
            onRetry: () => setState(
              () => _profile = AuthService.instance.loadProfileForUid(widget.uid),
            ),
          );
        },
      );

  Future<void> _signOutAndReturnToLogin() async {
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}

class _RoleProtectedPage extends StatefulWidget {
  const _RoleProtectedPage({
    required this.allowedRoles,
    required this.builder,
  });

  final Set<UserRole> allowedRoles;
  final Widget Function(AppUser profile) builder;

  @override
  State<_RoleProtectedPage> createState() => _RoleProtectedPageState();
}

class _RoleProtectedPageState extends State<_RoleProtectedPage> {
  late Future<AppUser?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = AuthService.instance.loadCurrentProfile();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState();
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'We could not verify your account permissions.',
              onRetry: () => setState(
                () => _profile = AuthService.instance.loadCurrentProfile(),
              ),
            );
          }

          final profile = snapshot.data;
          if (profile == null || !widget.allowedRoles.contains(profile.role)) {
            return const _AccessDeniedPage();
          }
          return widget.builder(profile);
        },
      );
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 52),
                const SizedBox(height: 12),
                const Text(
                  'You do not have permission to open this screen.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () async {
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Return to login'),
                ),
              ],
            ),
          ),
        ),
      );
}
