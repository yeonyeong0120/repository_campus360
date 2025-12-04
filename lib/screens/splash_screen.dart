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
    const Color mainBlue = Color(0xFF1565C0);
    const Color bgWhite = Colors.white;

    return Scaffold(
      backgroundColor: bgWhite,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // 1. 메인 로고 & 타이틀
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.05),
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
                          fontSize: 56,
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

            // 2. 하단 정보 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 점선 (Divider)
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

                  // 출발 -> 도착 정보
                  Row(
                    children: [
                      // 1. 왼쪽 (DEPART) - 1/3 공간 차지
                      Expanded(
                        child: _buildFlightInfo(
                            "DEPART", "HOME", CrossAxisAlignment.start // 왼쪽 정렬
                            ),
                      ),

                      // 2. 가운데 (아이콘) - 정중앙
                      Icon(
                        Icons.directions_run,
                        color: Colors.grey.withValues(alpha: 0.3),
                        size: 30,
                      ),

                      // 3. 오른쪽 (ARRIVE) - 1/3 공간 차지
                      Expanded(
                        child: Transform.translate(
                          // 🔥 [위치 조정] 여기서 숫자를 바꿔서 "CAMPUS" 글자 위치를 미세 조정하세요!
                          // x: -10 (왼쪽으로 당김), x: 10 (오른쪽으로 밈)
                          offset: const Offset(-10, 0),
                          child: _buildFlightInfo("ARRIVE", "CAMPUS",
                              CrossAxisAlignment.end // 오른쪽 정렬
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 로딩바
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(mainBlue),
                    minHeight: 2,
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

  // 텍스트 정보 위젯 (정렬 기능 추가됨)
  Widget _buildFlightInfo(
      String label, String value, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align, // 🔥 정렬 방향 설정
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
