class UserModel {
  final String idUser;
  final String username;
  final String role; // 'Admin', 'Guru', 'Siswa', 'Alumni'
  final String? idRef;
  final String fullName;
  final Map<String, dynamic>? studentProfile;

  UserModel({
    required this.idUser,
    required this.username,
    required this.role,
    this.idRef,
    required this.fullName,
    this.studentProfile,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isGuru => role.toLowerCase() == 'guru';
  bool get isSiswa => role.toLowerCase() == 'siswa';
  bool get isAlumni => role.toLowerCase() == 'alumni';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['id_user']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Siswa',
      idRef: json['id_ref']?.toString(),
      fullName: json['full_name']?.toString() ?? 'Pengguna',
      studentProfile: json['student_profile'] is Map<String, dynamic>
          ? json['student_profile'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'username': username,
      'role': role,
      'id_ref': idRef,
      'full_name': fullName,
      'student_profile': studentProfile,
    };
  }
}
