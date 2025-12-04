// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repository_campus360/screens/chatbot_sheet.dart';
import 'detail_screen.dart';
import 'my_history_screen.dart';
import 'map_screen.dart';
import '../widgets/common_image.dart';

// 1️⃣ 메인 홈 스크린
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              // 챗봇 버튼
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
        children: const [
          // 1. 배너 위젯
          Expanded(
            flex: 10,
            child: HomeBannerWidget(),
          ),
          // 2. 리뷰 리스트 위젯
          Expanded(
            flex: 11,
            child: HomeReviewListWidget(),
          ),
        ],
      ),
    );
  }
}

// 2️⃣ 배너 위젯 (🔥 랜덤 3개 추천 로직 적용됨)
class HomeBannerWidget extends StatefulWidget {
  const HomeBannerWidget({super.key});

  @override
  State<HomeBannerWidget> createState() => _HomeBannerWidgetState();
}

class _HomeBannerWidgetState extends State<HomeBannerWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // 🔥 랜덤으로 선택된 공간들을 저장할 리스트 (계속 바뀌지 않게 저장)
  List<DocumentSnapshot> _bannerSpaces = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_bannerSpaces.isEmpty) return;
      if (_currentPage < _bannerSpaces.length - 1) {
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

  Widget _buildHeroCard(Map<String, dynamic> space) {
    // 💡 1. 이미지 처리
    String imageUrl = space['mainImageUrl'] ?? '';
    if (imageUrl.isEmpty) {
      imageUrl = 'https://via.placeholder.com/600x400?text=No+Image';
    }

    return Stack(
      children: [
        Container(
          color: Colors.grey[300],
          child: Stack(
            fit: StackFit.expand,
            children: [
              CommonImage(
                imageUrl,
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
                        space['location'] ?? '위치 정보 없음',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      space['name'] ?? '공간 이름',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'manru',
                        height: 1.1,
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
                // 🔥 [수정됨] 상세 페이지로 넘기기 전에 데이터 안전장치 마련
                // capacity가 숫자일 수도 있고 문자일 수도 있으니 String으로 변환
                // 없으면 '0'으로 설정
                if (space['capacity'] == null) {
                  space['capacity'] = '0';
                } else {
                  space['capacity'] = space['capacity'].toString();
                }

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('spaces').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // 🔥 [수정됨] 데이터가 로드되었고, 아직 랜덤 리스트를 안 뽑았다면 뽑는다.
        // 이렇게 해야 화면이 갱신될 때마다 배너가 바뀌지 않고 고정됨.
        if (_bannerSpaces.isEmpty && docs.isNotEmpty) {
          // 1. 전체 리스트를 복사해서 섞는다 (Shuffle)
          List<DocumentSnapshot> shuffledDocs = List.from(docs)..shuffle();
          // 2. 앞에서 3개만 자른다 (Take 3)
          // 데이터가 3개보다 적으면 있는 만큼만 가져옴
          _bannerSpaces = shuffledDocs.take(3).toList();
        } else if (docs.isEmpty) {
          return const Center(child: Text("등록된 공간이 없습니다."));
        }

        return Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _bannerSpaces.length, // 🔥 랜덤 3개 개수 사용
              itemBuilder: (context, index) {
                final spaceData =
                    _bannerSpaces[index].data() as Map<String, dynamic>;
                spaceData['docId'] = _bannerSpaces[index].id;
                return _buildHeroCard(spaceData);
              },
            ),
            Positioned(
              bottom: 15,
              left: 24,
              child: Row(
                children: List.generate(
                  _bannerSpaces.length,
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
        );
      },
    );
  }
}

// 3️⃣ 리뷰 리스트 위젯
class HomeReviewListWidget extends StatelessWidget {
  const HomeReviewListWidget({super.key});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "방금 전";
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inMinutes < 1) return "방금 전";
    if (diff.inMinutes < 60) return "${diff.inMinutes}분 전";
    if (diff.inHours < 24) return "${diff.inHours}시간 전";
    return "${date.month}/${date.day}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("오류 발생"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (context, index) {
                    final reviewData =
                        docs[index].data() as Map<String, dynamic>;
                    return _buildReviewItem(context, reviewData);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
      BuildContext context, Map<String, dynamic> reviewData) {
    final String content = reviewData['content'] ?? "";
    final String spaceName = reviewData['spaceName'] ?? "공간";
    final Timestamp? createdAt = reviewData['createdAt'];
    final int rating = reviewData['rating'] ?? 5;

    if (reviewData['userName'] != null && reviewData['userName'] != '') {
      return _buildReviewRow(context, reviewData['userName'], content,
          spaceName, createdAt, rating);
    }

    final String userId = reviewData['userId'];
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String userName = "익명";
        if (userSnapshot.hasData && userSnapshot.data != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData['name'] != null) {
            userName = userData['name'];
          }
        }
        return _buildReviewRow(
            context, userName, content, spaceName, createdAt, rating);
      },
    );
  }

  Widget _buildReviewRow(BuildContext context, String userName, String content,
      String spaceName, Timestamp? createdAt, int rating) {
    String displayName = userName;
    if (userName.length > 1) {
      displayName = "${userName[0]}*${userName.substring(userName.length - 1)}";
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // 🔥 리뷰 클릭 시 DB에서 정확한 공간 정보 조회
          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('spaces')
                .where('name', isEqualTo: spaceName)
                .limit(1)
                .get();

            if (snapshot.docs.isNotEmpty) {
              final realSpaceData = snapshot.docs.first.data();
              realSpaceData['docId'] = snapshot.docs.first.id;

              // 🔥 여기도 동일하게 capacity 데이터 안전장치 추가
              if (realSpaceData['capacity'] == null) {
                realSpaceData['capacity'] = '0';
              } else {
                realSpaceData['capacity'] =
                    realSpaceData['capacity'].toString();
              }

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(
                      space: realSpaceData,
                      initialIndex: 1,
                    ),
                  ),
                );
              }
            } else {
              // DB에 없는 경우
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(
                      space: {
                        "name": spaceName,
                        "location": "위치 정보 없음",
                        "capacity": "0", // 임시 데이터 '0'으로 설정
                        "mainImageUrl": "",
                        "buildingName": "미등록 공간",
                      },
                      initialIndex: 1,
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint("공간 찾기 오류: $e");
          }
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
                  displayName.substring(0, 1),
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
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: index < rating
                                  ? const Color(0xFFFFC107)
                                  : Colors.grey[300],
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
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
  }
}
