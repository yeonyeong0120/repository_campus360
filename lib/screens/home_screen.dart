// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart'; // 로그아웃 시 이동할 화면

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 전광판(Provider)에서 로그인한 사용자 정보 가져오기
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      // 1. 상단 고정 바 (AppBar)
      appBar: AppBar(
        title: const Text("Smart Campus 360"),
        actions: [
          // 로그아웃 버튼
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // 로그아웃 로직 (전광판 비우기 + 화면 이동)
              context.read<UserProvider>().clearUser();
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen())
              );
            },
          ),
        ],
      ),
      
      // 2. 본문 (Body)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "안녕하세요, ${user?.name ?? '학우'}님!", 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "소속: ${user?.department ?? '학과미정'}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            // 여기에 공간 목록이 들어갈 예정 (Phase 2)
            const Text("예약 가능한 공간 목록이 여기에 표시됩니다."),
          ],
        ),
      ),
      
      // 3. 플로팅 버튼 (챗봇 등)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 챗봇 열기 기능... 아마도 나중에 구현?
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}