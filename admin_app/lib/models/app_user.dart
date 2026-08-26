enum UserRole { superAdmin, admin, staff, student, unknown }

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.department,
    this.studentId,
    this.semester,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? department;
  final String? studentId;
  final String? semester;

  bool get isStaff => role == UserRole.superAdmin || role == UserRole.admin || role == UserRole.staff;

  String get roleLabel => switch (role) {
        UserRole.superAdmin => 'Super',
        UserRole.admin => 'Admin',
        UserRole.staff => 'Staff',
        UserRole.student => 'Student',
        UserRole.unknown => 'Unknown',
      };

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    final value = (data['role'] as String? ?? '').trim().toLowerCase();
    final role = switch (value) {
      'super' || 'super admin' || 'superadmin' || 'super_admin' =>
        UserRole.superAdmin,
      'admin' => UserRole.admin,
      'staff' => UserRole.staff,
      'student' => UserRole.student,
      _ => UserRole.unknown,
    };
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: role,
      department: data['department'] as String?,
      studentId: data['studentId'] as String?,
      semester: data['semester'] as String?,
    );
  }
}
