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
// import 'dart:math' as math; // 🌟 회전 기능 뺐으니까 이건 이제 필요 없음!

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // lib/screens/splash_screen.dart 파일 내부 (initState 위에 새 함수 추가)

// 📌 [주의] 이 함수를 실행한 후에는 반드시 다시 주석 처리하거나 지워야 합니다.
    Future<void> uploadInitialData() async {
      final batch = FirebaseFirestore.instance.batch();
      final spacesCollection = FirebaseFirestore.instance.collection('spaces');

      const Map<String, List<Map<String, dynamic>>> initialData = {
        "1기술관": [
          {
            'floor': '2F',
            'rooms': ['CAD실습실', '콘트롤러실습실'],
            'capacity': 20
          },
        ],
        "2기술관": [
          {
            'floor': '3F',
            'rooms': ['자동차과이론강의실', 'PLC실습실'],
            'capacity': 30
          },
          {
            'floor': '2F',
            'rooms': ['자동차과이론강의실', 'CAD/CAE실'],
            'capacity': 25
          },
          {
            'floor': '1F',
            'rooms': ['CATIA실습실', '전기자동차실습실', '자동차과이론강의실'],
            'capacity': 30
          },
        ],
        "3기술관": [
          {
            'floor': '1F',
            'rooms': ['아이디어 존'],
            'capacity': 10
          },
        ],
        "5기술관": [
          {
            'floor': '4F',
            'rooms': [
              '시제품창의개발실',
              '아이디어카페',
              '디자인워크샵실습실',
              '융합디자인실습실',
              '디지털디자인실습실',
              '미디어창작실습실'
            ],
            'capacity': 20
          },
          {
            'floor': '3F',
            'rooms': ['강의실', '스터디룸', '반도체제어실', '전자CAD실', '기초전자실습실'],
            'capacity': 30
          },
          {
            'floor': '2F',
            'rooms': ['AI융합프로젝트실습실', '인공지능프로그래밍실습실', 'ioT제어실습실'],
            'capacity': 25
          },
          {
            'floor': '1F',
            'rooms': ['개인미디어실', '세미나실', '미디어편집실', 'AR그래픽실', '실감형콘텐츠운영실습실'],
            'capacity': 20
          },
        ],
        "7기술관": [
          {
            'floor': '3F',
            'rooms': ['소그룹실', '강의실', '반도체 시스템 제작실'],
            'capacity': 15
          },
        ],
      };

      for (var building in initialData.keys) {
        for (var floorData in initialData[building]!) {
          final floor = floorData['floor'] as String;
          final capacity = floorData['capacity'] as int;

          for (var room in floorData['rooms'] as List<String>) {
            final docRef = spacesCollection.doc(); // 새 문서 ID 생성

            batch.set(docRef, {
              'name': room,
              'location': '$building $floor', // 예: 1기술관 2F
              'buildingName': building,
              'capacity': '$capacity명', // DB에 저장되는 포맷
              'isReservable': true,
              'mainImageUrl':
                  'https://example.com/placeholder.jpg', // Placeholder
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      try {
        await batch.commit();
        print('✅ 초기 데이터 업로드 완료!');
      } catch (e) {
        print('❌ 초기 데이터 업로드 실패: $e');
      }
    }

    _checkLoginStatus(); // 앱이 켜지면 로그인 상태 확인 시작!
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    // [테스트용] 앱 켤 때마다 강제 로그아웃 (나중에 주석 처리 하세요!)
    await FirebaseAuth.instance.signOut();

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
          UserModel userModel =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          context.read<UserProvider>().setUser(userModel);

          // 직급(role)에 따라 화면 분기 처리
          if (userModel.role == 'admin') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AdminScreen()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD), // 상단: 아주 연한 하늘색
              Colors.white, // 하단: 깔끔한 흰색
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 💡 1. 아이콘 크기 (200) 유지 (기울기 제거됨)
            Image.asset(
              'assets/images/logo_hi3d.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school_rounded,
                    size: 140, color: Color(0xFF1E88E5));
              },
            ),

            // 💡 2. 텍스트 부분 (폰트: manru 적용)
            Transform.translate(
              offset: const Offset(0, -30),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  // 🌟 [수정 완료] 여기 폰트 이름을 'manru'로 바꿨습니다!
                  style: const TextStyle(
                    fontFamily: 'manru', // 이제 앱 전체 설정과 똑같이 만루체 적용!
                    color: Color(0xFF0D47A1),
                    letterSpacing: 1.0,
                  ),
                  children: [
                    TextSpan(
                      text: "Campus Room\n",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.blue.withValues(alpha: .2),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: "360",
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900, // 숫자는 더 굵게!
                        color: const Color(0xFF2196F3),
                        shadows: [
                          Shadow(
                            color: Colors.blueAccent.withValues(alpha: .3),
                            offset: const Offset(3, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 60),

            // 3. 로딩 인디케이터
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                strokeWidth: 3,
                backgroundColor: Colors.white.withValues(alpha: .5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
