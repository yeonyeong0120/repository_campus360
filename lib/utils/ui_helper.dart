// lib/utils/ui_helper.dart
import 'package:flutter/material.dart';

class UiHelper {
  // 어디서든 이 함수만 부르면 1초짜리 팝업이 뜹니다.
  static void showPopup(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1), // 💡 여기서 시간을 바꾸면 앱 전체가 다 바뀝니다!
        behavior: SnackBarBehavior.floating, // 바닥에 붙지 않고 살짝 떠 있음
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 둥근 모서리 디자인
        ),
      ),
    );
  }
}
