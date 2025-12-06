import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 접근
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';

// ---------------------------------------------------------
// 🔥 유저 상세 정보 조회 위젯 (학과, 학번 등)
// ---------------------------------------------------------
class _UserLookupWidget extends StatelessWidget {
  final String userId;
  final String spaceName;

  const _UserLookupWidget({required this.userId, required this.spaceName});

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // reservation 문서의 userId를 이용해 users 컬렉션에서 정보를 가져옴
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("유저 정보 로딩 중...",
              style: TextStyle(color: Colors.grey));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          // 유저 정보가 DB users 컬렉션에 누락된 경우
          return const Text("유저 정보(학과/학번)를 찾을 수 없습니다.",
              style: TextStyle(color: Colors.red));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("예약 공간", spaceName),
            _buildDetailRow("예약자명", userData['name'] ?? '정보 없음'),
            _buildDetailRow("학번", userData['studentId'] ?? '정보 없음'),
            _buildDetailRow("학과", userData['department'] ?? '정보 없음'),
            _buildDetailRow("권한", userData['role'] ?? '정보 없음'),
          ],
        );
      },
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

    if (reason != null && reason.trim().isNotEmpty) {
      updateData['rejectionReason'] = reason.trim();
    }

    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(docId)
        .update(updateData);
  }

  // [기능] 상세 정보 보기 다이얼로그
  void _showDetailInfo(
      BuildContext context, Map<String, dynamic> data, String docId) {
    // 🔥 예약 문서에서 직접 가져오는 데이터
    String timeDisplay = data['timeSlot'] ?? '시간 정보 없음';
    String userId = data['userId'] ?? '';
    String purpose = data['purpose'] ?? '내용 없음';
    String contact = data['contact'] ?? '정보 없음';
    int headCount = data['headCount'] ?? 1;

    // 🌟 [추가] 기자재 리스트 가져오기
    // Firestore에는 List<dynamic> 형태로 저장되므로 변환 필요
    List<dynamic> equipmentListRaw = data['equipment'] ?? [];
    String equipmentText = equipmentListRaw.isEmpty
        ? '선택 안함'
        : equipmentListRaw.join(', '); // "빔 프로젝터, 마이크" 형태로 변환

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
                // 1. 유저 정보 (Async Lookup으로 학번/학과 가져오기)
                if (userId.isNotEmpty)
                  _UserLookupWidget(
                      userId: userId, spaceName: data['spaceName']),

                const Divider(height: 20),

                // 2. 예약 정보
                _buildDetailRow("날짜", data['date']),
                _buildDetailRow("시간", timeDisplay),
                _buildDetailRow("인원", "$headCount명"),
                _buildDetailRow("연락처", contact),

                // 🌟 [추가] 기자재 정보 표시
                _buildDetailRow("필요 장비", equipmentText),

                const Divider(height: 20),

                // 3. 신청 사유
                const Text("신청 사유",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(purpose, style: const TextStyle(fontSize: 14)),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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
              onTap: () =>
                  _showDetailInfo(context, data, docId), // 박스 클릭 시 상세 정보 팝업
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
                    _buildInfoRow(Icons.access_time, data['timeSlot']),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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

            String timeDisplay = data['timeSlot'] ?? '시간 정보 없음';

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
                      Text("${data['date']} | $timeDisplay",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ),

                  // 거절 사유 디자인
                  if (status == 'rejected' &&
                      data['rejectionReason'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "거절 사유: ${data['rejectionReason']}",
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
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

// ---------------------------------------------------------
// 메인 관리자 스크린
// ---------------------------------------------------------
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
