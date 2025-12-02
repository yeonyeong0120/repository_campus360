// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repository_campus360/screens/chatbot_sheet.dart';
// import 'package:intl/intl.dart'; // 사용되지 않아 제거됨
import '../providers/user_provider.dart';
import 'login_screen.dart';
// 🌟 [최종 수정] 상대 경로 대신 절대 경로(Package Path)로 강제 지정
import 'package:repository_campus360/screens/reservation_detail_screen.dart';
import 'reservation_screen.dart';
import 'my_history_screen.dart';
import 'map_screen.dart'; // 🌟 [필수] 지도 화면 연결을 위해 추가

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> spaces = [
    {
      "name": "컨퍼런스룸",
      "location": "하이테크관 2F",
      "capacity": "20명",
      "image": null,
    },
    {
      "name": "디지털데이터활용실습실",
      "location": "하이테크관 3F",
      "capacity": "20명",
      "image": null,
    },
    {
      "name": "강의실 2",
      "location": "하이테크관 3F",
      "capacity": "30명",
      "image": null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserProvider>().currentUser;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // 🌟 [수정] SingleChildScrollView 제거 -> 화면 고정!
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------
              // 🎨 [1. 상단 헤더]
              // ---------------------------------------------------------
              Stack(
                children: [
                  Container(
                    height: size.height * 0.30,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "한국폴리텍대학",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'manru',
                                    ),
                                  ),
                                  Text(
                                    "인천캠퍼스",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'manru',
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.menu,
                                      color: Colors.white),
                                  onPressed: () {
                                    // 🌟 [수정 완료] 메뉴 버튼 누르면 마이페이지(MyHistoryScreen)로 이동!
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const MyHistoryScreen()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Text(
                            "안녕하세요, ${userModel?.name ?? '게스트'}님! 🌱",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'manru',
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              userModel?.department ?? "소속 없음",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'manru',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ---------------------------------------------------------
              // 🎨 [2. 본문 컨텐츠] (Expanded로 남은 공간 채움)
              // ---------------------------------------------------------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "최근 예약한 강의실",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                          fontFamily: 'manru',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🌟 [최근 예약 카드]
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: userModel == null
                              ? const Stream.empty()
                              : FirebaseFirestore.instance
                                  .collection('reservations')
                                  .where('userId', isEqualTo: userModel.uid)
                                  .orderBy('createdAt', descending: true)
                                  .limit(10)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                    child: Text("데이터 로드 오류",
                                        style: TextStyle(
                                            color: Colors.grey[500]))),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))),
                              );
                            }

                            QueryDocumentSnapshot? activeReservation;
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                if (data['status'] != 'cancelled') {
                                  activeReservation = doc;
                                  break;
                                }
                              }
                            }

                            if (activeReservation == null) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  children: [
                                    Icon(Icons.history_toggle_off,
                                        size: 30, color: Colors.grey[300]),
                                    const SizedBox(height: 8),
                                    Text(
                                      "최근 예약 기록이 없습니다.",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                        fontFamily: 'manru',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final doc = activeReservation;
                            final data = doc.data() as Map<String, dynamic>;
                            final reservationData =
                                Map<String, dynamic>.from(data);
                            reservationData['docId'] = doc.id;

                            final spaceName =
                                reservationData['spaceName'] ?? '알 수 없음';
                            final date = reservationData['date'] ?? '-';
                            final timeSlot = reservationData['timeSlot'] ?? '-';

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  // 🌟 [Navigation] ReservationDetailScreen 호출 (문제 라인)
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReservationDetailScreen(
                                        reservation: reservationData,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_circle,
                                            color: Colors.blue, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              spaceName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                                fontFamily: 'manru',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "$date | $timeSlot",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontFamily: 'manru',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right,
                                          color: Colors.grey[400]),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "이용 가능한 공간",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                              fontFamily: 'manru',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // 🌟 [기능 복구] 지도 화면(MapScreen)으로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MapScreen()),
                              );
                            },
                            child: const Text(
                              "지도에서 보기 →",
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'manru',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 🌟 남은 공간에 리스트 표시 (스크롤 없이 고정된 공간에 꽉 차게)
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          // 🌟 [수정] 스크롤 없애기 (NeverScrollableScrollPhysics 적용)
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ...spaces.map((space) => _buildSpaceCard(space)),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // 전체 화면 높이 사용 가능하게
                  backgroundColor: Colors.transparent, // 배경 투명 (둥근 모서리 위해)
                  builder: (context) => const ChatbotSheet(),
                );
              },
              backgroundColor: const Color(0xFF2196F3),
              child:
                  const Icon(Icons.question_mark_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceCard(Map<String, dynamic> space) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationScreen(space: space),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: space['image'] != null
                      ? Image.asset(space['image'], fit: BoxFit.cover)
                      : Icon(Icons.image_outlined, color: Colors.grey[400]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'manru',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            space['location'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontFamily: 'manru',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.people_outline,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            "수용 인원: ${space['capacity']}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontFamily: 'manru',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 🌟 [수정] 별표 삭제 & 화살표 가운데 정렬
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
