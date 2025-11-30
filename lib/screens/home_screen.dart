// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'detail_screen.dart';
import 'reservation_detail_screen.dart';
import 'chatbot_sheet.dart'; // 챗봇

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
          return const Card(
            margin: EdgeInsets.only(top: 10),
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.orange),
              title: Text("예약 기록을 불러오는 중..."),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const Card(
            margin: EdgeInsets.only(top: 10),
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.orange),
              title: Text("최근 예약 기록이 없습니다."),
            ),
          );
        }

        final validReservations = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          return status != 'cancelled';
        }).toList();

        if (validReservations.isEmpty) {
          return const Card(
            margin: EdgeInsets.only(top: 10),
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.orange),
              title: Text("최근 예약 기록이 없습니다."),
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

        return Card(
          margin: const EdgeInsets.only(top: 10),
          color: Colors.lightGreen[50],
          child: ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.green),
            title: Text(reservation['spaceName'] ?? '예약된 공간',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("예약일시: $formattedTime"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
            content: Text(isFavorite ? '찜 목록에서 제거되었습니다.' : '찜 목록에 추가되었습니다.'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('찜 기능 처리 오류: $e')),
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
      appBar: AppBar(
        title: const Text("Smart Campus 360"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<UserProvider>().clearUser();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "안녕하세요, ${user?.name ?? '학우'}님! 🌱",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Text(
                    user?.department != null
                        ? "${user!.department} 전공"
                        : "소속 미정",
                    style:
                        const TextStyle(fontSize: 16, color: Colors.blueGrey)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("최근 예약한 강의실",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (userId != null)
              _buildRecentReservation(userId)
            else
              const Card(
                margin: EdgeInsets.only(top: 10),
                child: ListTile(
                  leading: Icon(Icons.history, color: Colors.orange),
                  title: Text("로그인 정보가 없어 기록을 볼 수 없습니다."),
                ),
              ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("이용 가능한 공간",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MapScreen()));
                  },
                  child: const Text("지도에서 보기 →"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: userId == null
                  ? const Center(child: Text('로그인이 필요합니다'))
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
                        if (userSnapshot.hasData && userSnapshot.data != null) {
                          final userData = userSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          if (userData != null &&
                              userData['favoriteSpaces'] != null) {
                            userFavorites =
                                List<String>.from(userData['favoriteSpaces']);
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
                              return const Center(child: Text('등록된 공간이 없습니다'));
                            }

                            final spaces = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: spaces.length,
                              itemBuilder: (context, index) {
                                final spaceDoc = spaces[index];
                                final space =
                                    spaceDoc.data() as Map<String, dynamic>;
                                final spaceId = spaceDoc.id;

                                final isFavorite =
                                    userFavorites.contains(spaceId);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetailScreen(space: space),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              space['image'] ??
                                                  space['mainImageUrl'] ??
                                                  '',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image,
                                                      size: 40),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  space['name'] ?? '이름 없음',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.location_on,
                                                        size: 14,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        space['location'] ??
                                                            '위치 미정',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.people,
                                                        size: 14,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '수용 인원: ${space['capacity'] ?? 0}명',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  isFavorite
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: isFavorite
                                                      ? Colors.amber
                                                      : Colors.grey,
                                                  size: 28,
                                                ),
                                                onPressed: () =>
                                                    _toggleFavorite(context,
                                                        spaceId, isFavorite),
                                              ),
                                              const SizedBox(height: 8),
                                              const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: Colors.grey),
                                            ],
                                          ),
                                        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 챗봇 바텀 시트
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // 화면 반 이상 올라오게...
            backgroundColor: Colors.transparent, // 배경 투명 (둥근 모서리 위해)
            builder: (context) => const ChatbotSheet(),
          );
        },
        child: const Icon(Icons.help_rounded),
      ),
    );
  }
}
