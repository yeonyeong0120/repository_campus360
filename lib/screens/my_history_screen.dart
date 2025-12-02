// lib/screens/my_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'package:repository_campus360/screens/reservation_detail_screen.dart';

class MyHistoryScreen extends StatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  State<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends State<MyHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "내 활동 내역",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              context.read<UserProvider>().clearUser();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "예약 내역"),
            Tab(text: "수리 요청"),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text("로그인이 필요합니다."))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReservationList(user.uid),
                _buildRepairList(user.uid),
              ],
            ),
    );
  }

  // ------------------------------------------------------------------------
  // 📋 [1] 예약 내역 (클릭 시 상세 화면 이동 기능 추가)
  // ------------------------------------------------------------------------
  Widget _buildReservationList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("오류: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
              "예약 내역이 없습니다.", Icons.calendar_today_outlined);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';

            // 🌟 [핵심] 상세 화면으로 넘길 때 docId를 포함해야 취소가 가능함
            final reservationData = Map<String, dynamic>.from(data);
            reservationData['docId'] = doc.id;

            // 🌟 GestureDetector로 감싸서 클릭 가능하게 변경
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReservationDetailScreen(
                      reservation: reservationData,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['spaceName'] ?? '공간 정보 없음',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${data['date']} | ${data['timeSlot']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    // 화살표 아이콘 추가 (누를 수 있다는 힌트)
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "상세보기 >",
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
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

  // ------------------------------------------------------------------------
  // 🛠️ [2] 수리 요청 내역
  // ------------------------------------------------------------------------
  Widget _buildRepairList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('repairRequests')
          .where('userId', isEqualTo: uid)
          .orderBy('requestedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("오류: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("수리 요청 내역이 없습니다.", Icons.build_outlined);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final title = data['issue'] ?? data['title'] ?? '수리 요청';
            final status = data['status'] ?? '접수됨';

            final date = data['requestedAt'] != null
                ? DateFormat('yyyy-MM-dd')
                    .format((data['requestedAt'] as Timestamp).toDate())
                : '-';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.build, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "접수일: $date",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'confirmed':
        color = Colors.green;
        text = "확정됨";
        break;
      case 'cancelled':
        color = Colors.red;
        text = "취소됨";
        break;
      default:
        color = Colors.orange;
        text = "대기중";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
