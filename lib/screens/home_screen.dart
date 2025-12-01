// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import 'map_screen.dart';
import 'detail_screen.dart';
import 'reservation_detail_screen.dart';
import 'chatbot_sheet.dart'; // 챗봇
import 'my_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 👇 최근 예약 기록 (실시간 업데이트)
  Widget _buildRecentReservation(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 🎨 디자인 수정: Card -> Container (스타일 통일)
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.orange),
                SizedBox(width: 12),
                Text("예약 기록을 불러오는 중...", style: TextStyle(fontFamily: 'manru')),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.orange),
                SizedBox(width: 12),
                Text("최근 예약 기록이 없습니다.", style: TextStyle(fontFamily: 'manru')),
              ],
            ),
          );
        }

        final validReservations = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          return status != 'cancelled';
        }).toList();

        if (validReservations.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.orange),
                SizedBox(width: 12),
                Text("최근 예약 기록이 없습니다.", style: TextStyle(fontFamily: 'manru')),
              ],
            ),
          );
        }

        // 👇 문서 자체를 저장
        final reservationDoc = validReservations.first;
        final reservation = reservationDoc.data() as Map<String, dynamic>;

        // 👇 문서 ID를 맵에 추가!
        final reservationWithId = {
          ...reservation,
          'docId': reservationDoc.id, // 👈 문서 ID 추가!
        };

        final Timestamp startTimeStamp = reservation['startTime'] as Timestamp;
        final DateTime startTime = startTimeStamp.toDate();
        final String formattedTime =
            '${startTime.month}월 ${startTime.day}일 ${startTime.hour}시';

        // 🎨 디자인 수정: 최근 예약 카드 (강조)
        return Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.2)), // 파란 테두리
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 10,
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
                  MaterialPageRoute(
                    builder: (_) => ReservationDetailScreen(
                      reservation: reservationWithId, // 👈 문서 ID 포함!
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_month,
                          color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation['spaceName'] ?? '예약된 공간',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'manru',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "예약일시: $formattedTime",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontFamily: 'manru',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(
      BuildContext context, String spaceId, bool isFavorite) async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final updateCommand = isFavorite
        ? FieldValue.arrayRemove([spaceId])
        : FieldValue.arrayUnion([spaceId]);

    try {
      await userRef.update({'favoriteSpaces': updateCommand});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFavorite ? '찜 목록에서 제거되었습니다.' : '찜 목록에 추가되었습니다.',
                style: const TextStyle(fontFamily: 'manru')),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('찜 기능 처리 오류: $e',
                  style: const TextStyle(fontFamily: 'manru'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;
    final userId = user?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      // 🎨 AppBar를 제거하고 커스텀 헤더를 사용하기 위해 Body를 Column으로 시작
      body: Column(
        children: [
          // 🎨 [디자인 추가] 로그인 화면과 통일된 파란색 곡선 헤더
          Container(
            padding: const EdgeInsets.only(
                left: 24, right: 24, bottom: 30, top: 60), // SafeArea 고려
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)], // 브랜드 컬러
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40), // 로그인화면보단 조금 완만하게
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎨 [요청 1] 멘트 수정: 360 제거하고 깔끔하게 'Smart Campus' (원하시면 변경 가능)
                    Text(
                      "Smart",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontFamily: 'manru',
                      ),
                    ),
                    Text(
                      "Campus",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'manru',
                      ),
                    ),
                  ],
                ),
                // 메뉴 버튼 (흰색으로 변경)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyHistoryScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🎨 본문 영역 (Expanded로 남은 공간 채우기)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // 🎨 [요청 2] 인삿말 한 줄로 변경 (\n 제거)
                  Text(
                    "안녕하세요, ${user?.name ?? '학우'}님! 🌱",
                    style: const TextStyle(
                        fontSize: 24, // 한 줄이니까 크기 살짝 조정 (26 -> 24)
                        fontWeight: FontWeight.bold,
                        fontFamily: 'manru',
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),

                  // 🎨 [요청 3] 전공 박스 위치 오른쪽으로 원복 (Alignment.centerRight)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user?.department != null
                            ? "${user!.department} 전공"
                            : "소속 미정",
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontFamily: 'manru'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text("최근 예약한 강의실",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'manru')),
                  if (userId != null)
                    _buildRecentReservation(userId)
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.history, color: Colors.orange),
                          SizedBox(width: 12),
                          Text("로그인 정보가 없어 기록을 볼 수 없습니다.",
                              style: TextStyle(fontFamily: 'manru')),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("이용 가능한 공간",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'manru')),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MapScreen()));
                        },
                        child: const Text("지도에서 보기 →",
                            style: TextStyle(
                                fontFamily: 'manru',
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: userId == null
                        ? const Center(
                            child: Text('로그인이 필요합니다',
                                style: TextStyle(fontFamily: 'manru')))
                        : StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              List<String> userFavorites = [];
                              if (userSnapshot.hasData &&
                                  userSnapshot.data != null) {
                                final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                                if (userData != null &&
                                    userData['favoriteSpaces'] != null) {
                                  userFavorites = List<String>.from(
                                      userData['favoriteSpaces']);
                                }
                              }

                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('spaces')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('오류 발생: ${snapshot.error}'),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Center(
                                        child: Text('등록된 공간이 없습니다',
                                            style: TextStyle(
                                                fontFamily: 'manru')));
                                  }

                                  final spaces = snapshot.data!.docs;

                                  return ListView.builder(
                                    // 🎨 [요청 4 해결] 하단 여백을 넉넉히(100) 주어 FAB에 가려지는 문제 해결
                                    padding: const EdgeInsets.only(bottom: 100),
                                    itemCount: spaces.length,
                                    itemBuilder: (context, index) {
                                      final spaceDoc = spaces[index];
                                      final space = spaceDoc.data()
                                          as Map<String, dynamic>;
                                      final spaceId = spaceDoc.id;

                                      final isFavorite =
                                          userFavorites.contains(spaceId);

                                      // 🎨 공간 리스트 아이템 디자인 개선
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: Colors.grey[100]!),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.08),
                                              spreadRadius: 1,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => DetailScreen(
                                                      space: space),
                                                ),
                                              );
                                            },
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image.network(
                                                      space['image'] ??
                                                          space[
                                                              'mainImageUrl'] ??
                                                          '',
                                                      width: 70, // 날렵하게
                                                      height: 70,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          width: 70,
                                                          height: 70,
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                              Icons.image,
                                                              size: 30,
                                                              color:
                                                                  Colors.grey),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          space['name'] ??
                                                              '이름 없음',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily: 'manru',
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                                Icons
                                                                    .location_on,
                                                                size: 14,
                                                                color: Colors
                                                                    .grey),
                                                            const SizedBox(
                                                                width: 4),
                                                            Expanded(
                                                              child: Text(
                                                                space['location'] ??
                                                                    '위치 미정',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .grey,
                                                                  fontFamily:
                                                                      'manru',
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                                Icons.people,
                                                                size: 14,
                                                                color: Colors
                                                                    .grey),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              '수용 인원: ${space['capacity'] ?? 0}명',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                                color:
                                                                    Colors.grey,
                                                                fontFamily:
                                                                    'manru',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        constraints:
                                                            const BoxConstraints(),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        icon: Icon(
                                                          isFavorite
                                                              ? Icons.star
                                                              : Icons
                                                                  .star_border,
                                                          color: isFavorite
                                                              ? Colors.amber
                                                              : Colors
                                                                  .grey[300],
                                                          size: 26,
                                                        ),
                                                        onPressed: () =>
                                                            _toggleFavorite(
                                                                context,
                                                                spaceId,
                                                                isFavorite),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      const Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                          size: 14,
                                                          color: Colors.grey),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2196F3), // 브랜드 컬러 적용
        onPressed: () {
          // 바텀 시트
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // 화면 반 이상 올라오게...
            backgroundColor: Colors.transparent, // 배경 투명 (둥근 모서리 위해)
            builder: (context) => const ChatbotSheet(),
          );
        },
        child: const Icon(Icons.help_rounded, color: Colors.white),
      ),
    );
  }
}
