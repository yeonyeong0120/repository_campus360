// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'reservation_screen.dart';
import 'webview_screen.dart'; // 💡 360도 뷰어 연동을 위한 화면 임포트

class DetailScreen extends StatelessWidget {
  // 강의실 정보는 검색 결과화면에서 전달받음
  final Map<String, dynamic> space;

  const DetailScreen({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    // 편의시설 목록
    final facilities = List<String>.from(space['facilities'] ?? []);
    // 💡 360도 뷰어 URL 추출 (null 안전성을 위해 기본값 설정)
    final view360Url = space['view360Url'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text(space['name'] ?? '공간 상세')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 강의실 이미지 (이미지가 없으면 회색 박스로 대체)
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[300],
              child: space['image'] != null && space['image'].isNotEmpty
                  ? Image.network(space['image'], fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported,
                      size: 50, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. 제목 및 위치
                  Text(
                    space['name'] ?? '이름 없음',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        space['location'] ?? '위치 정보 없음',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // 3. 기본 정보 (수용 인원 등)
                  const Text("공간 정보",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      Icons.people, "수용 인원", "${space['capacity'] ?? 0}명"),

                  const SizedBox(height: 20),

                  // 4. 편의 시설 (Chips)
                  if (facilities.isNotEmpty) ...[
                    const Text("편의 시설",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: facilities.map((facility) {
                        return Chip(
                          label: Text(facility),
                          backgroundColor: Colors.blue[50],
                          labelStyle: const TextStyle(color: Colors.blue),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // 5. 360도 뷰어 버튼 (기능 연결 완료)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // 💡 URL이 있을 때만 WebViewScreen으로 이동
                        if (view360Url != null && view360Url.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // view360Url을 WebViewScreen으로 전달
                              builder: (_) =>
                                  WebViewScreen(view360Url: view360Url),
                            ),
                          );
                        } else {
                          // URL이 없을 경우, 팀원에게 URL 등록을 요청하도록 알림
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "360도 뷰어 URL이 등록되지 않았습니다. Unity 콘텐츠 팀원에게 요청하세요.")),
                          );
                        }
                      },
                      icon: const Icon(Icons.threesixty_rounded),
                      label: const Text("360도 뷰로 미리보기"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 6. 예약하기 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: () {
            // 여기에 예약화면 연결
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReservationScreen(space: space),
              ),
            );
          }, // onPressed
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text("날짜 선택하고 예약하기"),
        ),
      ),
    );
  }

  // 아이콘 + 라벨 + 값 형태의 행 만들어주는 메서드...
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
