// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String studentId;
  final String department;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.studentId,
    required this.department,
    required this.role,
  });

  // Firestore에서 데이터를 읽을 때 사용할 팩토리 생성자
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      studentId: map['studentId'] ?? '',
      department: map['department'] ?? '',
      role: map['role'] ?? '',
    );
  }

  // Firestore에 데이터를 쓸 때 사용할 메서드
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'studentId': studentId,
      'department': department,
      'role': role,
    };
  }
}
