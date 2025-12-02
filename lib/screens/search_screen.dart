// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  // MapScreen에서 검색어를 받기 위해 인수를 추가합니다.
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  late final bool _isInitialFilterActive; // 초기 필터 상태를 저장

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchText = widget.initialQuery!;
      _searchController.text = widget.initialQuery!;
      _isInitialFilterActive = true; // 초기 쿼리가 있으면 필터 활성화
    } else {
      _isInitialFilterActive = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: TextField(
          controller: _searchController,
          autofocus: !_isInitialFilterActive, // 초기 필터 활성화 시 자동 포커스 끄기
          decoration: const InputDecoration(
            hintText: "강의실 이름 검색 (예: 컨퍼런스룸)",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black, fontFamily: 'manru'),
          onChanged: (value) {
            setState(() {
              _searchText = value;
              // 사용자가 텍스트를 건드리면 초기 필터 상태는 해제됩니다.
              // _isInitialFilterActive = false; // 이 로직은 StreamBuilder 내부에서 처리
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchText = "";
                // 검색창을 지우면 전체 목록을 보여주기 위해 필터 해제 상태로 간주
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('spaces').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("오류 발생"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("등록된 공간이 없습니다."));
          }

          final searchLower = _searchText.toLowerCase();

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'].toString().toLowerCase();
            final location = data['location'].toString().toLowerCase();

            // 🌟 [수정된 필터링 로직]

            // 1. 검색어가 비어 있으면 모든 문서를 반환 (가장 넓은 범위의 '전체 보기')
            if (searchLower.isEmpty) {
              return true;
            }

            // 2. 초기 쿼리 (건물 이름)가 현재 검색 텍스트와 같고, 사용자가 텍스트를 수정하지 않은 상태라면
            //    -> 이 경우는 'ㅇㅇ관 전체 공간 보기' 링크를 눌렀을 때이며, **위치(location)에만 필터를 적용**합니다.
            if (_isInitialFilterActive &&
                _searchController.text == widget.initialQuery) {
              return location.contains(searchLower);
            }

            // 3. 그 외의 경우 (사용자가 능동적으로 검색어를 입력/수정했을 때)
            //    -> 이름 또는 위치에 검색어가 포함될 경우 true 반환 (일반적인 검색)
            return name.contains(searchLower) || location.contains(searchLower);
          }).toList();

          if (docs.isEmpty) {
            // 초기 쿼리가 적용된 상태라면 "검색 결과" 대신 "해당 건물에 등록된 공간" 메시지 표시
            final emptyMessage = _isInitialFilterActive
                ? "${widget.initialQuery}에 등록된 공간이 없습니다."
                : "검색 결과가 없습니다.";

            return Center(child: Text(emptyMessage));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final spaceData = Map<String, dynamic>.from(data);
              spaceData['docId'] = doc.id;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: data['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                Image.network(data['image'], fit: BoxFit.cover),
                          )
                        : const Icon(Icons.meeting_room, color: Colors.grey),
                  ),
                  title: Text(
                    data['name'] ?? '이름 없음',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "${data['location'] ?? '-'} | ${data['capacity'] ?? '-'}명",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(space: spaceData),
                      ),
                    );
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
