// lib/screens/my_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import 'login_screen.dart';

class MyHistoryScreen extends StatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  State<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends State<MyHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _backgroundColor = const Color(0xFFF0F5FA);

  @override
  void initState() {
    super.initState();
    // 탭 컨트롤러 초기화 (0: 내 티켓, 1: 리뷰 쓰기)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAndCompleteReservations(
      List<QueryDocumentSnapshot> docs) async {
    final now = DateTime.now();
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['endTime'] != null && data['status'] == 'confirmed') {
        final DateTime endTime = (data['endTime'] as Timestamp).toDate();
        if (now.isAfter(endTime)) {
          await doc.reference.update({'status': 'completed'});
        }
      }
    }
  }

  // 로그아웃 다이얼로그
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red, size: 30),
              SizedBox(height: 10),
              Text(
                "로그아웃",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'manru',
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            "정말 로그아웃\n하시겠습니까?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'manru',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding:
              const EdgeInsets.only(bottom: 20, left: 10, right: 10),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await FirebaseAuth.instance.signOut();

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "네",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
          backgroundColor: _backgroundColor,
          body: const Center(child: Text("로그인이 필요합니다.")));
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("내 상세 내역",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'manru')),
        centerTitle: true,
        backgroundColor: _backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: '로그아웃',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: "내 티켓"), Tab(text: "리뷰 쓰기")],
        ),
      ),
      body: Container(
        color: _backgroundColor,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildReservationList(user.uid),
            _buildReviewManagementTab(user.uid)
          ],
        ),
      ),
    );
  }

  Widget _buildReservationList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("오류: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = List.of(snapshot.data!.docs);
        if (docs.isEmpty) {
          return const Center(
            child: Text("발급된 티켓이 없습니다.",
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }

        docs.sort((a, b) {
          var aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          var bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        _checkAndCompleteReservations(docs);

        return Container(
          color: _backgroundColor,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              data['docId'] = docs[index].id;

              return SimpleTicketItem(
                key: ValueKey(data['docId']),
                data: data,
                // 리뷰 작성 버튼을 눌렀을 때 탭을 이동시키기 위한 콜백 함수 전달
                onReviewTap: () {
                  _tabController.animateTo(1); // 리뷰 탭으로 이동
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewManagementTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = List.of(snapshot.data!.docs);

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.airplane_ticket_outlined,
                    size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("리뷰를 쓸 수 있는\n완료된 티켓이 없어요!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        docs.sort((a, b) {
          var aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          var bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return Container(
          color: _backgroundColor,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              data['docId'] = docs[index].id;
              return ReviewActionItem(
                  key: ValueKey(data['docId']), reservationData: data);
            },
          ), // 리스트뷰
        );
      },
    );
  }
}

class SimpleTicketItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onReviewTap; // 리뷰 작성 이동 콜백 추가

  const SimpleTicketItem({super.key, required this.data, this.onReviewTap});

  @override
  State<SimpleTicketItem> createState() => _SimpleTicketItemState();
}

class _SimpleTicketItemState extends State<SimpleTicketItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _animation;
  bool _isFront = true;

  // 높이를 전역적으로 줄이기 위해 상수 또는 변수로 관리해도 좋지만
  // 여기서는 직접 위젯에서 160으로 수정합니다. (기존 190)
  final double _ticketHeight = 160.0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  void _onTicketTap() {
    final status = widget.data['status'];
    // 취소됨, 거절됨 상태는 클릭 불가 (뒤집기 안됨)
    if (status == 'cancelled' || status == 'rejected') return;

    // completed(사용완료)는 이제 뒤집기 허용! (리뷰 작성을 위해)
    _flipCard();
  }

  Future<void> _cancelReservation() async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.data['docId'])
          .update({'status': 'cancelled'});
      if (!mounted) return;
      _flipCard();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("오류: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'];
    final bool isCancelled = (status == 'cancelled' || status == 'rejected');

    return RepaintBoundary(
      child: GestureDetector(
        onTap: _onTicketTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * math.pi;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);
            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: _animation.value < 0.5
                  ? _buildFrontSide(status, isCancelled)
                  : Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildBackSide(status),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontSide(String? status, bool isCancelled) {
    Color themeColor = Colors.black;
    if (status == 'pending') themeColor = Colors.orange;
    if (status == 'confirmed') themeColor = Colors.blue;
    if (status == 'cancelled' || status == 'rejected') themeColor = Colors.grey;
    if (status == 'completed') themeColor = Colors.green;

    return ClipPath(
      clipper: TicketClipper(),
      child: Container(
        height: _ticketHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 8, color: themeColor)),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['spaceName'] ?? 'SPACE TICKET',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'manru',
                        color: isCancelled ? Colors.grey : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text("${widget.data['date']} | ${widget.data['timeSlot']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const Spacer(),
                  Row(
                      children: List.generate(
                          30,
                          (index) => Expanded(
                              child: Container(
                                  color: index % 2 == 0
                                      ? Colors.transparent
                                      : Colors.grey[300],
                                  height: 1)))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                          children: List.generate(
                              16,
                              (index) => Container(
                                  width: index % 3 == 0 ? 1 : 3,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 3),
                                  color: isCancelled
                                      ? Colors.grey
                                      : Colors.black87))),
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
            // 🔥 도장 표시 (모든 상태에 표시!)
            Positioned(
              top: 40,
              right: 30,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: themeColor.withValues(alpha: .5), width: 3),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    status == 'pending'
                        ? "대기중"
                        : status == 'confirmed'
                            ? "수락됨"
                            : status == 'completed'
                                ? "사용완료"
                                : "취소됨",
                    style: TextStyle(
                        color: themeColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide(String? status) {
    Color statusColor = Colors.grey;
    String statusText = "";

    if (status == 'pending') {
      statusColor = Colors.orange;
      statusText = "대기중";
    } else if (status == 'confirmed') {
      statusColor = Colors.blue;
      statusText = "확정됨";
    } else if (status == 'completed') {
      statusColor = Colors.green;
      statusText = "사용완료";
    } else if (status == 'cancelled' || status == 'rejected') {
      statusColor = Colors.grey;
      statusText = "취소됨";
    }

    return ClipPath(
      clipper: TicketClipper(),
      child: Container(
        height: _ticketHeight, // 높이 160으로 줄임
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (status == 'pending') ...[
              const Icon(Icons.warning_amber_rounded,
                  size: 36, color: Colors.orange), // 아이콘 크기 약간 축소
              const SizedBox(height: 8),
              const Text("예약을 취소하시겠습니까?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                // 버튼 크기 조절을 위해 SizedBox 사용
                height: 36,
                child: ElevatedButton(
                  onPressed: _cancelReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text("예약 취소하기",
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              )
            ] else if (status == 'completed') ...[
              // 완료 상태일 때 뒷면 로직 추가
              const Icon(Icons.rate_review_outlined,
                  size: 36, color: Colors.green),
              const SizedBox(height: 8),
              const Text("이용이 완료되었습니다.",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    // 카드를 다시 뒤집고
                    _flipCard();
                    // 전달받은 콜백 함수 실행 (리뷰 탭으로 이동)
                    if (widget.onReviewTap != null) {
                      widget.onReviewTap!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text("리뷰 작성하러 가기",
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              )
            ] else ...[
              // 기존 로직 (확정됨, 취소됨 등)
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 80,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data['spaceName'] ?? 'Unknown Space',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'manru',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${widget.data['date']} | ${widget.data['timeSlot']}",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}

class ReviewActionItem extends StatefulWidget {
  final Map<String, dynamic> reservationData;
  const ReviewActionItem({super.key, required this.reservationData});

  @override
  State<ReviewActionItem> createState() => _ReviewActionItemState();
}

class _ReviewActionItemState extends State<ReviewActionItem> {
  final TextEditingController _reviewController = TextEditingController();
  bool _isEditing = false;
  int _rating = 5;
  String? _reviewId;
  Map<String, dynamic>? _existingReview;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('reservationDocId', isEqualTo: widget.reservationData['docId'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;
        final hasReview = docs.isNotEmpty;

        if (hasReview) {
          _existingReview = docs.first.data() as Map<String, dynamic>;
          _reviewId = docs.first.id;
        } else {
          _existingReview = null;
          _reviewId = null;
        }

        return Container(
          decoration: BoxDecoration(
            color: hasReview ? const Color(0xFFFFF9C4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(2, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: hasReview
                      ? const Color(0xFFFDD835)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(hasReview ? Icons.rate_review : Icons.edit_note,
                        size: 18, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.reservationData['spaceName'] ?? 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      widget.reservationData['date'] ?? '',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    )
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 16), // 👈 상단 8로 줄임!
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEditing && !hasReview)
                      Column(
                        children: [
                          const Text("어땠나요? 솔직한 후기를 남겨주세요!",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                                _reviewController.clear();
                                _rating = 5;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 0),
                            child: const Text("✨ 리뷰 작성하기"),
                          ),
                        ],
                      )
                    else if (!_isEditing && hasReview)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(Icons.star_rounded,
                                      size: 22,
                                      color:
                                          i < (_existingReview!['rating'] ?? 5)
                                              ? Colors.orange
                                              : Colors.grey[300]),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 28, color: Colors.blue),
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                        _reviewController.text =
                                            _existingReview!['content'];
                                        _rating = _existingReview!['rating'];
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 28, color: Colors.red),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('reviews')
                                          .doc(_reviewId)
                                          .delete();
                                      await FirebaseFirestore.instance
                                          .collection('reservations')
                                          .doc(widget.reservationData['docId'])
                                          .update({'hasReview': false});
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 4), // 👈 별점-텍스트 간격 4로!
                          Text(_existingReview!['content'] ?? '',
                              style:
                                  const TextStyle(fontSize: 15, height: 1.5)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _rating = index + 1),
                                child: Icon(
                                    index < _rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: Colors.orange,
                                    size: 36),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _reviewController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "여기에 내용을 입력하세요...",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isEditing = false),
                                child: const Text("취소",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_reviewController.text.isEmpty) return;
                                  final data = {
                                    'userId':
                                        FirebaseAuth.instance.currentUser!.uid,
                                    'reservationDocId':
                                        widget.reservationData['docId'],
                                    'spaceName':
                                        widget.reservationData['spaceName'],
                                    'content': _reviewController.text,
                                    'rating': _rating,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };

                                  if (_reviewId == null) {
                                    await FirebaseFirestore.instance
                                        .collection('reviews')
                                        .add(data);
                                    await FirebaseFirestore.instance
                                        .collection('reservations')
                                        .doc(widget.reservationData['docId'])
                                        .update({'hasReview': true});
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('reviews')
                                        .doc(_reviewId)
                                        .update(data);
                                  }
                                  setState(() => _isEditing = false);
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white),
                                child: const Text("완료"),
                              ),
                            ],
                          )
                        ],
                      )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.addOval(Rect.fromCircle(
      center: Offset(0.0, size.height * 0.7),
      radius: 10.0,
    ));
    path.addOval(Rect.fromCircle(
      center: Offset(size.width, size.height * 0.7),
      radius: 10.0,
    ));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
