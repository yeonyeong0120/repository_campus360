// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'signup_screen.dart';
import 'admin_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        UserModel userModel =
            UserModel.fromMap(userDoc.data() as Map<String, dynamic>);

        if (mounted) {
          context.read<UserProvider>().setUser(userModel);
          ScaffoldMessenger.of(context).clearSnackBars();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${userModel.name}님 환영합니다! 체크인 성공!",
                style:
                    const TextStyle(color: Colors.white, fontFamily: 'manru'),
              ),
              backgroundColor: const Color(0xFF1565C0),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
              duration: const Duration(seconds: 1), // 1초 설정
            ),
          );

          if (mounted) {
            if (userModel.role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("로그인 실패: ${e.message}"),
          duration: const Duration(seconds: 1), // 1초 설정
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 로고 & 타이틀 영역
                Container(
                  padding: const EdgeInsets.all(20), // 패딩 조금 더 줌
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // 🔥 [수정] 배경색을 조금 더 진하게 (0.05 -> 0.1)
                    color: Colors.blue.withValues(alpha: 0.1),
                  ),
                  child: Image.asset(
                    'assets/images/logo_3d.png',
                    width: 180, // 크기 살짝 조정
                    height: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.school_rounded,
                          size: 60, color: mainBlue);
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
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      "360",
                      style: TextStyle(
                        fontFamily: 'manru',
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: mainBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // 2. 입력 폼 영역
                _buildInputField(
                  controller: _emailController,
                  icon: Icons.alternate_email_rounded,
                  hint: "User Email",
                  isObscure: false,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: _passwordController,
                  icon: Icons.lock_outline_rounded,
                  hint: "Password",
                  isObscure: true,
                  onSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: 30),

                // 3. 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "로그인하기",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'manru',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // 4. 구분선
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

                const SizedBox(height: 30),

                // 5. 하단 링크들
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTextButton("회원가입", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    }, isBold: true),
                    Container(
                      height: 12,
                      width: 1,
                      color: Colors.grey.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildTextButton("비밀번호를 잃어버렸어요", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen()),
                      );
                    }, isBold: false),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 입력창 디자인 수정됨 (테두리 추가 + 색상 진하게)
  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isObscure,
    Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        // 🔥 배경색 진하게 변경 (0.05 -> 0.1)
        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        // 🔥 테두리 추가 (눈에 잘 띄게)
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Theme(
        data: ThemeData(
          colorScheme: Theme.of(context).colorScheme,
          useMaterial3: true,
        ),
        child: TextField(
          controller: controller,
          obscureText: isObscure,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.withValues(alpha: 0.6),
              fontSize: 14,
              fontFamily: 'manru',
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed,
      {required bool isBold}) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: isBold ? const Color(0xFF1565C0) : Colors.grey,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'manru',
          fontSize: 14,
        ),
      ),
    );
  }
}
