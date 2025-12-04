import 'package:flutter/material.dart';
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

  // 학과 선택 관련 (참고용)
  final List<String> _departments = [
    '디지털융합제어과',
    '메카트로닉스과',
    'AI소프트웨어과',
    '영상디자인과',
  ];
  String? _selectedDept;

  final Color _backgroundColor = const Color(0xFFF5F7FA); // 배경색 통일

  void _handleSignup() async {
    // 1. 입력 확인
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _studentIdController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("모든 정보를 입력해주세요."),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // 2. 회원가입 로직
    try {
      String inputId = _studentIdController.text.trim();
      String inputName = _nameController.text.trim();

      // 명단 확인
      DocumentSnapshot whitelistDoc = await FirebaseFirestore.instance
          .collection('whitelist')
          .doc(inputId)
          .get();

      // 명단 검증
      if (!whitelistDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("등록된 학번이 없습니다.\n입력 정보를 확인해주세요!"),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }

      // 이름 일치 확인
      Map<String, dynamic> whitelistData =
          whitelistDoc.data() as Map<String, dynamic>;
      if (whitelistData['name'] != inputName) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("등록 정보가 일치하지 않습니다.\n입력 정보를 확인해주세요!"),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }

      // 명단 정보 가져오기 (진짜 권한 및 학과)
      String realRole = whitelistData['role'];
      String realDept = whitelistData['department'];

      // 3. Firebase Auth 계정 생성
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 프로필 업데이트
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(inputName);
        await userCredential.user!.reload();
      }

      String uid = userCredential.user!.uid;

      // 4. Firestore 저장 (UserModel)
      UserModel newUser = UserModel(
        uid: uid,
        email: _emailController.text.trim(),
        name: inputName,
        studentId: inputId,
        department: realDept, // 명단의 실제 학과 사용
        role: realRole, // 명단의 실제 권한 사용
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(newUser.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("인증 완료! 가입에 성공했습니다."),
          duration: Duration(seconds: 1),
        ));
        Navigator.pop(context); // 화면 닫기
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("가입 실패: ${e.message}"),
          duration: const Duration(seconds: 1),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // 배경색 적용
      appBar: AppBar(
        title: const Text("회원가입",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'manru')),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 안내 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "학교에 등록된 정보(이름, 학번)와\n일치해야 가입이 가능합니다.",
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            height: 1.4,
                            fontFamily: 'manru'), // 안내 문구는 디자인 폰트 유지
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 입력 폼 박스
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("계정 정보",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'manru')),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _emailController,
                        label: "이메일",
                        icon: Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _passwordController,
                        label: "비밀번호",
                        icon: Icons.lock_outline,
                        isObscure: true),

                    const Divider(height: 40),

                    const Text("학생 인증 정보",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'manru')),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _nameController,
                        label: "이름 (실명)",
                        icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _studentIdController,
                        label: "학번",
                        icon: Icons.badge_outlined,
                        isNumber: true),
                    const SizedBox(height: 16),

                    // 학과 선택 드롭다운 (스타일 통일)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          icon: Icon(Icons.school_outlined, color: Colors.grey),
                          border: InputBorder.none,
                          labelText: "학과 (참고용)",
                          labelStyle: TextStyle(
                              color: Colors.grey, fontFamily: 'manru'),
                        ),
                        dropdownColor: Colors.white,
                        initialValue: _selectedDept,
                        items: _departments.map((String dept) {
                          return DropdownMenuItem<String>(
                              value: dept,
                              child: Text(dept,
                                  style: const TextStyle(fontFamily: 'manru')));
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDept = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 가입 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("가입하기",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'manru')),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 텍스트 필드 디자인 위젯
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        // 🔥 [수정 포인트] 입력되는 글씨체는 기본 폰트(Roboto 등)로 설정하여 가독성 확보
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontFamily: 'Roboto', // 기본 폰트로 지정 (manru 제외)
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          labelText: label,
          // 라벨(이메일, 비밀번호 등)은 디자인 통일성을 위해 manru 유지
          labelStyle: const TextStyle(color: Colors.grey, fontFamily: 'manru'),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
