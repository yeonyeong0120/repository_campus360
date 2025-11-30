// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:repository_campus360/screens/home_screen.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'signup_screen.dart'; // 회원가입 화면 연결
import 'admin_screen.dart'; // 어드민 연결

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
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
          if (mounted) {
            // Role이 admin이면 관리자 페이지로, 아니면 홈으로~~
            if (userModel.role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()), // 관리자 페이지로 납치!
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()), // 학생은 홈으로
              );
            }
          }

          // 6. 성공 메시지 띄우기
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${userModel.name}님 환영합니다! 로그인 성공!",
                style: const TextStyle(color: Colors.white), // 👈 검정색 폰트
              ),
              backgroundColor: const Color.fromARGB(255, 32, 51, 74),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("로그인 실패: ${e.message}")));
      }
    }
  }

  // [추가] 비밀번호 재설정 메일 발송 함수
  void _handleFindPassword() async {
    final email = _emailController.text.trim();

    // 1. 이메일 입력 확인
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호를 찾을 이메일을 위 입력창에 적어주세요.")),
      );
      return;
    }

    try {
      // 2. Firebase에게 메일 발송 요청 (이게 핵심 코드!)
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("재설정 이메일을 보냈습니다! 메일함을 확인해주세요.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 3. 에러 처리 (예: 가입되지 않은 이메일 등)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("발송 실패: ${e.message}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("폴리텍 로그인")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "비밀번호"),
              obscureText: true,
              onSubmitted: (_) => _handleLogin(), // 엔터키로 로그인
            ),
            const SizedBox(height: 30),

            // 로그인 버튼
            SizedBox(
              width: double.infinity, // 버튼 꽉 채우기
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogin,
                child: const Text("로그인", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 15),

            // 회원가입 버튼  // + 비번찾기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text("회원가입", style: TextStyle(color: Colors.blue)), // 강조색
                ),
                const Text("|", style: TextStyle(color: Colors.grey)), // 구분선  
                TextButton(
                  onPressed: _handleFindPassword, // 비번찾기 함수
                  child: const Text("비밀번호 찾기", style: TextStyle(color: Colors.grey)),
                ),                
                              
                
              ], // children
            ),
          ],
        ),
      ),
    );
  }
}
