// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 👇 최근 예약 기록을 가져오는 StreamBuilder를 반환하는 메서드
  Widget _buildRecentReservation(String userId) {
    return StreamBuilder<QuerySnapshot>(
      // 1. reservations 컬렉션에서 현재 userId와 일치하는 문서를 조회
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          // 2. 예약 시작 시간(startTime)을 기준으로 내림차순 정렬 (가장 최근 예약이 맨 위로)
          .orderBy('startTime', descending: true)
          .limit(1) // 3. 가장 최근 기록 1개만 가져옴
          .snapshots(),
      builder: (context, snapshot) {
        // 로딩 중이거나 데이터 오류 시 기본 Card 반환
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(top: 10),
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.orange),
              title: Text("예약 기록을 불러오는 중..."),
            ),
          );
        }

        // 데이터가 없거나 오류 발생 시 기본 메시지 반환
        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty ||
            snapshot.hasError) {
          return const Card(
            margin: EdgeInsets.only(top: 10),
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.orange),
              title: Text("최근 예약 기록이 없습니다."),
            ),
          );
        }

        // 데이터가 있을 경우: 가장 최근 예약 기록
        final reservation =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;

        // 날짜/시간 포맷팅
        // Firestore의 Timestamp를 DateTime 객체로 변환
        final Timestamp startTimeStamp = reservation['startTime'] as Timestamp;
        final DateTime startTime = startTimeStamp.toDate();
        final String formattedTime =
            '${startTime.month}월 ${startTime.day}일 ${startTime.hour}시';

        return Card(
          margin: const EdgeInsets.only(top: 10),
          color: Colors.lightGreen[50], // 예약이 있다는 시각적 강조
          child: ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.green),
            // 예약한 공간의 이름 표시 (reservation 문서 내 spaceName 필드가 있다고 가정)
            title: Text(reservation['spaceName'] ?? '예약된 공간',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("예약일시: $formattedTime"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 💡 여기를 탭하면 예약 상세 화면(필요 시)으로 이동하도록 로직 추가 가능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('예약 상세 정보 화면은 추후 구현 예정입니다')),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final userId = user?.uid; // 현재 로그인된 사용자의 UID (예약 조회에 사용)

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
            // 환영 메시지
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

            // 최근 예약한 강의실 (수정된 부분)
            const Text("최근 예약한 강의실",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

            // 💡 _buildRecentReservation 메서드 호출
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

            // 공간 목록 헤더
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

            // 👇 Firebase 공간 목록 (이전 클릭 오류 수정된 버전 유지)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('spaces').snapshots(),
                builder: (context, snapshot) {
                  // 로딩, 에러, 데이터 없음 처리 로직... (생략)
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('오류 발생: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('등록된 공간이 없습니다'));
                  }

                  // 데이터 표시
                  final spaces = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: spaces.length,
                    itemBuilder: (context, index) {
                      final spaceDoc = spaces[index];
                      final space = spaceDoc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            // 상세 화면으로 이동 (DetailScreen 진입)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(space: space),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // 이미지
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    space['image'] ??
                                        space['mainImageUrl'] ??
                                        '',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child:
                                            const Icon(Icons.image, size: 40),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // 정보
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
                                          const Icon(Icons.location_on,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              space['location'] ?? '위치 미정',
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
                                              size: 14, color: Colors.grey),
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

                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
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
          // 챗봇 기능 연결 예정
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('챗봇은 추후 구현 예정입니다')),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}
