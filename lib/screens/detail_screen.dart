// lib/screens/detail_screen.dart

import 'package:flutter/material.dart';
import 'reservation_screen.dart'; // 예약하기 버튼 누르면 이동
import 'webview_screen.dart'; // 360도 뷰

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> space;
  final int initialIndex; // 0: 상세정보, 1: 리뷰

  const DetailScreen({
    super.key,
    required this.space,
    this.initialIndex = 0,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🌟 이미지 슬라이더용 컨트롤러
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 360도 뷰 URL
    final String view360Url = widget.space['view360Url'] ?? '';

    // 🌟 [이미지 데이터 준비]
    final List<String> images = widget.space['images'] != null
        ? List<String>.from(widget.space['images'])
        : [
            widget.space['image'] ?? widget.space['mainImageUrl'] ?? '',
            // 👇 테스트용 이미지 (스크롤 확인용)
            "assets/images/conference.jpg",
            "assets/images/lab.jpg",
            "assets/images/class2.jpg",
          ];

    // 만약 첫 번째 이미지가 비어있다면 제거 (빈 화면 방지)
    if (images.isNotEmpty && images[0] == '') {
      images.removeAt(0);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.space['name'] ?? '공간 상세',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'manru',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. 탭 바 (상단 고정)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4282CB),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF4282CB),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'manru',
              ),
              tabs: const [
                Tab(text: "상세 정보"),
                Tab(text: "리뷰"),
              ],
            ),
          ),

          // 2. 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailTab(images, view360Url), // 🌟 상세 탭
                _buildReviewTab(), // 🌟 리뷰 탭
              ],
            ),
          ),
        ],
      ),

      // 하단 고정 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReservationScreen(space: widget.space),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4282CB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "이 공간 예약하기",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'manru',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📄 탭 1: 상세 정보 (이미지 슬라이더 + 인디케이터 추가됨!)
  Widget _buildDetailTab(List<String> images, String view360Url) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📸 [1. 상단 이미지 슬라이더]
          SizedBox(
            height: 350,
            width: double.infinity,
            child: images.isNotEmpty
                ? Stack(
                    children: [
                      // 1-1. 이미지 PageView
                      PageView.builder(
                        controller: _imagePageController,
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final imageUrl = images[index];
                          if (imageUrl.startsWith('http')) {
                            return Image.network(imageUrl, fit: BoxFit.cover);
                          } else {
                            return Image.asset(imageUrl, fit: BoxFit.cover);
                          }
                        },
                      ),

                      // 🌟 1-2. [추가됨] 이미지 인디케이터 (파란 막대 / 회색 막대)
                      // 사진이 2장 이상일 때만 표시
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 24, // 홈 화면과 위치 통일
                          child: Row(
                            children: List.generate(
                              images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                // 선택된 건 길게(24), 나머지는 짧게(8)
                                width: _currentImageIndex == index ? 24 : 8,
                                height: 6, // 두께
                                decoration: BoxDecoration(
                                  // 선택된 건 파란색(#4282CB), 나머지는 반투명 흰색
                                  color: _currentImageIndex == index
                                      ? const Color(0xFF4282CB)
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 50, color: Colors.grey),
                    ),
                  ),
          ),

          // 상세 정보 내용
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.space['name'] ?? '이름 없음',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'manru',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              widget.space['location'] ?? '위치 정보 없음',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${widget.space['capacity'] ?? 0} 수용",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  "편의 시설",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'manru'),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _FacilityIcon(icon: Icons.wifi, label: "Wi-Fi"),
                    _FacilityIcon(icon: Icons.tv, label: "스크린"),
                    _FacilityIcon(icon: Icons.ac_unit, label: "에어컨"),
                    _FacilityIcon(icon: Icons.power, label: "콘센트"),
                  ],
                ),

                // 360도 뷰 버튼 (URL 있을 때만 표시)
                if (view360Url.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
                      icon: const Icon(Icons.threesixty, size: 20),
                      label: const Text("360도 뷰로 미리보기"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4282CB),
                        side: const BorderSide(
                            color: Color(0xFF4282CB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'manru'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ 탭 2: 리뷰 위젯 (최신순 정렬 포함)
  Widget _buildReviewTab() {
    final reviews = [
      {
        "user": "허*롱",
        "date": "2024.03.15",
        "content": "팀플하기 너무 좋아요! 시설도 깨끗하고 에어컨도 빵빵합니다 👍",
        "rating": 5
      },
      {
        "user": "김*영",
        "date": "2024.03.14",
        "content": "PC 속도가 빨라서 과제하기 편했어요. 다음에도 예약할게요.",
        "rating": 4
      },
      {
        "user": "오*자",
        "date": "2024.03.10",
        "content": "조용하고 집중 잘 됩니다. 시험 기간에 강추!",
        "rating": 5
      },
      {
        "user": "박*민",
        "date": "2024.03.09",
        "content": "넓고 쾌적해서 좋았습니다. 다음에 또 이용할게요.",
        "rating": 5
      },
      {
        "user": "이*진",
        "date": "2024.03.08",
        "content": "와이파이가 빨라서 좋았어요.",
        "rating": 4
      },
      {
        "user": "최*수",
        "date": "2024.03.07",
        "content": "공간이 넓어서 답답하지 않아요.",
        "rating": 5
      },
      {
        "user": "정*우",
        "date": "2024.03.06",
        "content": "콘센트가 많아서 노트북 쓰기 편해요.",
        "rating": 5
      },
    ];

    // 🌟 날짜 기준 최신순 정렬
    reviews.sort((a, b) {
      String dateA = (a['date'] as String).replaceAll('.', '-');
      String dateB = (b['date'] as String).replaceAll('.', '-');
      return dateB.compareTo(dateA);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  radius: 18,
                  child: Text(
                    (review['user'] as String)[0],
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['user'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      review['date'] as String,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      Icons.star,
                      size: 18,
                      color: starIndex < (review['rating'] as int)
                          ? const Color(0xFF4282CB)
                          : Colors.grey[300],
                    );
                  }),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review['content'] as String,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        );
      },
    );
  }
}

class _FacilityIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FacilityIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontFamily: 'manru',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
