// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'search_screen.dart'; // 검색결과랑 연결

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _peopleCount = 10.0; // 인원수 슬라이더 값
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도에서 찾기"),
        actions: [
          // 필터 아이콘
          IconButton(
            icon: const Icon(Icons.filter_list_alt), 
            onPressed: () => _showFilterModal(context), // 바텀 시트 열기
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 지도 배경 (회색)
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text("지도 이미지 영역", style: TextStyle(color: Colors.grey)),
            ),
          ),
          // 2. 핀 예시
          const Positioned(
            top: 200, left: 100,
            child: Column(children: [
              Icon(Icons.location_on, color: Colors.red, size: 40),
              Text("하이테크관", style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  // 바텀 시트(필터) 보여주는 메서드
  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 450, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("필터로 찾아보기", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 필터 칩들
                  const Row(children: [
                     Chip(label: Text("Wi-Fi"), backgroundColor: Colors.blue, labelStyle: TextStyle(color: Colors.white)),
                     SizedBox(width: 10),
                     Chip(label: Text("빔프로젝터")),
                  ]),
                  const SizedBox(height: 20),
                  const Text("인원 선택", style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _peopleCount, min: 0, max: 50, divisions: 5, label: "${_peopleCount.round()}명",
                    onChanged: (val) => setModalState(() => _peopleCount = val),
                  ),
                  const Spacer(),
                  // 결과 보기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // 창 닫기
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())); // 이동!
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text("검색 결과 보기", style: TextStyle(fontSize: 18)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}