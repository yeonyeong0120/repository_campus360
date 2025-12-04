// lib/screens/reservation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Provider는 이제 굳이 안 써도 되지만, 혹시 모르니 남겨둡니다.
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

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

  final Color _backgroundColor = const Color(0xFFF0F5FA);

  int _currentRating = 5;
  bool _isLoading = false;
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

  // 1. 이미 작성된 리뷰 확인
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
      debugPrint("리뷰 확인 중 오류 발생: $e");
    }
  }

  // 2. 리뷰 등록/수정 (🔥 무조건 DB에서 이름 가져오도록 수정됨!)
  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('리뷰 내용을 입력해주세요.'), duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 💡 [핵심 수정] Provider고 뭐고 다 떠나서, 무조건 DB에서 직접 이름 조회!
      String finalName = '익명'; // 기본값

      if (currentUser != null) {
        // users 컬렉션에서 내 UID로 된 문서를 직접 가져옵니다.
        final userDoc =
            await _firestore.collection('users').doc(currentUser!.uid).get();

        if (userDoc.exists) {
          // 문서가 있으면 그 안의 'name' 필드를 가져옵니다.
          finalName = userDoc.data()?['name'] ?? '익명';
          debugPrint("DB에서 가져온 이름: $finalName"); // 콘솔에서 확인 가능
        } else {
          debugPrint("오류: DB에 유저 정보가 없습니다. (UID: ${currentUser!.uid})");
        }
      }

      final reviewData = {
        'reservationDocId': widget.reservation['docId'],
        'userId': currentUser?.uid,
        'userName': finalName, // 💡 방금 DB에서 찾아낸 진짜 이름을 넣습니다.
        'rating': _currentRating,
        'content': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'spaceName': widget.reservation['spaceName'],
      };

      if (_hasReview && _reviewDocId != null) {
        // 수정 (Update)
        await _firestore
            .collection('reviews')
            .doc(_reviewDocId)
            .update(reviewData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('리뷰가 수정되었습니다.'), duration: Duration(seconds: 1)),
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
            const SnackBar(
                content: Text('리뷰가 등록되었습니다.'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              duration: const Duration(seconds: 1)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 3. 리뷰 삭제
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
          const SnackBar(
              content: Text('리뷰가 삭제되었습니다.'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint("리뷰 삭제 중 오류: $e");
    }
  }

  // 예약 취소 로직
  Future<void> _cancelReservation() async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservation['docId'])
          .update({'status': 'cancelled'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("예약이 취소되었습니다."), duration: Duration(seconds: 1)),
        );
        Navigator.pop(context); // 취소 후 리스트로 복귀
      }
    } catch (e) {
      debugPrint("예약 취소 중 오류 발생: $e");
    }
  }

  // Helper 함수들
  String getStatusText(String? status) {
    if (status == 'confirmed') return '예약 확정';
    if (status == 'completed') return '사용 완료';
    if (status == 'canceled' || status == 'cancelled') return '예약 취소';
    if (status == 'pending') return '예약 대기';
    return '상태 미정';
  }

  Color getStatusColor(String? status) {
    if (status == 'confirmed') return Colors.blue;
    if (status == 'completed') return Colors.green;
    if (status == 'canceled' || status == 'cancelled') return Colors.grey;
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
          return Scaffold(
              backgroundColor: _backgroundColor,
              body: const Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Scaffold(body: Center(child: Text("데이터 없음")));
        }

        final currentStatus = data['status'] ?? 'pending';

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            title: const Text('상세 정보',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'manru',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            centerTitle: true,
            backgroundColor: _backgroundColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 🎫 상세 정보 티켓 디자인
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: getStatusColor(currentStatus)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Icon(
                          currentStatus == 'confirmed'
                              ? Icons.check_circle
                              : currentStatus == 'completed'
                                  ? Icons.task_alt
                                  : currentStatus == 'canceled' ||
                                          currentStatus == 'cancelled'
                                      ? Icons.cancel
                                      : Icons.schedule,
                          size: 48,
                          color: getStatusColor(currentStatus),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        data['spaceName'] ?? 'Unknown Space',
                        style: const TextStyle(
                            fontSize: 24,
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
                            fontSize: 18),
                      ),
                      const SizedBox(height: 40),
                      _buildDetailRow("날짜", data['date'] ?? '-'),
                      _buildDetailRow("시간", data['timeSlot'] ?? '-'),
                      _buildDetailRow("예약자", data['userName'] ?? 'User'),
                      _buildDetailRow("티켓 번호",
                          data['docId']?.substring(0, 8).toUpperCase() ?? '-'),
                      const SizedBox(height: 40),
                      if (currentStatus == 'pending' ||
                          currentStatus == 'confirmed')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _cancelReservation,
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: const Text("예약 취소"),
                          ),
                        ),
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

                // 📝 하단 리뷰 섹션
                if (currentStatus == 'completed') ...[
                  const Text("리뷰 작성",
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]),
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                List.generate(5, (index) => _buildStar(index))),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _reviewController,
                          style: const TextStyle(color: Colors.black),
                          maxLines: 3,
                          readOnly: _hasReview,
                          decoration: InputDecoration(
                            hintText: _hasReview
                                ? "작성한 리뷰가 없습니다."
                                : "상세한 이용 후기를 남겨주세요.",
                            hintStyle: const TextStyle(color: Colors.grey),
                            fillColor: const Color(0xFFF5F5F5),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.blue)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_hasReview)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _deleteReview,
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red[300],
                                      side: BorderSide(color: Colors.red[300]!),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16)),
                                  child: const Text("삭제"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitReview,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16)),
                                  child: const Text("수정",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        else
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
                                  : const Text(
                                      "리뷰 저장",
                                      style: TextStyle(
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
