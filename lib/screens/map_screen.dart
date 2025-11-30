// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'search_screen.dart'; // 검색결과랑 연결

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _peopleCount = 10.0; // 인원수 슬라이더용 변수

  // 지도 원본 크기 저장용
  final double mapWidth = 2304.0;
  final double mapHeight = 1856.0;

  // 층별 리스트 아이템 디자인
  // Widget _buildFloorTile(String floor, String description) {
  //   return ListTile(
  //     contentPadding: EdgeInsets.zero,
  //     leading: CircleAvatar(
  //       backgroundColor: Colors.blue[50],
  //       child: Text(floor, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
  //     ),
  //     title: Text(description),
  //     trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
  //     onTap: () {
  //       // 특정 층을 눌러도 검색 화면으로 이동
  //       Navigator.pop(context);
  //       Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
  //     },
  //   );
  // }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("캠퍼스 맵")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentGeometry.topCenter,
            end: AlignmentGeometry.bottomCenter,
            colors: [
              Color.fromARGB(255, 165, 243, 255), // 매우 진한 파랑 (위쪽)
              Color.fromARGB(255, 193, 224, 241), // 조금 밝은 파랑 (아래쪽)
              // 또는 원하시는 다른 색상 코드를 넣으셔도 됩니다.
            ],
          ),
        ),
        child: Stack(
          children: [
            // 확대/축소 지도 영역 // InteractiveViewer
            InteractiveViewer(
              minScale: 1.0, // 최소 1배
              maxScale: 5.0, // 최대 5배까지 확대
              child: Center(
                child: AspectRatio(
                  aspectRatio: mapWidth / mapHeight, // 비율을 고정
                  child: Stack(
                    children: [
                      // 1-1. 지도 이미지
                      Image.asset(
                        'assets/images/campusMap.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
        
                      // 1-2. 건물 핀 배치 // 픽셀좌표 그림판에서 볼수잇숨
                      _buildMapPin(2088, 489, "하이테크관"),                    
                      _buildMapPin(1162, 496, "대학 본관"),
                    ],
                  ),
                ),
              ),
            ),
        
            // 필터 버튼
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color.fromARGB(255, 22, 54, 109),
                onPressed: () => _showFilterModal(context), // 기존 필터 함수 연결
                child: const Icon(Icons.filter_alt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //-------------메서드 모음들--------///
  // 핀 디자인을 만드는 함수
  Widget _buildMapPin(double x, double y, String name) {
    return Align(
      // 화면 크기가 변해도 핀 위치가 지도상의 정확한 곳에 고정됩니다.
      alignment: FractionalOffset(x / mapWidth, y / mapHeight),
      child: GestureDetector(
        onTap: () => _showBuildingDetail(name),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 핀 크기만큼만 차지하게
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 25),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .2), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
            ),
          ],
        ),
      ),
    );
  }

  // 건물 상세 정보창
  void _showBuildingDetail(String buildingName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용물만큼만 높이 차지
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(buildingName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // 층별 안내 (예시 데이터)
              const Text("층별 안내", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              
              // 리스트타일로 층 정보 표시
              ListTile(
                leading: const CircleAvatar(child: Text("1F", style: TextStyle(fontSize: 12))),
                title: const Text("로비, 행정실"),
              ),
              ListTile(
                leading: const CircleAvatar(child: Text("3F", style: TextStyle(fontSize: 12))),
                title: const Text("디지털데이터활용실습실 (추천)"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  // 3층을 누르면 바로 검색 결과 화면으로 이동!
                  Navigator.pop(context); // 창 닫고
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                },
              ),
              
              const SizedBox(height: 20),
              
              // 전체 보기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const SearchScreen())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text("$buildingName 전체 공간 보기"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 바텀 시트 보여주는 메서드
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