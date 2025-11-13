// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart'; // 방금 만든 UserModel 가져오기

class UserProvider with ChangeNotifier {
  UserModel? _currentUser; // 앱 내에 저장될 사용자 정보

  UserModel? get currentUser => _currentUser;

  // 로그인 성공 시 이 함수를 호출
  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners(); // "전광판" 내용 변경! -> 알림
  }

  // 로그아웃 시
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
