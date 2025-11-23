// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'signup_screen.dart'; // 회원가입 화면 연결

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
              email: _emailController.text,
              password: _passwordController.text
          );

      // 2. 로그인 된 유저의 UID 가져오기
      String uid = userCredential.user!.uid;

      // 3. Firestore에서 내 정보(학과, 이름 등) 가져오기
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // 4. 가져온 정보를 UserModel로 변환
      if (userDoc.exists) {
        UserModel userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);

        // 5. 전광판(Provider)에 내 정보 등록!
        if (mounted) {
          context.read<UserProvider>().setUser(userModel);

          // 6. 성공 메시지 띄우기
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${userModel.name}님 환영합니다! 로그인 성공!"))
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("로그인 실패: ${e.message}"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
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
            
            const SizedBox(height: 10),
            
            // 회원가입 버튼
            TextButton(
              onPressed: () {
                // 회원가입 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: const Text("계정이 없으신가요? 회원가입"),
            )
          ],
        ),
      ),
    );
  }
}