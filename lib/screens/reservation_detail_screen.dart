// lib/screens/reservation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReservationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    // 시간 포맷팅
    String formatDateTime(Timestamp? timestamp) {
      if (timestamp == null) return '정보 없음';
      final dateTime = timestamp.toDate();
      return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dateTime);
    }

    // 시간만 포맷팅
    String formatTime(Timestamp? timestamp) {
      if (timestamp == null) return '정보 없음';
      final dateTime = timestamp.toDate();
      return DateFormat('HH:mm').format(dateTime);
    }

    // 상태에 따른 색상
    Color getStatusColor(String? status) {
      switch (status) {
        case 'confirmed':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        case 'cancelled':
          return Colors.red;
        default:
          return Colors.orange; // 기본값: 승인 대기중
      }
    }

    // 👇 상태 텍스트 (이모지 제거)
    String getStatusText(String? status) {
      switch (status) {
        case 'confirmed':
          return '확정'; // 👈 체크 마크 제거
        case 'pending':
          return '승인 대기중';
        case 'cancelled':
          return '취소됨';
        default:
          return '승인 대기중'; // 👈 기본값: 승인 대기중
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
            // 공간 이미지 + 이름 헤더
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
                      // 이미지
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                      // 공간 이름
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
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 핵심 정보 섹션
            const Text(
              '핵심 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 예약 일시
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

            // 예약 상태
            _buildInfoCard(
              icon: Icons.info_outline,
              iconColor: getStatusColor(reservation['status']),
              title: '예약 상태',
              content: getStatusText(reservation['status']),
              contentColor: getStatusColor(reservation['status']),
            ),

            const SizedBox(height: 12),

            // 예약자 이름
            _buildInfoCard(
              icon: Icons.person,
              iconColor: Colors.orange,
              title: '예약자 이름',
              content: reservation['userName'] ?? '김지안님',
            ),

            const SizedBox(height: 24),

            // 360도 뷰 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final spacesSnapshot = await FirebaseFirestore.instance
                        .collection('spaces')
                        .where('name', isEqualTo: reservation['spaceName'])
                        .limit(1)
                        .get();

                    if (spacesSnapshot.docs.isNotEmpty) {
                      final spaceData = spacesSnapshot.docs.first.data();
                      final view360Url = spaceData['view360Url'];

                      if (view360Url != null && view360Url.isNotEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('360도 뷰어는 추후 구현 예정입니다')),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('이 공간은 360도 뷰를 제공하지 않습니다')),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('오류 발생: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.threesixty),
                label: const Text('360도 뷰로 미리보기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 👇 예약 취소 버튼 (취소됨이 아닐 때만 표시)
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

  // 정보 카드 위젯
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

  // 👇 예약 취소 다이얼로그 (실제 구현) - 스낵바 색상 수정
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
                // 👇 Firestore에서 예약 문서 찾아서 상태 업데이트
                final reservationsSnapshot = await FirebaseFirestore.instance
                    .collection('reservations')
                    .where('userId', isEqualTo: reservation['userId'])
                    .where('spaceName', isEqualTo: reservation['spaceName'])
                    .where('status', whereIn: ['confirmed', 'pending']).get();

                if (reservationsSnapshot.docs.isNotEmpty) {
                  // 첫 번째 문서 찾기 (시간까지 정확히 매칭)
                  for (var doc in reservationsSnapshot.docs) {
                    final data = doc.data();

                    // 시간 비교
                    bool isMatch = false;
                    if (reservation['startTime'] != null &&
                        data['startTime'] != null) {
                      isMatch =
                          (reservation['startTime'] as Timestamp).seconds ==
                              (data['startTime'] as Timestamp).seconds;
                    } else if (reservation['date'] != null &&
                        reservation['timeSlot'] != null) {
                      isMatch = data['date'] == reservation['date'] &&
                          data['timeSlot'] == reservation['timeSlot'];
                    }

                    if (isMatch) {
                      // 상태를 'cancelled'로 변경
                      await doc.reference.update({
                        'status': 'cancelled',
                        'cancelledAt': FieldValue.serverTimestamp(),
                      });

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext); // 다이얼로그 닫기
                      }

                      if (context.mounted) {
                        // 👇 성공 스낵바 - 진한 회색으로 변경!
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('예약이 취소되었습니다'),
                            backgroundColor: Colors.grey, // 👈 진한 회색
                          ),
                        );

                        // 이전 화면으로 돌아가기
                        Navigator.pop(context);
                      }
                      return;
                    }
                  }
                }

                // 예약을 찾지 못한 경우
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('예약을 찾을 수 없습니다'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
