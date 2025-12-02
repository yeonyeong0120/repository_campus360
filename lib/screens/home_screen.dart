// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

// 🌟 [경로 유지]
import 'detail_screen.dart'; // 🌟 상세 페이지 (탭 포함)
import 'my_history_screen.dart';
import 'map_screen.dart';
// import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // 🌟 [데이터] 강의실 데이터
  final List<Map<String, dynamic>> featuredSpaces = [
    {
      "name": "컨퍼런스룸",
      "location": "하이테크관 2F",
      "capacity": "20명",
      "desc": "넓은 공간과 쾌적한 환경",
      "image": "assets/images/conference.jpg",
    },
    {
      "name": "디지털데이터활용실습실",
      "location": "하이테크관 3F",
      "capacity": "20명",
      "desc": "최신형 PC와 듀얼 모니터",
      "image": "assets/images/lab.jpg",
    },
    {
      "name": "강의실 2",
      "location": "하이테크관 3F",
      "capacity": "30명",
      "desc": "팀 프로젝트에 최적화된 공간",
      "image": "assets/images/class2.jpg",
    },
  ];

  // 🌟 [데이터] 리뷰 데이터
  final List<Map<String, String>> reviews = [
    {
      "user": "허*롱",
      "space": "컨퍼런스룸",
      "content": "팀플하기 너무 좋아요! 시설도 깨끗하고 에어컨도 빵빵합니다 👍",
      "date": "방금 전"
    },
    {
      "user": "김*영",
      "space": "디지털실습실",
      "content": "PC 속도가 빨라서 과제하기 편했어요. 다음에도 예약할게요.",
      "date": "1시간 전"
    },
    {
      "user": "오*자",
      "space": "강의실 2",
      "content": "조용하고 집중 잘 됩니다. 시험 기간에 강추!",
      "date": "3시간 전"
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < featuredSpaces.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        title: Row(
          children: [
            const Text(
              "CAMPUS 360",
              style: TextStyle(
                fontFamily: 'manru',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7BA4D2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7BA4D2).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "공간 예약하기",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () {},
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/images/gemini.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ---------------------------------------------------------
          // 📸 1. 상단 이미지 슬라이더 (클릭 시 상세 탭으로 이동)
          // ---------------------------------------------------------
          Expanded(
            flex: 9,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: featuredSpaces.length,
                  itemBuilder: (context, index) {
                    // 🌟 [수정] InkWell을 감싼 형태로 변경하여 터치 인식 개선
                    return _buildHeroCard(featuredSpaces[index]);
                  },
                ),
                Positioned(
                  bottom: 30,
                  left: 24,
                  child: Row(
                    children: List.generate(
                      featuredSpaces.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF2196F3)
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------
          // 📝 2. 하단 리뷰 리스트 (클릭 시 리뷰 탭으로 이동)
          // ---------------------------------------------------------
          Expanded(
            flex: 11,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "우리 동기들의 후기 💫",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'manru',
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MapScreen()),
                            );
                          },
                          child: const Text(
                            "지도에서 보기",
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 5),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            // 🌟 [수정] InkWell로 감싸서 터치 영역 확보
                            onTap: () {
                              // 리뷰에 해당하는 공간 찾기
                              final targetSpace = featuredSpaces.firstWhere(
                                (element) => element['name'] == review['space'],
                                orElse: () => featuredSpaces[0],
                              );

                              // DetailScreen으로 이동 (리뷰 탭: 1)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailScreen(
                                    space: targetSpace,
                                    initialIndex: 1, // 리뷰 탭 열기!
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[100],
                                    child: Text(
                                      review['user']!.substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              review['user']!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                            Text(
                                              review['date']!,
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          review['content']!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 15,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "# ${review['space']}",
                                          style: const TextStyle(
                                            color: Color(0xFF2196F3),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 [수정] 터치가 잘 되도록 InkWell을 상위에 배치한 카드 위젯
  Widget _buildHeroCard(Map<String, dynamic> space) {
    return Stack(
      children: [
        // 1. 배경 이미지 및 내용 (기존 디자인)
        Container(
          color: Colors.grey[300],
          child: Stack(
            fit: StackFit.expand,
            children: [
              space['image'] != null
                  ? Image.asset(space['image'], fit: BoxFit.cover)
                  : Container(color: Colors.grey[300]),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 50,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        space['location'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      space['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'manru',
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      space['desc'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontFamily: 'manru',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. 🌟 [핵심] 투명한 터치 영역을 가장 위에 덮어씌움
        // 이렇게 하면 아래 위젯들에 상관없이 무조건 클릭이 됩니다.
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // DetailScreen으로 이동 (상세 탭: 0)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(
                      space: space,
                      initialIndex: 0, // 상세 탭 열기!
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
