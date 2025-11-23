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

  // 학과 선택 관련...
  final List<String> _departments = [
    '디지털융합제어과',
    '메카트로닉스과',
    'AI소프트웨어과',
    '영상디자인과',
  ];
  String? _selectedDept; // 선택한거 저장할곳

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
        department: _selectedDept ?? "학과미정", // 선택 안 했으면 기본값
        role: "student", // 고정
      );

      // 3. Firestore 'users' 컬렉션에 정보 저장
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(newUser.toMap());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("가입 성공! 로그인해주세요!")));
        Navigator.pop(context); // 화면 닫기
      }

      // (회원가입 성공 시 로그인 화면으로 이동 등...)
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text("가입 실패: ${e.message}")));
      }
    }
  } // _handleSignup 클래스

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
            const SizedBox(height: 10), // 살짝 띄우기
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "학과 선택"),
              initialValue: _selectedDept,
              items: _departments.map((String dept) {
                return DropdownMenuItem<String>(value: dept, child: Text(dept));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedDept = newValue;
                });
              },
            ),
            const SizedBox(height: 20), // 버튼이랑 같이
            ElevatedButton(onPressed: _handleSignup, child: Text("가입하기")),
          ],
        ),
      ),
    );
  }
}
