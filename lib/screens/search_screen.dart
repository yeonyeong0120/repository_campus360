import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.initialQuery,
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
            final name = (data['name'] ?? '').toString().toLowerCase();
            final location = (data['location'] ?? '').toString().toLowerCase();

            // 🔥 건물명 필터 (initialQuery가 있을 때)
            if (_isInitialFilterActive && widget.initialQuery != null) {
              final queryLower = widget.initialQuery!.toLowerCase();
              return location.contains(queryLower);
            }

            // 검색어가 비어 있으면 모두 표시
            if (searchLower.isEmpty) {
              return true;
            }

            // 일반 검색 (이름 또는 위치에 검색어 포함)
            return name.contains(searchLower) || location.contains(searchLower);
          }).toList();

          if (docs.isEmpty) {
            final emptyMessage =
                _isInitialFilterActive && widget.initialQuery != null
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
                    "${data['location'] ?? '-'} | ${displayCapacity}명",
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
