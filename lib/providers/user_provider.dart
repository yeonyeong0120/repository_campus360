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
    // [수정된 부분] 안전 장치 추가: UID가 비어있으면 서버에 요청하지 않고 함수 종료
    if (uid.isEmpty) {
      print('UID가 비어있어 사용자 정보를 가져올 수 없습니다.');
      return;
    }

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
