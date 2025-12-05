// lib/screens/detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'reservation_screen.dart';
import 'webview_screen.dart'; // 💡 [필수] 360도 뷰 화면 연결

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> space;
  final int initialIndex;

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
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  // 🔥 [이미지 매핑 데이터]
  static const Map<String, List<String>> _localImageMap = {
    '강의실 2': [
      'assets/images/강의실2.png',
      'assets/images/강의실2.png',
      'assets/images/강의실2.png',
    ],
    '컨퍼런스룸': [
      'assets/images/컨퍼런스룸.png',
      'assets/images/컨퍼런스룸.png',
      'assets/images/컨퍼런스룸.png',
    ],
    '디지털데이터활용실습실': [
      'assets/images/디지털데이터활용실습실.png',
      'assets/images/디지털데이터활용실습실.png',
      'assets/images/디지털데이터활용실습실.png',
    ],
    'CATIA실습실': ['assets/images/tech2.png'],
    '전기자동차실습실': ['assets/images/tech2.png'],
    '자동차과이론강의실': ['assets/images/tech2.png'],
    'CAD/CAE실': ['assets/images/tech2.png'],
    'PLC실습실': ['assets/images/tech2.png'],
    '개인미디어실': ['assets/images/tech5.png'],
    '실감형콘텐츠운영실습실': ['assets/images/tech5.png'],
    '세미나실': ['assets/images/tech5.png'],
    '미디어편집실': ['assets/images/tech5.png'],
    'AI융합프로젝트실습실': ['assets/images/tech5.png'],
    '전자CAD실': ['assets/images/tech5.png'],
    '기초전자실습실': ['assets/images/tech5.png'],
    '미디어창작실습실': ['assets/images/tech5.png'],
    '아이디어카페': ['assets/images/tech5.png'],
    '융합디자인실습실': ['assets/images/tech5.png'],
    '시제품창의개발실': ['assets/images/tech5.png'],
    '콘트롤러실습실': ['assets/images/tech2.png'],
    'CAD실습실': ['assets/images/tech2.png'],
    '소그룹실': ['assets/images/tech5.png'],
    '강의실': ['assets/images/tech5.png'],
    '로비': ['assets/images/main_building.png'],
    '행정실': ['assets/images/main_building.png'],
  };

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
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String view360Url = widget.space['view360Url'] ?? '';
    final String spaceName = widget.space['name'] ?? '';

    // 이미지 리스트 로딩 로직
    List<String> images = [];
    if (_localImageMap.containsKey(spaceName)) {
      images = _localImageMap[spaceName]!;
    } else if (widget.space['images'] != null &&
        (widget.space['images'] as List).isNotEmpty) {
      images = List<String>.from(widget.space['images']);
    } else if (widget.space['mainImageUrl'] != null &&
        widget.space['mainImageUrl'] != '') {
      images = [widget.space['mainImageUrl']];
    }
    if (images.isNotEmpty && images[0] == '') {
      images.removeAt(0);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          spaceName,
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
      // 🔥 [핵심 수정 1] body를 Stack으로 변경하여 버튼을 화면 위에 띄움 (Overlay)
      body: Stack(
        children: [
          // 1. 기존 내용 (스크롤 영역)
          Column(
            children: [
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 🔥 중요: 버튼에 가려지지 않게 하단에 여백(padding)을 줌
                    Padding(
                      padding: const EdgeInsets.only(bottom: 80), // 버튼 높이만큼 띄움
                      child: _buildDetailTab(images, view360Url),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: _buildReviewTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. 예약하기 버튼 (화면 하단에 고정)
          // 🔥 BottomNavigationBar 대신 여기에 위치시켜서 SnackBar가 이 위를 덮게 함
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white, // 버튼 뒤 배경색
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                top: false, // 상단 SafeArea 무시
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
          ),
        ],
      ),
      // 🔥 [핵심 수정 2] BottomNavigationBar 삭제됨 (위 Stack 안으로 이동)
    );
  }

  Widget _buildDetailTab(List<String> images, String view360Url) {
    String capacityText;
    var rawCapacity = widget.space['capacity'];
    String capacityStr = rawCapacity?.toString() ?? '0';

    if (int.tryParse(capacityStr) != null) {
      capacityText = "$capacityStr명 수용";
    } else {
      capacityText = capacityStr;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: images.isNotEmpty
                ? Stack(
                    children: [
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
                            return Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image)),
                            );
                          } else {
                            return Image.asset(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                          Icons.image_not_supported)),
                            );
                          }
                        },
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 24,
                          child: Row(
                            children: List.generate(
                              images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                width: _currentImageIndex == index ? 24 : 8,
                                height: 6,
                                decoration: BoxDecoration(
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
                        capacityText,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _FacilityIcon(icon: Icons.wifi, label: "Wi-Fi"),
                    _FacilityIcon(icon: Icons.tv, label: "스크린"),
                    _FacilityIcon(icon: Icons.ac_unit, label: "에어컨"),
                    _FacilityIcon(icon: Icons.power, label: "콘센트"),
                  ],
                ),

                const SizedBox(height: 40),

                // 🌟 [수정된 360도 뷰 버튼]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (view360Url.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WebViewScreen(view360Url: view360Url),
                            ),
                          );
                        } else {
                          // 🔥 [여기] SnackBar가 기본 위치에 뜹니다 (Stack 구조 덕분에 버튼 위를 덮음)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("미리보기가 지원되지 않는 강의실입니다."),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.threesixty, size: 18),
                      label: const Text("360도 뷰로 공간 미리보기"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4282CB),
                        side: const BorderSide(
                            color: Color(0xFF4282CB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'manru'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('spaceName', isEqualTo: widget.space['name'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("리뷰를 불러오는 중 오류가 발생했습니다.\n${snapshot.error}",
                  textAlign: TextAlign.center));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("아직 작성된 리뷰가 없습니다.\n첫 번째 리뷰를 남겨보세요!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }

        final reviews = snapshot.data!.docs;
        reviews.sort((a, b) {
          final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final data = reviews[index].data() as Map<String, dynamic>;

            final userName = data['userName'] ?? '익명';
            final content = data['content'] ?? '';
            final rating = (data['rating'] ?? 5).toDouble();

            String dateStr = '';
            if (data['createdAt'] != null) {
              final ts = data['createdAt'] as Timestamp;
              dateStr = DateFormat('yyyy.MM.dd').format(ts.toDate());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      radius: 18,
                      child: Text(
                        userName.isNotEmpty ? userName[0] : '?',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          dateStr,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          Icons.star,
                          size: 18,
                          color: starIndex < rating
                              ? const Color(0xFFFFC107)
                              : Colors.grey[300],
                        );
                      }),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            );
          },
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
