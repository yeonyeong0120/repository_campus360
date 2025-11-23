// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart'; // 로그아웃 시 이동할 화면
import 'map_screen.dart'; // 지도 화면 연결

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
      body: Padding(
        padding: const EdgeInsets.all(20.0), // 전체 여백 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
          children: [
            // 1. 상단 환영 메시지
            Text(
              "안녕하세요, ${user?.name ?? '학우'}님! 🌱", 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Align(
              alignment: AlignmentGeometry.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Text(
                  user?.department != null ? "${user!.department} 전공" : "소속 미정", 
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey)
                ),
              ),
            ),

            const SizedBox(height: 30), // 간격 띄우기

            // 최근 예약한 강의실 // 아직은 모양만!!
            const Text("최근 예약한 강의실", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Card(
              margin: EdgeInsets.only(top: 10),
              child: ListTile(
                leading: Icon(Icons.history, color: Colors.orange),
                title: Text("최근 예약 기록이 없습니다."),
              ),
            ),

            const SizedBox(height: 80), // 약간 아래로 밀기 // 나중에 수정할지도..

            // 2. 공간 찾아보기 버튼 (지도로 이동)
            const Text("원하는 공간을 찾아보세요!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, // 버튼 꽉 채우기
              child: ElevatedButton.icon(
                onPressed: () {
                  // 지도 화면으로 이동
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                },
                icon: const Icon(Icons.map),
                label: const Text("지도에서 공간 찾기"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15), 
                  textStyle: const TextStyle(fontSize: 18)
                ),
              ),
            ),
            const SizedBox(height: 20), // 바닥에서 살짝 띄우기
          ],
        ),
      ),
      
      // 3. 플로팅 버튼 챗봇? (나중에 구현 예정)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 챗봇 열기...
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}