// lib/screens/reservation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// import 'package:repository_campus360/widgets/common_image.dart'; // 📌 기존 이미지 위젯이 있다면 사용, 없다면 아래 Image.network 사용
import 'webview_screen.dart';

class ReservationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  // ----------------------------------------------------------------------
  // 🛠️ [Helper Functions] 날짜/시간/상태 변환 함수들 (주석 원본 유지)
  // ----------------------------------------------------------------------
  String formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return '정보 없음';
    final dateTime = timestamp.toDate();
    return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dateTime);
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '정보 없음';
    final dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime);
  }

  String getStatusText(String? status) {
    switch (status) {
      case 'confirmed':
        return '예약 확정';
      case 'pending':
        return '승인 대기중';
      case 'cancelled':
        return '취소됨';
      default:
        return '상태 미정';
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF4CAF50); // 녹색
      case 'pending':
        return const Color(0xFFFF9800); // 주황색
      case 'cancelled':
        return const Color(0xFFE53935); // 빨간색
      default:
        return Colors.grey;
    }
  }

  // ----------------------------------------------------------------------
  // 🎨 [UI Building]
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // 🎨 배경색: 부드러운 연회색
      appBar: AppBar(
        title: const Text(
          '예약 상세 정보',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'manru'),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FA), // 배경색과 맞춤
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // 📸 [1. 공간 이미지 & 이름 카드]
            // -------------------------------------------------------
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('spaces')
                  .where('name', isEqualTo: reservation['spaceName'])
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                String imageUrl = '';
                String view360Url = '';

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final spaceData =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  // 📌 [로직 유지] 이미지 URL과 360 URL 업데이트
                  imageUrl =
                      spaceData['image'] ?? spaceData['mainImageUrl'] ?? '';
                  view360Url = spaceData['view360Url'] ?? '';
                }

                return Column(
                  children: [
                    // 메인 카드 (세련된 디자인 적용)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24), // 둥글게
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 이미지 영역
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[100],
                                        child: const Center(
                                            child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                                size: 40)),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 200,
                                    color: Colors.blue[50],
                                    child: Center(
                                      child: Icon(Icons.meeting_room_rounded,
                                          size: 60, color: Colors.blue[200]),
                                    ),
                                  ),
                          ),

                          // 텍스트 정보 영역
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reservation['spaceName'] ?? '공간명 없음',
                                        style: const TextStyle(
                                          // 🌟 [수정] 폰트 크기 24pt에서 20pt로 축소
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'manru',
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                    ),
                                    // 상태 뱃지
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(
                                                reservation['status'])
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        getStatusText(reservation['status']),
                                        style: TextStyle(
                                          color: getStatusColor(
                                              reservation['status']),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          fontFamily: 'manru',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // 🌟 [수정] 아래 한국폴리텍대학 인천캠퍼스 텍스트 제거됨
                                // const SizedBox(height: 8),
                                // Row(...)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // -------------------------------------------------------
                    // 📝 [2. 상세 정보 리스트]
                    // -------------------------------------------------------
                    const Text(
                      '예약 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'manru',
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 예약 일시 (Timestamp 및 date/timeSlot fallback 처리)
                          _buildInfoRow(
                            icon: Icons.calendar_today_rounded,
                            iconColor: Colors.blue,
                            title: '예약 일시',
                            content: reservation['startTime'] != null
                                ? '${formatDateTime(reservation['startTime'] as Timestamp?)} ~ ${formatTime(reservation['endTime'] as Timestamp?)}'
                                : reservation['date'] != null &&
                                        reservation['timeSlot'] != null
                                    ? '${reservation['date']} ${reservation['timeSlot']}'
                                    : '정보 없음',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                          ),
                          // 예약 상태
                          _buildInfoRow(
                            icon: Icons.info_outline_rounded,
                            iconColor: getStatusColor(reservation['status']),
                            title: '예약 상태',
                            content: getStatusText(reservation['status']),
                            contentColor: getStatusColor(reservation['status']),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                          ),
                          // 예약자 이름
                          _buildInfoRow(
                            icon: Icons.person_rounded,
                            iconColor: Colors.orange,
                            title: '예약자',
                            content: reservation['userName'] ?? '본인',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // -------------------------------------------------------
                    // 🔘 [3. 액션 버튼들 (360뷰 & 취소)]
                    // -------------------------------------------------------
                    if (view360Url.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WebViewScreen(view360Url: view360Url),
                              ),
                            );
                          },
                          icon: const Icon(Icons.threesixty, size: 22),
                          label: const Text('360도 뷰로 공간 미리보기'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2196F3),
                            side: const BorderSide(
                                color: Color(0xFF2196F3), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'manru'),
                          ),
                        ),
                      ),

                    if (view360Url.isNotEmpty) const SizedBox(height: 12),

                    if (reservation['status'] != 'cancelled')
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showCancelDialog(context, reservation);
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          label: const Text('예약 취소하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFFFEBEE), // 연한 빨강 배경
                            foregroundColor:
                                const Color(0xFFD32F2F), // 진한 빨강 글씨
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'manru'),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 📌 정보 행 위젯 (디자인 개선)
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    Color? contentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'manru',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: contentColor ?? const Color(0xFF333333),
                  fontFamily: 'manru',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 📌 예약 취소 다이얼로그 (기존 로직 100% 유지 + 디자인 개선)
  void _showCancelDialog(
      BuildContext context, Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text('예약 취소',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'manru')),
          ],
        ),
        content: const Text(
          '정말로 이 예약을 취소하시겠습니까?\n취소된 예약은 복구할 수 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontFamily: 'manru'),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text("돌아가기",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'manru')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // 👇 문서 ID가 있으면 직접 사용!
                final docId = reservation['docId'] as String?;

                if (docId != null) {
                  // 👇 문서 ID로 직접 접근!
                  final docRef = FirebaseFirestore.instance
                      .collection('reservations')
                      .doc(docId);

                  final docSnapshot = await docRef.get();

                  if (!docSnapshot.exists) {
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('예약을 찾을 수 없습니다'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  final data = docSnapshot.data() as Map<String, dynamic>;

                  if (data['status'] == 'cancelled') {
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('이미 취소된 예약입니다'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Navigator.pop(context);
                    }
                    return;
                  }

                  // 👇 상태 업데이트!
                  await docRef.update({
                    'status': 'cancelled',
                    'cancelledAt': FieldValue.serverTimestamp(),
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('예약이 취소되었습니다'),
                        backgroundColor: Colors.grey,
                      ),
                    );

                    Navigator.pop(context);
                  }
                  return;
                }

                // 👇 문서 ID가 없으면 기존 방식 (fallback)
                final reservationsSnapshot = await FirebaseFirestore.instance
                    .collection('reservations')
                    .where('userId', isEqualTo: reservation['userId'])
                    .where('spaceName', isEqualTo: reservation['spaceName'])
                    .get();

                if (reservationsSnapshot.docs.isEmpty) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('예약을 찾을 수 없습니다'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final docToCancel = reservationsSnapshot.docs.first;

                if (docToCancel.data()['status'] == 'cancelled') {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('이미 취소된 예약입니다'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    Navigator.pop(context);
                  }
                  return;
                }

                await docToCancel.reference.update({
                  'status': 'cancelled',
                  'cancelledAt': FieldValue.serverTimestamp(),
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('예약이 취소되었습니다'),
                      backgroundColor: Colors.grey,
                    ),
                  );

                  Navigator.pop(context);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('예약 취소 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('취소하기',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'manru')),
          ),
        ],
      ),
    );
  }
}
