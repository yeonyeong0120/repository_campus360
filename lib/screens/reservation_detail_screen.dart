// lib/screens/reservation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:repository_campus360/widgets/common_image.dart';
import 'webview_screen.dart';

class ReservationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
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

    Color getStatusColor(String? status) {
      switch (status) {
        case 'confirmed':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        case 'cancelled':
          return Colors.red;
        default:
          return Colors.orange;
      }
    }

    String getStatusText(String? status) {
      switch (status) {
        case 'confirmed':
          return '확정';
        case 'pending':
          return '승인 대기중';
        case 'cancelled':
          return '취소됨';
        default:
          return '승인 대기중';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 상세 정보'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('spaces')
                  .where('name', isEqualTo: reservation['spaceName'])
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                String imageUrl = '';

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final spaceData =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  imageUrl =
                      spaceData['image'] ?? spaceData['mainImageUrl'] ?? '';
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonImage(
                        imageUrl, // 위에서 변수로 받은 주소
                        width: double.infinity,
                        height: 180,
                        borderRadius: 12, // 전체 둥글게 해도 디자인상 괜찮습니다.
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '예약 공간',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reservation['spaceName'] ?? '컴퓨터실용',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],  // childern
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '핵심 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
              title: '예약 일시',
              content: reservation['startTime'] != null
                  ? '${formatDateTime(reservation['startTime'] as Timestamp?)} ~ ${formatTime(reservation['endTime'] as Timestamp?)}'
                  : reservation['date'] != null &&
                          reservation['timeSlot'] != null
                      ? '${reservation['date']} ${reservation['timeSlot']}'
                      : '정보 없음',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.info_outline,
              iconColor: getStatusColor(reservation['status']),
              title: '예약 상태',
              content: getStatusText(reservation['status']),
              contentColor: getStatusColor(reservation['status']),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.person,
              iconColor: Colors.orange,
              title: '예약자 이름',
              content: reservation['userName'] ?? '김지안님',
            ),
            const SizedBox(height: 24),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('spaces')
                  .where('name', isEqualTo: reservation['spaceName'])
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                String view360Url = '';
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final spaceData =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  view360Url = spaceData['view360Url'] ?? '';
                }

                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: view360Url.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WebViewScreen(
                                  view360Url: view360Url,
                                ),
                              ),
                            );
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('이 공간은 360도 뷰를 제공하지 않습니다')),
                            );
                          },
                    icon: const Icon(Icons.threesixty),
                    label: const Text('360도 뷰로 미리보기'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            if (reservation['status'] != 'cancelled')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showCancelDialog(context, reservation);
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('예약 취소하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    Color? contentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: contentColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
      BuildContext context, Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('예약 취소'),
          ],
        ),
        content: const Text('정말로 이 예약을 취소하시겠습니까?\n취소된 예약은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('돌아가기'),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
  }
}
