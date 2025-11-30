// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // 앱이 켜지면 로그인 상태 확인 시작!
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    // 로그인 사용자 확인
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 3-A. 로그인 되어 있음 -> DB에서 최신 정보 가져오기
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          // 정보가 있으면 Provider에 등록
          UserModel userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          context.read<UserProvider>().setUser(userModel);

          // 직급(role)에 따라 화면 분기 처리
          if (userModel.role == 'admin') {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const AdminScreen())
            );
          } else {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const HomeScreen())
            );
          }
        } else {
          // DB에 정보가 없으면 로그아웃 시키고 로그인 화면으로
          _navigateToLogin();
        }
      } catch (e) {
        // 에러 나면 로그인 화면으로
        _navigateToLogin();
      }
    } else {
      // 3-B. 로그인 안 되어 있음 -> 로그인 화면으로
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색 흰색
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 로고 이미지
            Image.asset(
              'assets/images/logo.png', 
              width: 200, // 크기 조절
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                // 이미지가 없을 경우...
                return const Icon(Icons.school, size: 100, color: Colors.blue);
              },
            ),
            const SizedBox(height: 5),
            
            // 2. 앱 이름 텍스트
            const Text(
              "Campus 360",
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Color(0xFF06679D),
                letterSpacing: 1.2, // 글자 간격
              ),
            ),
            const SizedBox(height: 50),
            
            // 프로그래스써클 표시
            const CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      ),
    );
  }
}