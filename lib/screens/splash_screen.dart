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

  // ---------------------------------------------------------------------------
  // 💾 [데이터 업로드 함수] - 사용 안 함 (주석으로 보관)
  // ---------------------------------------------------------------------------
  // Future<void> _uploadInitialData() async {
  //   final batch = FirebaseFirestore.instance.batch();
  //   final spacesCollection = FirebaseFirestore.instance.collection('spaces');
  //
  //   const Map<String, List<Map<String, dynamic>>> initialData = {
  //     "1기술관": [
  //       {
  //         'floor': '2F',
  //         'rooms': ['CAD실습실', '콘트롤러실습실'],
  //         'capacity': 20
  //       },
  //     ],
  //     "2기술관": [
  //       {
  //         'floor': '3F',
  //         'rooms': ['자동차과이론강의실', 'PLC실습실'],
  //         'capacity': 30
  //       },
  //       {
  //         'floor': '2F',
  //         'rooms': ['자동차과이론강의실', 'CAD/CAE실'],
  //         'capacity': 25
  //       },
  //       {
  //         'floor': '1F',
  //         'rooms': ['CATIA실습실', '전기자동차실습실', '자동차과이론강의실'],
  //         'capacity': 30
  //       },
  //     ],
  //     "3기술관": [
  //       {
  //         'floor': '1F',
  //         'rooms': ['아이디어 존'],
  //         'capacity': 15
  //       },
  //     ],
  //     "5기술관": [
  //       {
  //         'floor': '4F',
  //         'rooms': [
  //           '시제품창의개발실',
  //           '아이디어카페',
  //           '디자인워크샵실습실',
  //           '융합디자인실습실',
  //           '디지털디자인실습실',
  //           '미디어창작실습실'
  //         ],
  //         'capacity': 25
  //       },
  //       {
  //         'floor': '3F',
  //         'rooms': ['강의실', '스터디룸', '반도체제어실', '전자CAD실', '기초전자실습실'],
  //         'capacity': 30
  //       },
  //       {
  //         'floor': '2F',
  //         'rooms': ['AI융합프로젝트실습실', '인공지능프로그래밍실습실', 'ioT제어실습실'],
  //         'capacity': 25
  //       },
  //       {
  //         'floor': '1F',
  //         'rooms': ['개인미디어실', '세미나실', '미디어편집실', 'AR그래픽실', '실감형콘텐츠운영실습실'],
  //         'capacity': 20
  //       },
  //     ],
  //     "7기술관": [
  //       {
  //         'floor': '3F',
  //         'rooms': ['소그룹실', '강의실', '반도체 시스템 제작실'],
  //         'capacity': 15
  //       },
  //     ],
  //   };
  //
  //   for (var building in initialData.keys) {
  //     for (var floorData in initialData[building]!) {
  //       final floor = floorData['floor'] as String;
  //       final capacity = floorData['capacity'] as int;
  //
  //       for (var room in floorData['rooms'] as List<String>) {
  //         final docRef = spacesCollection.doc(); // 새 문서 ID 자동 생성
  //
  //         batch.set(docRef, {
  //           'name': room,
  //           'location': '$building $floor',
  //           'buildingName': building,
  //           'capacity': '$capacity명',
  //           'isReservable': true,
  //           'mainImageUrl': '',
  //           'view360Url': '',
  //           'createdAt': FieldValue.serverTimestamp(),
  //         });
  //       }
  //     }
  //   }
  //
  //   try {
  //     await batch.commit();
  //     print('✅✅✅ 초기 데이터 업로드 성공! (이제 이 함수 호출을 주석 처리하세요) ✅✅✅');
  //   } catch (e) {
  //     print('❌❌❌ 초기 데이터 업로드 실패: $e');
  //   }
  // }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 🔥 자동 업로드 제거!
      // await _uploadInitialData();

      print("✅ 로그인된 사용자 확인됨");

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
