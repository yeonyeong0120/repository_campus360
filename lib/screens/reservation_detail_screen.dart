import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  // 기존 로직(리뷰 작성/삭제 등)은 그대로 유지합니다.
  final TextEditingController _reviewController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  int _currentRating = 5;
  final bool _isLoading = false;
  bool _hasReview = false;
  String? _reviewDocId;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _checkExistingReview();
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // ... (기존 _checkExistingReview, _submitReview, _deleteReview 함수들 생략 없이 그대로 사용하세요)
  // 편의상 이 답변에서는 UI 변경에 집중하기 위해 로직 함수는 위 코드 블록과 동일하다고 가정합니다.
  // (실제 적용 시에는 기존 코드의 로직 함수들을 여기에 그대로 붙여넣어 주세요)

  // 🔽 아래 함수들은 복사해서 붙여넣으세요 (로직 보존)
  Future<void> _checkExistingReview() async {
    try {
      final query = await _firestore
          .collection('reviews')
          .where('reservationDocId', isEqualTo: widget.reservation['docId'])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        setState(() {
          _hasReview = true;
          _reviewDocId = query.docs.first.id;
          _currentRating = data['rating'] ?? 5;
          _reviewController.text = data['content'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('리뷰 확인 에러: $e');
    }
  }

  Future<void> _submitReview() async {
    // ... (기존 로직 동일)
    // 실제 적용 시 위쪽 기존 코드의 _submitReview 내용을 그대로 사용하십시오.
  }

  Future<void> _deleteReview() async {
    // 1. 문서 ID가 없으면 삭제 불가 (방어 코드)
    if (_reviewDocId == null) return;

    setState(() {
      // _isLoading = true; // (선택사항) 로딩 시작
    });

    try {
      // 2. 파이어베이스에서 해당 리뷰 삭제 (여기서 _reviewDocId가 사용됨! ✅)
      await _firestore.collection('reviews').doc(_reviewDocId).delete();

      // 3. 화면 상태 초기화 (리뷰 안 쓴 상태로 되돌리기)
      setState(() {
        _hasReview = false;
        _reviewDocId = null;
        _reviewController.clear();
        _currentRating = 5;
      });

      // 4. 안내 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("리뷰가 삭제되었습니다.")),
        );
      }
    } catch (e) {
      debugPrint("리뷰 삭제 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("오류가 발생했습니다.")),
        );
      }
    } finally {
      /* setState(() {
        _isLoading = false; // 로딩 끝
      }); 
      */
    }
  }

  // Helper 함수들
  String getStatusText(String? status) {
    // ... (기존 로직 동일)
    if (status == 'confirmed') return '예약 확정';
    if (status == 'completed') return '사용 완료';
    return '상태 미정';
  }

  Color getStatusColor(String? status) {
    if (status == 'confirmed') return Colors.blue;
    if (status == 'completed') return Colors.grey;
    return Colors.orange;
  }

  Widget _buildStar(int index) {
    return GestureDetector(
      onTap: () => setState(() => _currentRating = index + 1),
      child: Icon(
        index < _currentRating ? Icons.star_rounded : Icons.star_border_rounded,
        color: const Color(0xFFFFC107),
        size: 40.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservation['docId'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Scaffold(body: Center(child: Text("데이터 없음")));
        }

        final currentStatus = data['status'] ?? 'pending';

        return Scaffold(
          backgroundColor: const Color(0xFF333333), // 🌟 배경을 어둡게 하여 티켓에 집중
          appBar: AppBar(
            title: const Text('TICKET DETAIL',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'manru',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 🎫 상세 정보 티켓 디자인 (영수증처럼 길게)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 상단 아이콘
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color:
                                getStatusColor(currentStatus).withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Icon(
                          currentStatus == 'confirmed'
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 40,
                          color: getStatusColor(currentStatus),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data['spaceName'] ?? 'Unknown Space',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'manru'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getStatusText(currentStatus),
                        style: TextStyle(
                            color: getStatusColor(currentStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 32),

                      // 정보 Row들
                      _buildDetailRow("DATE", data['date'] ?? '-'),
                      _buildDetailRow("TIME", data['timeSlot'] ?? '-'),
                      _buildDetailRow("GUEST", data['userName'] ?? 'User'),
                      _buildDetailRow("BOOKING ID",
                          data['docId']?.substring(0, 8).toUpperCase() ?? '-'),

                      const SizedBox(height: 32),
                      // 점선
                      Row(
                          children: List.generate(
                              30,
                              (i) => Expanded(
                                  child: Container(
                                      color: i % 2 == 0
                                          ? Colors.transparent
                                          : Colors.grey[300],
                                      height: 2)))),
                      const SizedBox(height: 32),

                      // 취소 버튼 (확정/대기 상태일 때만)
                      if (currentStatus == 'pending' ||
                          currentStatus == 'confirmed')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text("예약 취소"),
                          ),
                        ),

                      // 360도 뷰 버튼 (기존 유지)
                      if (data['view360Url'] != null &&
                          data['view360Url'] != '') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.threesixty),
                                label: const Text("360도 뷰 보기")))
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 📝 하단 리뷰 섹션 (완료된 경우에만 표시)
                if (currentStatus == 'completed') ...[
                  const Text("YOUR REVIEW",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24)),
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때
                      : Column(
                      children: [
                        // 1. 별점 표시
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) => _buildStar(index))
                        ),
                        const SizedBox(height: 16),

                        // 2. 리뷰 작성 칸 vs 이미 쓴 리뷰 내용 ( _hasReview 변수 사용! )
                        TextField(
                          controller: _reviewController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          // 리뷰가 이미 있으면 수정 못하게 막기 (읽기 전용)
                          readOnly: _hasReview, 
                          decoration: InputDecoration(
                            hintText: _hasReview ? "작성한 리뷰가 없습니다." : "상세한 이용 후기를 남겨주세요.",
                            hintStyle: const TextStyle(color: Colors.white54),
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. 버튼 (저장 vs 삭제) - ( _deleteReview 함수 사용! )
                        SizedBox(
                          width: double.infinity,
                          child: _hasReview
                              ? OutlinedButton( // 이미 리뷰가 있으면 '삭제' 버튼 표시
                                  onPressed: _deleteReview,
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red[300],
                                      side: BorderSide(color: Colors.red[300]!),
                                      padding: const EdgeInsets.symmetric(vertical: 16)),
                                  child: const Text("내 리뷰 삭제하기"),
                                )
                              : ElevatedButton( // 리뷰가 없으면 '저장' 버튼 표시
                                  onPressed: _submitReview,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 16)),
                                  child: const Text("리뷰 저장",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                        )
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontFamily: 'manru',
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
