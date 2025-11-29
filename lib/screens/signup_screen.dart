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

  // 학과 선택 관련... // 원랜 지워야하는데 일단 남겨두기
  final List<String> _departments = [
    '디지털융합제어과',
    '메카트로닉스과',
    'AI소프트웨어과',
    '영상디자인과',
  ];
  String? _selectedDept; // 선택한거 저장할곳

  void _handleSignup() async {
    // 오입력 방지!
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _studentIdController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("모든 정보를 입력해주세요.")),
        );
      }
      return;
    }
    
    // 여기부터 회원가입 로직
    try {
      String inputId = _studentIdController.text.trim();
      String inputName = _nameController.text.trim();

      // 명단부터 확인
      DocumentSnapshot whitelistDoc = await FirebaseFirestore.instance
          .collection('whitelist')
          .doc(inputId) // 입력한 학번으로 문서 찾기
          .get();

      // [추가] 명단 검증 로직
      if (!whitelistDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("등록된 학번이 없습니다.\n입력 정보를 확인해주세요!")),
          );
        }
        return;
      }

      // 명단에는 있는데, 이름이 다른 경우
      Map<String, dynamic> whitelistData = whitelistDoc.data() as Map<String, dynamic>;
      if (whitelistData['name'] != inputName) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("등록 정보가 일치하지 않습니다.\n입력 정보를 확인해주세요!")),
          );
        }
        return;
      }

      // 명단 정보 가져오기
      // 명단에 적혀있는 진짜 직급(role)과 학과(department)를 가져옵니다.
      String realRole = whitelistData['role'];
      String realDept = whitelistData['department'];

      // 5. Firebase Authentication에 계정 생성 (검증 통과 후 실행)
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      // UserModel 객체 생성
      // (사용자가 선택한 값이 아니라, 명단에 있는 '진짜 정보'를 저장합니다)
      UserModel newUser = UserModel(
        uid: uid,
        email: _emailController.text.trim(),
        name: inputName,
        studentId: inputId,
        department: realDept, // [수정] _selectedDept 대신 whitelist 정보 사용
        role: realRole,       // [수정] "student" 고정값 대신 whitelist 정보 사용 (admin 가능)
      );

      // Firestore 'users' 컬렉션에 정보 저장
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(newUser.toMap());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("인증 완료! 가입에 성공했습니다.")));
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
  } // 여기까지 _handleSignup 클래스

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("폴리텍 인증 회원가입")),
      body: SingleChildScrollView(   // 키보드 짜증나게하는거 방지..
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 안내 문구
              const Text(
              "학교에 등록된 정보(이름, 학번)와\n일치해야 가입이 가능합니다.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "이메일"),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "비밀번호"),
                obscureText: true,
              ),
              const SizedBox(height: 20), // 패딩대신주고싶어서...
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "이름"),
              ),
              TextField(
                controller: _studentIdController,
                decoration: InputDecoration(labelText: "학번"),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "학과 (참고용)"),
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSignup, 
                  child: const Text("가입하기", style: TextStyle(fontSize: 18)),
                  ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
