import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  // MapScreen에서 검색어와 필터(인원수)를 받기 위해 변수를 추가합니다.
  final String? initialQuery;
  final int minCapacity; // 최소 수용 인원 필터

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.minCapacity = 0, // 기본값은 0명
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  late final bool _isInitialFilterActive;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchText = widget.initialQuery!;
      _searchController.text = widget.initialQuery!;
      _isInitialFilterActive = true;
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
          autofocus: !_isInitialFilterActive,
          decoration: const InputDecoration(
            hintText: "강의실 이름 검색 (예: 컨퍼런스룸)",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black, fontFamily: 'manru'),
          onChanged: (value) {
            setState(() {
              _searchText = value;
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

            // 인원수 필터링
            String rawCapacity = (data['capacity'] ?? '0').toString();
            String capacityOnlyNumber =
                rawCapacity.replaceAll(RegExp(r'[^0-9]'), '');
            int capacity = int.tryParse(capacityOnlyNumber) ?? 0;

            if (capacity < widget.minCapacity) {
              return false;
            }

            // 검색어 필터링
            if (searchLower.isEmpty) {
              return true;
            }

            if (_isInitialFilterActive &&
                _searchController.text == widget.initialQuery) {
              return location.contains(searchLower);
            }

            return name.contains(searchLower) || location.contains(searchLower);
          }).toList();

          if (docs.isEmpty) {
            final emptyMessage = _isInitialFilterActive
                ? "${widget.initialQuery}에 등록된 공간이 없습니다."
                : "조건에 맞는 검색 결과가 없습니다.";

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

              String rawCapacity = (data['capacity'] ?? '0').toString();
              String displayCapacity =
                  rawCapacity.replaceAll(RegExp(r'[^0-9]'), '');

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),

                  // 🔥 [수정됨] 이미지 표시 부분 (인터넷 vs 로컬 구분)
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
                            child: data['image'].startsWith('http')
                                ? Image.network(
                                    data['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                          child: Icon(Icons.broken_image,
                                              color: Colors.grey));
                                    },
                                  )
                                : Image.asset(
                                    data['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                          child: Icon(Icons.image_not_supported,
                                              color: Colors.grey));
                                    },
                                  ),
                          )
                        : const Icon(Icons.meeting_room, color: Colors.grey),
                  ),

                  title: Text(
                    data['name'] ?? '이름 없음',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "${data['location'] ?? '-'} | $displayCapacity명",
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
