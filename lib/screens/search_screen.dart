// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("검색 결과"),
      ),
      // DB와 연결된거
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('spaces').snapshots(),
        builder: (context, snapshot) {
          // 1. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. 데이터 없음
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("조건에 맞는 공간이 없습니다."));
          }

          // 3. 데이터 도착! 리스트 만들기
          final spaces = snapshot.data!.docs;

          return ListView.builder(
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              var space = spaces[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.meeting_room, size: 40, color: Colors.blue),
                  title: Text(space['name'] ?? '이름 없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${space['location']} | 수용 ${space['capacity']}명"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(space: space),
                      ),
                    );  // ontap
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}