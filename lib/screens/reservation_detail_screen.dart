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
  final TextEditingController _reviewController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  int _currentRating = 5;
  bool _isLoading = false; // final 제거 (상태 변경을 위해)
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

  // 🔹 기존에 비어있던 함수들을 완전히 구현했습니다.

  // 1. 이미 작성된 리뷰가 있는지 확인하는 함수
  Future<void> _checkExistingReview() async {
    try {
      final query = await _firestore
          .collection('reviews')
          .where('reservationDocId', isEqualTo: widget.reservation['docId'])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        if (mounted) {
          setState(() {
            _hasReview = true;
            _reviewDocId = query.docs.first.id;
            _currentRating = data['rating'] ?? 5;
            _reviewController.text = data['content'] ?? '';
          });
        }
      }
    } catch (e) {
      print("리뷰 확인 중 오류 발생: $e");
    }
  }

  // 2. 리뷰를 등록하거나 수정하는 함수
  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 내용을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reviewData = {
        'reservationDocId': widget.reservation['docId'],
        'userId': currentUser?.uid,
        'userName': currentUser?.displayName ?? '익명',
        'rating': _currentRating,
        'content': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'spaceName': widget.reservation['spaceName'], // 나중에 리뷰 목록에서 보여주기 위함
      };

      if (_hasReview && _reviewDocId != null) {
        // 수정 (Update)
        await _firestore
            .collection('reviews')
            .doc(_reviewDocId)
            .update(reviewData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리뷰가 수정되었습니다.')),
          );
        }
      } else {
        // 신규 작성 (Create)
        final docRef = await _firestore.collection('reviews').add(reviewData);
        if (mounted) {
          setState(() {
            _hasReview = true;
            _reviewDocId = docRef.id;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리뷰가 등록되었습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 3. 리뷰를 삭제하는 함수 (필요 시 사용)
  Future<void> _deleteReview() async {
    if (!_hasReview || _reviewDocId == null) return;

    try {
      await _firestore.collection('reviews').doc(_reviewDocId).delete();
      if (mounted) {
        setState(() {
          _hasReview = false;
          _reviewDocId = null;
          _reviewController.clear();
          _currentRating = 5;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 삭제되었습니다.')),
        );
      }
    } catch (e) {
      print("리뷰 삭제 중 오류: $e");
    }
  }

  // 4. 상태에 따른 텍스트 반환 (취소 상태 포함)
  String getStatusText(String? status) {
    if (status == 'confirmed') return '예약 확정';
    if (status == 'completed') return '사용 완료';
    if (status == 'canceled' || status == 'cancelled') return '예약 취소'; // 오타 대응
    if (status == 'pending') return '예약 대기';
    return '상태 미정';
  }

  // 5. 상태에 따른 색상 반환
  Color getStatusColor(String? status) {
    if (status == 'confirmed') return Colors.blue;
    if (status == 'completed') return Colors.grey;
    if (status == 'canceled' || status == 'cancelled') return Colors.red;
    return Colors.orange; // pending
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
              backgroundColor: Color(0xFF333333),
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Scaffold(
              backgroundColor: Color(0xFF333333),
              body: Center(
                  child:
                      Text("데이터 없음", style: TextStyle(color: Colors.white))));
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
                              : currentStatus == 'completed'
                                  ? Icons.task_alt
                                  : currentStatus == 'canceled'
                                      ? Icons.cancel
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

                      // 360도 뷰 버튼
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
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitReview,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _hasReview ? "리뷰 수정" : "리뷰 저장",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
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
