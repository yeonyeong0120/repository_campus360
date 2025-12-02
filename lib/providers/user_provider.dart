import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  // 1. 내부 변수 (남들은 못 건드림)
  UserModel? _currentUser;

  // 🌟 [여기가 핵심!]
  // 다른 화면들이 "currentUser 내놔!" 할 때 "여기 있어~" 하고 주는 역할입니다.
  // 이 줄이 없으면 다른 모든 화면에서 에러가 납니다.
  UserModel? get currentUser => _currentUser;

  // 💡 찜 목록 가져오기 (기존 기능)
  List<String> get favoriteSpaces => _currentUser?.favoriteSpaces ?? const [];

  // 유저 정보 저장
  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Firestore에서 정보 가져오기
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
      // ignore: avoid_print
      print('사용자 정보 로드 오류: $e');
    }
  }

  // 로그아웃 시 초기화
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
