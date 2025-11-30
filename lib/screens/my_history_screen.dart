// lib/screens/my_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';

class MyHistoryScreen extends StatelessWidget {
  const MyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 탭 2개 (예약 / 신고)
      child: Scaffold(
        appBar: AppBar(
          title: const Text("나의 활동 내역"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "예약 내역"),
              Tab(text: "신고 내역"),
            ],
          ),
        ),
        body: Column(
          children: [
            const Expanded(
              child: TabBarView(
                children: [
                  _MyReservationList(),
                  _MyRepairList(),
                ],
              ),
            ),

            // 로그아웃
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<UserProvider>().clearUser();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false, // 뒤로가기 스택 일단 비우기...
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.grey),
                  label: const Text("로그아웃", style: TextStyle(color: Colors.grey)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 탭 1. 나의 예약 내역 리스트
// ---------------------------------------------------------
class _MyReservationList extends StatelessWidget {
  const _MyReservationList();

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return const Center(child: Text("로그인 정보 없음"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: user.uid) // 👈 내 것만 가져오기!
          .orderBy('startTime', descending: true) // 최신순 정렬
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("예약 내역이 없습니다."));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              // 상태에 따라 카드 색상을 살짝 다르게 (확정=초록, 대기=노랑, 취소=회색)
              color: status == 'confirmed' ? Colors.green[50] : 
                     status == 'cancelled' ? Colors.grey[200] : Colors.orange[50],
              child: ListTile(
                title: Text(data['spaceName'] ?? '공간명 없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${data['date']} ${data['timeSlot']}"),
                trailing: Chip(
                  label: Text(
                    status == 'confirmed' ? "확정됨" : 
                    status == 'cancelled' ? "취소됨" : "승인 대기",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: status == 'confirmed' ? Colors.green : 
                                   status == 'cancelled' ? Colors.grey : Colors.orange,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------
// 탭 2. 나의 수리/불편 신고 내역 리스트
// ---------------------------------------------------------
class _MyRepairList extends StatelessWidget {
  const _MyRepairList();

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return const Center(child: Text("로그인 정보 없음"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('repairRequests')
          .where('userId', isEqualTo: user.uid) // 👈 내 것만 가져오기!
          .orderBy('requestedAt', descending: true) // 최신순 정렬
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("데이터 로딩 오류 (색인 필요)"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("신고 내역이 없습니다."));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isCompleted = data['status'] == 'completed';

            return Card(
              child: ListTile(
                leading: Icon(Icons.build, color: isCompleted ? Colors.blue : Colors.grey),
                title: Text(data['spaceName'] ?? '공간명 없음'),
                subtitle: Text(data['description'] ?? '내용 없음', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  isCompleted ? "처리 완료" : "접수됨",
                  style: TextStyle(
                    color: isCompleted ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}