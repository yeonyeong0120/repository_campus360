// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String studentId;
  final String department;
  final String role;
  // 💡 [추가] 사용자가 찜한 공간 ID 목록을 저장하는 필드
  final List<String> favoriteSpaces;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.studentId,
    required this.department,
    required this.role,
    // 💡 [추가] 초기화 리스트에 포함
    this.favoriteSpaces = const [],
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
      // 💡 [추가] Firestore 문서의 'favoriteSpaces' 배열을 읽어와 List<String>으로 변환
      favoriteSpaces: List<String>.from(map['favoriteSpaces'] ?? []),
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
      'favoriteSpaces': favoriteSpaces, // 💡 [추가] 찜 목록 포함
    };
  }
}
