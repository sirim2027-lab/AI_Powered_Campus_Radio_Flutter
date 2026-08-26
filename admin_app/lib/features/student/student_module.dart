import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../student/student_dashboard.dart';
import 'screens/student_onboarding_screen.dart';
import 'screens/student_splash_screen.dart';

/// Student-only entry flow shown after the authenticated Firestore role is verified.
class StudentModule extends StatefulWidget {
  const StudentModule({super.key, required this.user});
  final AppUser user;
  @override
  State<StudentModule> createState() => _StudentModuleState();
}

class _StudentModuleState extends State<StudentModule> {
  var _stage = 0;
  @override
  Widget build(BuildContext context) => switch (_stage) {
        0 => StudentSplashScreen(onComplete: () => setState(() => _stage = 1)),
        1 => StudentOnboardingScreen(onComplete: () => setState(() => _stage = 2)),
        _ => StudentDashboard(user: widget.user),
      };
}
