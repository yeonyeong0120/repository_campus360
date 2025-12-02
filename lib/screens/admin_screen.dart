// lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 접근
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 탭 컨트롤러 설정  // 일단 탭 개수 2개
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("관리자 페이지"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            // 로그아웃 버튼
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<UserProvider>().clearUser();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
          // 탭바 (메뉴)
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: "예약 승인 관리"),
              Tab(icon: Icon(Icons.build), text: "수리 요청 관리"),
            ],
          ),
        ),
        // 탭 내용 (순서대로 배치)
        body: Column(
          children: [            

            // 탭 내용 (Expanded로 감싸서 남은 공간 채우기)
            const Expanded(
              child: TabBarView(
                // 여기서 바뀜
                children: [
                  _ReservationApprovalList(), // 첫 번째 탭: 예약 관리
                  _RepairRequestList(), // 두 번째 탭: 수리 관리
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 탭 1. 예약 승인 관리 리스트 위젯
// ---------------------------------------------------------
class _ReservationApprovalList extends StatelessWidget {
  const _ReservationApprovalList();

  // [기능] 예약 상태 변경 함수 (승인 or 거절)
  Future<void> _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(docId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 'pending'(대기중)인 예약만 가져오기
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true) // 최신순 정렬
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("승인 대기 중인 예약이 없습니다."));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id; // 문서 ID (업데이트용)

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 예약 정보 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data['spaceName'] ?? '공간명 없음',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Chip(
                            label: Text(data['userName'] ?? '사용자'),
                            backgroundColor: Colors.blue[50]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("📅 날짜: ${data['date']}"),
                    Text("⏰ 시간: ${data['timeSlot']}"),

                    const Divider(height: 24),

                    // 승인 / 거절 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              _updateStatus(docId, 'cancelled'), // 거절 -> 취소 처리
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text("거절"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () =>
                              _updateStatus(docId, 'confirmed'), // 승인 -> 확정 처리
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white),
                          child: const Text("승인"),
                        ),
                      ],
                    )
                  ],
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
// 탭 2. 수리 요청 관리 리스트 위젯
// ---------------------------------------------------------
class _RepairRequestList extends StatelessWidget {
  const _RepairRequestList();

  // [기능] 수리 완료 처리 함수
  Future<void> _completeRepair(String docId) async {
    await FirebaseFirestore.instance
        .collection('repairRequests')
        .doc(docId)
        .update({'status': 'completed'}); // 상태를 완료로 변경
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 'pending'(처리전)인 수리 요청만 가져오기
      stream: FirebaseFirestore.instance
          .collection('repairRequests')
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("접수된 수리 요청이 없습니다."));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text("🔧 ${data['spaceName']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("신고자: ${data['userName']}"),
                    const SizedBox(height: 4),
                    Text(data['description'] ?? '',
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _completeRepair(docId),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white),
                  child: const Text("처리 완료"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
