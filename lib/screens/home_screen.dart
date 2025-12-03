// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 DB 사용을 위해 필수
// 날짜 포맷을 위해 필요 (없으면 pubspec.yaml에 intl 추가 권장, 없으면 기본 포맷 사용)

import 'package:repository_campus360/screens/chatbot_sheet.dart';
import 'detail_screen.dart';
import 'my_history_screen.dart';
import 'map_screen.dart';
import '../widgets/common_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // 🌟 [데이터] 강의실 데이터 (상단 배너용은 고정)
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

  // 🗑️ [삭제됨] 기존의 가짜 reviews 리스트는 삭제했습니다!

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

  // 🌟 시간 포맷 헬퍼 함수
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "방금 전";
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inMinutes < 1) return "방금 전";
    if (diff.inMinutes < 60) return "${diff.inMinutes}분 전";
    if (diff.inHours < 24) return "${diff.inHours}시간 전";
    return "${date.month}/${date.day}"; // intl 패키지 없이 간단하게 표현
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
                    color: const Color(0xFF4282CB),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4282CB).withValues(alpha: 0.3),
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
              // 챗봇
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
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const ChatbotSheet(),
                      );
                    },
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
          // 📸 1. 상단 이미지 슬라이더
          // ---------------------------------------------------------
          Expanded(
            flex: 10,
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
                    return _buildHeroCard(featuredSpaces[index]);
                  },
                ),
                Positioned(
                  bottom: 15,
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
          // 📝 2. 하단 리뷰 리스트 (Real-time Firestore 연동)
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

                  // 🌟 [수정됨] StreamBuilder로 실제 DB 데이터 가져오기
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reviews')
                          .orderBy('createdAt', descending: true) // 최신순 정렬
                          .limit(10) // 홈화면이니까 최신 10개만 보여주기
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(child: Text("데이터를 불러오지 못했습니다."));
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rate_review_outlined,
                                    size: 40, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                const Text("아직 등록된 후기가 없어요!",
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 5),
                          itemCount: docs.length,
                          separatorBuilder: (context, index) => const Divider(
                              height: 1, color: Color(0xFFF0F0F0)),
                          itemBuilder: (context, index) {
                            final reviewData =
                                docs[index].data() as Map<String, dynamic>;

                            // 🌟 사용자 이름 가져오기 (비동기)
                            return _buildReviewItem(reviewData);
                          },
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

  // 🌟 [추가됨] 리뷰 아이템 위젯 (사용자 이름 fetch 포함)
  Widget _buildReviewItem(Map<String, dynamic> reviewData) {
    final String userId = reviewData['userId'];
    final String content = reviewData['content'] ?? "";
    final String spaceName = reviewData['spaceName'] ?? "공간";
    final Timestamp? createdAt = reviewData['createdAt'];

    return FutureBuilder<DocumentSnapshot>(
      // 리뷰 작성자의 ID로 users 컬렉션에서 이름 가져오기
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String userName = "익명";
        if (userSnapshot.hasData && userSnapshot.data != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData['name'] != null) {
            String rawName = userData['name'];
            // 이름 마스킹 (예: 김철수 -> 김*수)
            if (rawName.length > 1) {
              userName =
                  "${rawName[0]}*${rawName.substring(rawName.length - 1)}";
            } else {
              userName = rawName;
            }
          }
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // 해당 공간의 상세 페이지로 이동
              final targetSpace = featuredSpaces.firstWhere(
                (element) => element['name'] == spaceName,
                orElse: () => featuredSpaces[0],
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(
                    space: targetSpace,
                    initialIndex: 1, // 리뷰 탭 열기
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[100],
                    child: Text(
                      userName.substring(0, 1),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          content,
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
                          "# $spaceName",
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
    );
  }

  // 상단 히어로 카드 빌더 (기존 유지)
  Widget _buildHeroCard(Map<String, dynamic> space) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[300],
          child: Stack(
            fit: StackFit.expand,
            children: [
              CommonImage(
                space['image'],
                fit: BoxFit.cover,
              ),
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
                bottom: 35,
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
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(
                      space: space,
                      initialIndex: 0,
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
