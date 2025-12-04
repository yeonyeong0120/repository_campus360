import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 접근
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          // 🔥 [수정] 뒤로가기 버튼 자동 생성 끄기
          automaticallyImplyLeading: false,

          title: const Text("관리자 페이지",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'manru')),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                context.read<UserProvider>().clearUser();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorWeight: 3,
            labelStyle:
                TextStyle(fontWeight: FontWeight.bold, fontFamily: 'manru'),
            tabs: [
              Tab(text: "예약 승인 관리"),
              Tab(text: "예약 신청 목록"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReservationApprovalList(),
            _ReservationHistoryList(),
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

  // [기능] 예약 상태 변경
  Future<void> _updateStatus(String docId, String newStatus,
      {String? reason}) async {
    final Map<String, dynamic> updateData = {'status': newStatus};

    // 거절 사유가 있으면 저장
    if (reason != null && reason.trim().isNotEmpty) {
      updateData['rejectionReason'] = reason.trim();
    }

    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(docId)
        .update(updateData);
  }

  // [기능] 상세 정보 보기 다이얼로그
  void _showDetailInfo(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("예약 상세 정보",
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontFamily: 'manru')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow("예약 공간", data['spaceName']),
                _buildDetailRow("예약자명", data['userName']),
                _buildDetailRow("연락처", data['phoneNumber'] ?? '정보 없음'),
                _buildDetailRow("소속/학번", data['department'] ?? '정보 없음'),
                const Divider(height: 20),
                _buildDetailRow("날짜", data['date']),
                _buildDetailRow("시간", data['timeSlot']),
                _buildDetailRow("인원", "${data['participants'] ?? '-'}명"),
                const Divider(height: 20),
                const Text("신청 사유",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(data['purpose'] ?? '내용 없음',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value ?? '-',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // [기능] 거절 사유 입력 다이얼로그 (선택 사항)
  void _showRejectionDialog(BuildContext context, String docId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("예약 거절",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              hintText: "거절 사유 (선택 사항)",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _updateStatus(docId, 'rejected', reason: reasonController.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("거절 확정"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("승인 대기 중인 예약이 없습니다.",
                  style: TextStyle(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return GestureDetector(
              onTap: () => _showDetailInfo(context, data),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                        Expanded(
                          child: Text(data['spaceName'] ?? '공간명 없음',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  fontFamily: 'manru'),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text("승인 대기",
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        Icons.calendar_today_outlined, "${data['date']}"),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.access_time, "${data['timeSlot']}"),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.person_outline,
                        "${data['userName']} (클릭하여 상세 보기)"),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _showRejectionDialog(context, docId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("거절"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(docId, 'confirmed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text("승인"),
                          ),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14)),
      ],
    );
  }
}

// ---------------------------------------------------------
// 탭 2. 예약 신청 목록 (전체 히스토리)
// ---------------------------------------------------------
class _ReservationHistoryList extends StatelessWidget {
  const _ReservationHistoryList();

  Color _getStatusColor(String status) {
    if (status == 'confirmed' || status == 'completed') {
      return Colors.blue;
    } else if (status == 'cancelled') {
      return Colors.grey;
    } else if (status == 'rejected') {
      return Colors.red;
    }
    return Colors.black;
  }

  String _getStatusText(String status) {
    if (status == 'confirmed' || status == 'completed') {
      return "승인완료";
    } else if (status == 'cancelled') {
      return "본인취소";
    } else if (status == 'rejected') {
      return "거절함";
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('status',
              whereIn: ['confirmed', 'rejected', 'cancelled', 'completed'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("처리된 예약 내역이 없습니다.",
                  style: TextStyle(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'unknown';

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                      Expanded(
                        child: Text(data['spaceName'] ?? '공간명 없음',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'manru'),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${data['userName']}",
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_filled,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${data['date']} | ${data['timeSlot']}",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ),

                  // 🔥 [수정] 거절 사유 디자인 (진회색)
                  if (status == 'rejected' &&
                      data['rejectionReason'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100], // 배경 연한 회색
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "거절 사유: ${data['rejectionReason']}",
                        style: TextStyle(
                            color: Colors.grey[800], fontSize: 13), // 글자 진한 회색
                      ),
                    ),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }
}
