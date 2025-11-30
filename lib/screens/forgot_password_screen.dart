// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false; // 전송 중 로딩 표시용

  void _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이메일을 입력해주세요.")),
      );
      return;
    }

    setState(() {
      _isSending = true; // 로딩 시작
    });

    try {
      // Firebase 비밀번호 재설정 이메일 발송
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("재설정 이메일을 보냈습니다! 메일함을 확인해주세요.")),
        );
        Navigator.pop(context); // 전송 성공하면 로그인 화면으로 복귀
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = "전송 실패";
        if (e.code == 'user-not-found') {
          errorMessage = "가입되지 않은 이메일입니다.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "이메일 형식이 올바르지 않습니다.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false; 
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("비밀번호 찾기")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "가입하신 이메일 주소를 입력하시면\n비밀번호 재설정 링크를 보내드립니다.",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "이메일",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendResetEmail, // 로딩 중 클릭 방지
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("재설정 이메일 보내기", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}