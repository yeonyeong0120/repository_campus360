// lib/screens/detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'reservation_screen.dart';
import 'webview_screen.dart';

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

    // 🔥 [수정] 이미지가 없으면 빈 리스트로 초기화 (없는 로컬 파일 강제 로드 금지)
    List<String> images = [];
    if (widget.space['images'] != null &&
        (widget.space['images'] as List).isNotEmpty) {
      images = List<String>.from(widget.space['images']);
    } else if (widget.space['mainImageUrl'] != null &&
        widget.space['mainImageUrl'] != '') {
      images = [widget.space['mainImageUrl']];
    }
    // 주의: 여기에 없는 assets/... 파일을 넣으면 에러가 납니다.

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
                _buildDetailTab(images, view360Url),
                _buildReviewTab(),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildDetailTab(List<String> images, String view360Url) {
    // 🔥 [수정] 수용 인원 텍스트 처리 로직
    String capacityText;
    var rawCapacity = widget.space['capacity'];

    // 데이터가 null이면 '0'
    String capacityStr = rawCapacity?.toString() ?? '0';

    // 숫자로 변환 가능한지 확인 (예: "30" -> 가능, "정보 없음" -> 불가능)
    if (int.tryParse(capacityStr) != null) {
      // 숫자라면 "명 수용" 붙이기
      capacityText = "$capacityStr명 수용";
    } else {
      // 숫자가 아니면(문자면) 그냥 그대로 표시
      capacityText = capacityStr;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 350,
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
                          // 🔥 [수정] 네트워크 이미지 에러 처리 추가
                          if (imageUrl.startsWith('http')) {
                            return Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            );
                          } else {
                            // 로컬 이미지는 try-catch가 안되므로 파일이 확실할 때만 써야 함
                            // 여기서는 안전하게 네트워크 이미지가 아니면 기본 박스 처리
                            return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                    child: Icon(Icons.image,
                                        size: 50, color: Colors.grey)));
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
                        capacityText, // 🔥 [수정됨] 안전하게 처리된 텍스트 사용
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
                      label: const Text("360도 뷰로 공간 미리보기"),
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

  // 🔥 리뷰 탭
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
