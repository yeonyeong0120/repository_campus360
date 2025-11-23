// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
// _handleSignup 함수 내부에서 쓸거 임포트 (signup_screen.dart)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // UserModel 임포트

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  // ... (학과 선택을 위한 String 변수 등) ...

  void _handleSignup() async {
    try {
      // 1. Firebase Authentication에 계정 생성
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

      String uid = userCredential.user!.uid;

      // 2. UserModel 객체 생성
      UserModel newUser = UserModel(
        uid: uid,
        email: _emailController.text,
        name: _nameController.text,
        studentId: _studentIdController.text,
        department: "디지털융합제어과", // (임시, 드롭다운 값으로 변경 필요)
        role: "student", // 고정
      );

      // 3. Firestore 'users' 컬렉션에 정보 저장
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(newUser.toMap());

      // (회원가입 성공 시 로그인 화면으로 이동 등...)
    } on FirebaseAuthException catch (e) {
      // (에러 처리...)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "이메일"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "비밀번호"),
              obscureText: true,
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "이름"),
            ),
            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(labelText: "학번"),
            ),
            // (학과 선택 드롭다운 UI 추가...)
            ElevatedButton(onPressed: _handleSignup, child: Text("가입하기")),
          ],
        ),
      ),
    );
  }
}
