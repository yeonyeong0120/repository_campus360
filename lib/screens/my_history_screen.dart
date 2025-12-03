import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:repository_campus360/screens/reservation_detail_screen.dart'; // 예약 상세 이동용
import 'dart:math' as math; // 3D 회전 효과를 위해 필요

class MyHistoryScreen extends StatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  State<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends State<MyHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 예약 완료 처리 (시간 지나면 자동 완료)
  Future<void> _checkAndCompleteReservations(
      List<QueryDocumentSnapshot> docs) async {
    final now = DateTime.now();
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      // 상태가 confirmed이고 시간이 지났으면 completed로 변경
      if (data['endTime'] != null && data['status'] == 'confirmed') {
        final DateTime endTime = (data['endTime'] as Timestamp).toDate();
        if (now.isAfter(endTime)) {
          await doc.reference.update({'status': 'completed'});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // 배경을 조금 더 짙게 하여 흰색 티켓 강조
      appBar: AppBar(
        title: const Text("내 티켓 지갑", // 제목 변경: 활동 내역 -> 내 티켓 지갑
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'manru')),
        backgroundColor: const Color(0xFFF0F2F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          tabs: const [Tab(text: "보유 티켓"), Tab(text: "리뷰 모아보기")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationList(user.uid),
          _buildMyReviewList(user.uid)
        ],
      ),
    );
  }

  // 1. 예약 내역 리스트 (티켓 리스트로 변경)
  Widget _buildReservationList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("발급된 티켓이 없습니다.\n예약을 통해 티켓을 수집해보세요!",
              Icons.local_activity_outlined);
        }

        _checkAndCompleteReservations(snapshot.data!.docs);
        final docs = snapshot.data!.docs;

        // 최신순 정렬
        docs.sort((a, b) {
          var aTime = a['createdAt'] as Timestamp?;
          var bTime = b['createdAt'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            data['docId'] = docs[index].id;

            // 🌟 [핵심] 기존 Card 대신 커스텀 TicketItem 사용
            return TicketItem(
              data: data,
              onTap: () {
                // 상세 페이지 이동
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ReservationDetailScreen(reservation: data)));
              },
            );
          },
        );
      },
    );
  }

  // 2. 내가 쓴 리뷰 리스트 (기존 코드 유지하되 디자인 살짝 다듬음)
  Widget _buildMyReviewList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _buildEmptyState(
              "작성한 리뷰 기록이 없습니다.", Icons.rate_review_outlined);
        }

        docs.sort((a, b) {
          var aTime = a['createdAt'] as Timestamp?;
          var bTime = b['createdAt'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            // 기존 코드: 리뷰 리스트 아이템 디자인은 유지하되 폰트 적용
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['spaceName'] ?? '공간 정보 없음',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(data['content'] ?? '',
                      style: TextStyle(color: Colors.grey[800])),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 16, height: 1.5))
    ]));
  }
}

// ---------------------------------------------------------
// 🎫 [NEW] Ticket Item Widget (티켓 모양 + 뒤집기 애니메이션)
// ---------------------------------------------------------
class TicketItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const TicketItem({super.key, required this.data, required this.onTap});

  @override
  State<TicketItem> createState() => _TicketItemState();
}

class _TicketItemState extends State<TicketItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _animation;
  bool _isFront = true; // 현재 앞면인지 확인

  // 리뷰 작성을 위한 컨트롤러
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    // 3D 회전 애니메이션 설정 (0 ~ 180도 회전)
    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack));

    // 기존 리뷰가 있다면 불러오기 (간단한 구현을 위해 여기서는 생략하고 신규 작성 위주로)
  }

  @override
  void dispose() {
    _flipController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'];
    // 사용 완료된 티켓은 흑백 처리 (채도 0)
    final bool isUsed = (status == 'completed' || status == 'cancelled');

    return GestureDetector(
      onTap: widget.onTap, // 티켓을 누르면 상세 페이지로
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // 3D 회전 효과 행렬 연산
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // 원근감 추가
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _animation.value < 0.5
                ? _buildFrontSide(status, isUsed) // 0~90도: 앞면
                : Transform(
                    // 90~180도: 뒷면 (거울 모드 방지를 위해 Y축 180도 회전 보정)
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackSide(isUsed),
                  ),
          );
        },
      ),
    );
  }

  // 🎟️ 티켓 앞면 (정보 + 바코드 + 도장)
  Widget _buildFrontSide(String? status, bool isUsed) {
    Color themeColor = isUsed ? Colors.grey : Colors.blue;

    return ColorFiltered(
      // 사용 완료된 티켓은 흑백으로 보이게 필터 적용
      colorFilter: isUsed
          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: ClipPath(
        clipper: TicketClipper(), // 🌟 티켓 모양 자르기
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Stack(
            children: [
              // 좌측 색상 띠
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 6, color: themeColor),
              ),

              // 내용물
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단: 공간 이름 & 날짜
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.data['spaceName'] ?? 'SPACE TICKET',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'manru'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 우측 상단 로고 느낌
                        Icon(Icons.airplane_ticket,
                            color: themeColor.withOpacity(0.3)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.data['date']} | ${widget.data['timeSlot']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),

                    const Spacer(),

                    // 하단: 바코드 흉내 & 좌석 정보
                    const Divider(
                        height: 20,
                        thickness: 1,
                        indent: 0,
                        endIndent: 0), // 절취선 느낌의 실선
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 바코드 (디자인 요소)
                        Row(
                          children: List.generate(
                              15,
                              (index) => Container(
                                    width: index % 2 == 0 ? 2 : 4,
                                    height: 30,
                                    margin: const EdgeInsets.only(right: 3),
                                    color: Colors.black87,
                                  )),
                        ),
                        Text(
                            "NO. ${widget.data['docId'].substring(0, 4).toUpperCase()}",
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),

              // 🌟 도장 (Stamp) 효과
              if (status == 'confirmed' || status == 'completed')
                Positioned(
                  top: 40,
                  right: 30,
                  child: Transform.rotate(
                    angle: -0.2, // 약간 기울이기
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: status == 'completed'
                                ? Colors.grey
                                : Colors.red.withOpacity(0.7),
                            width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'completed' ? "USED" : "CONFIRMED",
                        style: TextStyle(
                            color: status == 'completed'
                                ? Colors.grey
                                : Colors.red.withOpacity(0.7),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2),
                      ),
                    ),
                  ),
                ),

              // 뒤집기 버튼 (우측 하단)
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _flipCard,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.grey[100], shape: BoxShape.circle),
                    child: const Icon(Icons.refresh,
                        size: 20, color: Colors.blueGrey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 티켓 뒷면 (리뷰 작성)
  Widget _buildBackSide(bool isUsed) {
    return ClipPath(
      clipper: TicketClipper(),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA), // 뒷면은 약간 종이 질감 색
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("How was your experience?",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'manru')),
              const SizedBox(height: 10),

              // 별점
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Icon(
                      index < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFFFC107),
                      size: 32,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 10),

              // 간단 리뷰 입력 (여기를 누르면 키보드가 올라옴)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _reviewController,
                    decoration: const InputDecoration(
                        hintText: "짧은 한줄평을 남겨주세요 (Ticket 기록)",
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey)),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 저장 & 뒤집기 버튼 row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: _flipCard,
                      child: const Text("닫기",
                          style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                    onPressed: () {
                      // 여기에 실제 리뷰 저장 로직(Firebase)을 연결하면 됩니다.
                      // 현재는 UI 데모를 위해 스낵바만 띄웁니다.
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("티켓 뒷면에 기록이 저장되었습니다! 🎫")));
                      _flipCard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(60, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("기록하기",
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ✂️ 티켓 모양을 잘라주는 Clipper (양옆이 파인 모양)
class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);

    // 왼쪽 구멍 (반원)
    path.addOval(
        Rect.fromCircle(center: Offset(0.0, size.height * 0.7), radius: 10.0));
    // 오른쪽 구멍 (반원)
    path.addOval(Rect.fromCircle(
        center: Offset(size.width, size.height * 0.7), radius: 10.0));

    path.fillType = PathFillType.evenOdd; // 겹치는 부분 구멍 뚫기
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
