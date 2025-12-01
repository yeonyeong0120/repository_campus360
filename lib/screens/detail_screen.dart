// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reservation_screen.dart'; // 예약하기 버튼 누르면 여기로 이동
import 'webview_screen.dart'; // 360도 뷰

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> space;

  const DetailScreen({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    // 360도 뷰 URL 및 이미지 URL 안전하게 가져오기
    final String view360Url = space['view360Url'] ?? '';
    final String imageUrl = space['image'] ?? space['mainImageUrl'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // 배경색 통일
      appBar: AppBar(
        title: Text(
          space['name'] ?? '공간 상세',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'manru',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // 📸 [1. 메인 이미지 카드]
            // -------------------------------------------------------
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                  // 이미지 (상단 둥글게)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 220,
                                color: Colors.grey[100],
                                child: const Center(
                                    child: Icon(Icons.image_not_supported,
                                        color: Colors.grey, size: 40)),
                              );
                            },
                          )
                        : Container(
                            height: 220,
                            color: Colors.blue[50],
                            child: Center(
                              child: Icon(Icons.meeting_room_rounded,
                                  size: 70, color: Colors.blue[200]),
                            ),
                          ),
                  ),

                  // 텍스트 정보
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                space['name'] ?? '이름 없음',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'manru',
                                ),
                              ),
                            ),
                            // 수용 인원 뱃지
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${space['capacity'] ?? 0}명 수용",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'manru',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              space['location'] ?? '위치 정보 없음',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                fontFamily: 'manru',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // -------------------------------------------------------
            // 🛋️ [2. 편의 시설 정보]
            // -------------------------------------------------------
            const Text(
              "편의 시설",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
                fontFamily: 'manru',
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _FacilityIcon(icon: Icons.wifi, label: "Wi-Fi"),
                  _FacilityIcon(icon: Icons.tv, label: "스크린"),
                  _FacilityIcon(icon: Icons.ac_unit, label: "에어컨"),
                  _FacilityIcon(icon: Icons.power, label: "콘센트"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // -------------------------------------------------------
            // 🔘 [3. 하단 버튼 (360뷰 & 예약)]
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
                        builder: (_) => WebViewScreen(view360Url: view360Url),
                      ),
                    );
                  },
                  icon: const Icon(Icons.threesixty, size: 22),
                  label: const Text("360도 뷰로 미리보기"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                    side:
                        const BorderSide(color: Color(0xFF2196F3), width: 1.5),
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

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservationScreen(space: space),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'manru'),
                ),
                child: const Text("이 공간 예약하기"),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// 편의시설 아이콘 위젯
class _FacilityIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FacilityIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA), // 아이콘 배경도 부드러운 색으로
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontFamily: 'manru',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
