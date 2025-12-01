// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
// 🛠 [수정] 상대 경로로 변경하여 import 에러 방지
import 'home_screen.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'signup_screen.dart'; // 회원가입 화면 연결
import 'admin_screen.dart'; // 어드민 연결
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🛠 [추가] 중복 로그인 시도 방지를 위한 로딩 상태 변수
  bool _isLoading = false;

  void _handleLogin() async {
    // 🛠 [추가] 이미 로딩 중이면 함수 실행 막기 (중복 실행 방지)
    if (_isLoading) return;

    // 키보드 내리기
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      // 1. Firebase 로그인 시도
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      // 2. 로그인 된 유저의 UID 가져오기
      String uid = userCredential.user!.uid;

      // 3. Firestore에서 내 정보(학과, 이름 등) 가져오기
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // 4. 가져온 정보를 UserModel로 변환
      if (userDoc.exists) {
        UserModel userModel =
            UserModel.fromMap(userDoc.data() as Map<String, dynamic>);

        // 5. 전광판(Provider)에 내 정보 등록!
        if (mounted) {
          context.read<UserProvider>().setUser(userModel);

          // 🛠 [수정] SnackBar 중복 방지 및 FAB 고정을 위한 설정
          // 기존 메시지가 있다면 제거 (두 번 뜨는 현상 방지)
          ScaffoldMessenger.of(context).clearSnackBars();

          // 6. 성공 메시지 띄우기 (화면 이동 전에 띄움)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${userModel.name}님 환영합니다! 로그인 성공!",
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'manru'), // 폰트 적용
              ),
              backgroundColor: const Color.fromARGB(255, 32, 51, 74),
              // 🛠 [추가] SnackBar가 떠도 FAB가 밀리지 않도록 floating 설정
              behavior: SnackBarBehavior.floating,
              // 🛠 [추가] 하단에서 약간 띄워서 렌더링 (가려져도 상관없으므로 고정 효과)
              margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
              duration: const Duration(seconds: 2), // 2초 뒤 사라짐
            ),
          );

          if (mounted) {
            // Role이 admin이면 관리자 페이지로, 아니면 홈으로~~
            if (userModel.role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminScreen()), // 관리자 페이지로 납치!
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const HomeScreen()), // 학생은 홈으로
              );
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("로그인 실패: ${e.message}")));
      }
    } finally {
      // 🛠 [추가] 로딩 상태 해제 (성공하든 실패하든)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 계산 (반응형 디자인을 위해)
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경 흰색
      body: SingleChildScrollView(
        // 키보드가 올라와도 스크롤 가능하게
        child: Column(
          children: [
            // 🎨 [디자인 1] 상단 곡선 헤더 영역
            Stack(
              children: [
                // 파란색 그라데이션 배경
                Container(
                  // 🎨 로고가 커졌으므로 헤더 높이도 40% -> 45%로 살짝 늘려줌 (답답하지 않게)
                  height: size.height * 0.40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF64B5F6)], // 브랜드 컬러
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(60), // 왼쪽 아래 둥글게
                    ),
                  ),
                ),

                // 배경 꾸미기 (반투명 원)
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // 로고 및 텍스트 (헤더 중앙 정렬)
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🌟 [유저 설정 유지] 3D 캐릭터 이미지 크기
                      Container(
                        child: Image.asset(
                          'assets/images/logo_3d.png',
                          width: 260, // 설정하신 값 유지
                          height: 260, // 설정하신 값 유지
                          // 만약 이미지가 없으면 아이콘 대체
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.calendar_month,
                                size: 150, color: Colors.white);
                          },
                        ),
                      ),

                      // 이미지의 투명 여백 때문에 멀어 보이는 것을 해결하기 위해 Transform.translate 사용
                      Transform.translate(
                        offset: const Offset(0, -28), // 설정하신 값 유지
                        child: Column(
                          children: [
                            const Text(
                              "Smart Campus 360",
                              style: TextStyle(
                                fontSize: 33, // 설정하신 값 유지
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'manru',
                                letterSpacing: 1.0,
                              ),
                            ),

                            // 🛠 [수정] 중복된 SizedBox 제거하고 하나만 남김
                            const SizedBox(height: 5),

                            const Text(
                              "스마트한 대학 생활의 시작",
                              style: TextStyle(
                                fontSize: 20, // 설정하신 값 유지
                                color: Colors.white70, // 살짝 투명하게
                                fontFamily: 'manru',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 📝 입력 폼 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "로그인",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'manru',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🎨 [디자인 2] 이메일 입력창 (박스형)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16), // 더 둥글게
                    ),
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(fontFamily: 'manru'),
                      decoration: const InputDecoration(
                        prefixIcon:
                            Icon(Icons.email_outlined, color: Colors.grey),
                        hintText: "이메일",
                        hintStyle:
                            TextStyle(color: Colors.grey, fontFamily: 'manru'),
                        border: InputBorder.none, // 테두리 없애기
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🎨 [디자인 2] 비밀번호 입력창 (박스형)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(fontFamily: 'manru'),
                      onSubmitted: (_) => _handleLogin(), // 엔터키 로그인 유지
                      decoration: const InputDecoration(
                        prefixIcon:
                            Icon(Icons.lock_outline, color: Colors.grey),
                        hintText: "비밀번호",
                        hintStyle:
                            TextStyle(color: Colors.grey, fontFamily: 'manru'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🎨 [디자인 3] 로그인 버튼 (크고 둥글게)
                  SizedBox(
                    width: double.infinity,
                    height: 56, // 버튼 높이 키움
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _handleLogin, // 🛠 [수정] 로딩 중이면 버튼 비활성화
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3), // 브랜드 컬러
                        foregroundColor: Colors.white,
                        elevation: 8, // 그림자 진하게
                        shadowColor: Colors.blueAccent.withValues(alpha: .4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // 둥글게
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white) // 🛠 [추가] 로딩 중엔 인디케이터 표시
                          : const Text(
                              "로그인",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'manru',
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 하단 링크들 (회원가입, 비번찾기)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          "회원가입",
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'manru',
                          ),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          "비밀번호 찾기",
                          style: TextStyle(
                              color: Colors.grey, fontFamily: 'manru'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40), // 하단 여백 확보
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
