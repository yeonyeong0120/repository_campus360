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
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          UserModel userModel =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          context.read<UserProvider>().setUser(userModel);

          if (userModel.role == 'admin') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AdminScreen()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          }
        } else {
          _navigateToLogin();
        }
      } catch (e) {
        _navigateToLogin();
      }
    } else {
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
    // 색상 정의
    const Color mainBlue = Color(0xFF1565C0);
    const Color bgWhite = Colors.white;

    return Scaffold(
      backgroundColor: bgWhite,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 여백
            const Spacer(flex: 2),

            // 1. 메인 로고 & 타이틀 (캠퍼스 앱의 본질 90%)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로고 (가장 큼)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.05), // 은은한 배경 원
                    ),
                    child: Image.asset(
                      'assets/images/logo_hi3d.png',
                      width: 160,
                      height: 160,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.school_rounded,
                          size: 140,
                          color: mainBlue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 앱 타이틀
                  Column(
                    children: const [
                      Text(
                        "CAMPUS ROOM",
                        style: TextStyle(
                          fontFamily: 'manru',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        "360",
                        style: TextStyle(
                          fontFamily: 'manru',
                          fontSize: 56, // 압도적인 크기
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: mainBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // 2. 하단 정보 영역 (여행 컨셉 10% - 텍스트로만 은유적 표현)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 점선 (Divider) - 여행 티켓의 절취선을 단순화
                  Row(
                    children: List.generate(
                      20,
                      (index) => Expanded(
                        child: Container(
                          height: 1,
                          color: index % 2 == 0
                              ? Colors.grey.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 출발 -> 도착 정보 (여행 메타포)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFlightInfo("DEPART", "HOME"),
                      // 달리는 사람으로 변경
                      Icon(
                        Icons.directions_run,
                        color: Colors.grey.withValues(alpha: 0.3),
                        size: 30,
                      ),
                      _buildFlightInfo("ARRIVE", "CAMPUS"),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 로딩바
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(mainBlue),
                    minHeight: 2, // 아주 얇고 세련되게
                  ),
                  const SizedBox(height: 150),

                  // 로딩 텍스트
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "어플 체크인 중...",
                      style: TextStyle(
                        fontFamily: 'manru',
                        fontSize: 16,
                        color: mainBlue.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 텍스트 정보 위젯
  Widget _buildFlightInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'manru',
            fontSize: 10,
            color: Colors.grey.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'manru',
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
