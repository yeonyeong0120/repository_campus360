import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  // 💡 찜 목록을 가져오는 Getter
  List<String> get favoriteSpaces => _currentUser?.favoriteSpaces ?? const [];

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Firestore에서 UID를 사용하여 사용자 정보를 가져와 상태를 갱신하는 메서드
  Future<void> fetchUserFromFirestore(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data()!);
        setUser(userModel);
      }
    } catch (e) {
      // print('사용자 정보 로드 오류: $e');
    }
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
