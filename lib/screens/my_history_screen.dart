import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  // 변수명 다시 _currentUser로 복구
  UserModel? _currentUser;

  // 🌟 [중요] 다른 화면들이 찾고 있는 이름인 'currentUser'로 되돌립니다.
  UserModel? get currentUser => _currentUser;

  // 찜 목록 Getter
  List<String> get favoriteSpaces => _currentUser?.favoriteSpaces ?? const [];

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Firestore에서 유저 정보 가져오기
  Future<void> fetchUserFromFirestore(String uid) async {
    if (uid.isEmpty) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        setUser(userModel);
      }
    } catch (e) {
      print('사용자 정보 로드 오류: $e');
    }
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
