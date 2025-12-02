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

  // 🌟 [핵심 로직] 시간이 지난 'confirmed' 예약을 'completed'로 자동 업데이트
  Future<void> _checkAndCompleteReservations(
      List<QueryDocumentSnapshot> docs) async {
    final now = DateTime.now();
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      // endTime 필드가 존재하고 상태가 'confirmed'(확정)인 경우
      if (data['endTime'] != null && data['status'] == 'confirmed') {
        final DateTime endTime = (data['endTime'] as Timestamp).toDate();
        if (now.isAfter(endTime)) {
          // 시간이 지났으면 'completed'로 상태 변경
          await doc.reference.update({'status': 'completed'});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

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
              // 🛠 [수정] Provider 로직이 없어서 오류가 날 수 있지만, user clear 로직이 있다고 가정
              // context.read<UserProvider>().clearUser();
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
            Tab(text: "내가 쓴 리뷰"), // 🌟 [수정] 수리요청 -> 내가 쓴 리뷰
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationList(user.uid),
          _buildMyReviewList(user.uid), // 🌟 새로운 리뷰 리스트 함수
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // 📋 [1] 예약 내역 (상세 화면 연결 유지)
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

        // 🌟 [핵심] 데이터 로드 시 상태 체크 실행 (DB 상태 업데이트)
        _checkAndCompleteReservations(snapshot.data!.docs);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';

            final reservationData = Map<String, dynamic>.from(data);
            reservationData['docId'] = doc.id; // 문서 ID 전달

            // 🌟 이용 완료 상태 텍스트
            String statusText = _getStatusTextForDisplay(status);
            Color statusColor = _getStatusColorForDisplay(status);

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
                        _buildStatusBadge(statusColor, statusText), // 뱃지 위젯 변경
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${data['date']} | ${data['timeSlot']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text("상세보기 >",
                          style: TextStyle(fontSize: 12, color: Colors.blue)),
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
  // 📋 [2] 내가 쓴 리뷰 리스트
  // ------------------------------------------------------------------------
  Widget _buildMyReviewList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("작성한 리뷰가 없습니다.", Icons.rate_review_outlined);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final date = data['createdAt'] != null
                ? DateFormat('yyyy.MM.dd')
                    .format((data['createdAt'] as Timestamp).toDate())
                : '-';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['spaceName'] ?? '공간명',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(date,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: starIndex < (data['rating'] ?? 0)
                          ? const Color(0xFF4282CB)
                          : Colors.grey[300],
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(data['content'] ?? '',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  // Helper 함수들
  String _getStatusTextForDisplay(String status) {
    switch (status) {
      case 'confirmed':
        return "확정됨";
      case 'pending':
        return "대기중";
      case 'cancelled':
        return "취소됨";
      case 'completed':
        return "이용 완료";
      default:
        return "상태 미정";
    }
  }

  Color _getStatusColorForDisplay(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  // 🌟 [수정 완료] withOpacity -> withValues(alpha: ...)
  Widget _buildStatusBadge(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
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
}
