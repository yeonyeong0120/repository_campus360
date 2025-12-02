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
  //   return ListTile(
  //     contentPadding: EdgeInsets.zero,
  //     leading: CircleAvatar(
  //       backgroundColor: Colors.blue[50],
  //       child: Text(floor, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
  //     ),
  //     title: Text(description),
  //     trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
  //     onTap: () {
  //       // 특정 층을 눌러도 검색 화면으로 이동
  //       Navigator.pop(context);
  //       Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // 🌟 배경을 앱 표준색으로 통일
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
                        cacheWidth: 1000,
                      ),

                      // 1-2. 건물 핀 배치 // 픽셀좌표 그림판에서 볼수잇숨
                      _buildMapPin(2225, 500, "하이테크관"),
                      _buildMapPin(1162, 496, "대학 본관"),
                      _buildMapPin(2040, 1632, "1기술관"),
                      _buildMapPin(1600, 1050, "2기술관"),
                      _buildMapPin(1830, 700, "3기술관"),
                      _buildMapPin(200, 1200, "5기술관"),
                      _buildMapPin(1450, 700, "6기술관"),
                      _buildMapPin(1980, 349, "7기술관"),
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
  // 핀 디자인을 만드는 함수 (원래 디자인으로 복원)
  Widget _buildMapPin(double x, double y, String name) {
    return Align(
      // 화면 크기가 변해도 핀 위치가 지도상의 정확한 곳에 고정됩니다.
      alignment: FractionalOffset(x / mapWidth, y / mapHeight),
      child: GestureDetector(
        onTap: () => _showBuildingDetail(name),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 핀 크기만큼만 차지하게
          children: [
            const Icon(Icons.location_on_rounded,
                color: Colors.redAccent, size: 25), // 🌟 원래 빨간색으로 복원
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(.2), // opacity를 직접 설정
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 8)),
            ),
          ],
        ),
      ),
    );
  }

  // 건물 상세 정보창 (🌟 [수정] 대표 추천 강의실만 노출 및 데이터 전달)
  void _showBuildingDetail(String buildingName) {
    // 1. 층별 강의실 데이터 정의 (사용자 데이터 반영)
    final Map<String, List<Map<String, dynamic>>> buildingData = {
      "하이테크관": [
        {
          'floor': '3F',
          'rooms': ['디지털데이터활용실습실', '강의실 2']
        },
        {
          'floor': '2F',
          'rooms': ['컨퍼런스룸']
        },
      ],
      "1기술관": [
        {
          'floor': '2F',
          'rooms': ['CAD실습실', '콘트롤러실습실']
        },
      ],
      "2기술관": [
        {
          'floor': '3F',
          'rooms': ['자동차과이론강의실', 'PLC실습실']
        },
        {
          'floor': '2F',
          'rooms': ['자동차과이론강의실', 'CAD/CAE실']
        },
        {
          'floor': '1F',
          'rooms': ['CATIA실습실', '전기자동차실습실', '자동차과이론강의실']
        },
      ],
      "3기술관": [
        {
          'floor': '1F',
          'rooms': ['아이디어 존']
        },
      ],
      "5기술관": [
        {
          'floor': '4F',
          'rooms': [
            '시제품창의개발실',
            '아이디어카페',
            '디자인워크샵실습실',
            '융합디자인실습실',
            '디지털디자인실습실',
            '미디어창작실습실'
          ]
        },
        {
          'floor': '3F',
          'rooms': ['강의실', '스터디룸', '반도체제어실', '전자CAD실', '기초전자실습실']
        },
        {
          'floor': '2F',
          'rooms': ['AI융합프로젝트실습실', '인공지능프로그래밍실습실', 'ioT제어실습실']
        },
        {
          'floor': '1F',
          'rooms': ['개인미디어실', '세미나실', '미디어편집실', 'AR그래픽실', '실감형콘텐츠운영실습실']
        },
      ],
      "6기술관": [
        {
          'floor': '1F',
          'rooms': ['건축설계과']
        },
      ],
      "7기술관": [
        {
          'floor': '3F',
          'rooms': ['소그룹실', '강의실', '반도체 시스템 제작실']
        },
      ],
      "대학 본관": [
        {
          'floor': '1F',
          'rooms': ['로비', '행정실']
        },
      ],
    };

    final floors = buildingData[buildingName] ?? [];

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
                  Text(buildingName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // 층별 안내
              const Text("층별 안내",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),

              // 🌟 [수정] 대표 강의실만 ListTile로 보여주고 데이터 전달
              ...floors.map((floorData) {
                final floor = floorData['floor'] as String;
                final rooms = floorData['rooms'] as List<String>;
                // 첫 번째 방을 추천 방으로 지정
                final recommendedRoom = rooms.first;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: Text(floor,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)),
                  ),
                  // 🌟 [추천 기능] 첫 번째 방만 (추천) 텍스트와 함께 표시
                  title: Text("$recommendedRoom (추천)"),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                  onTap: () {
                    // 🌟 [수정] 추천 방 이름과 건물 이름을 쿼리로 전달
                    Navigator.pop(context); // 모달 닫기
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SearchScreen(
                                initialQuery: recommendedRoom))); // 이동!
                  },
                );
              }),

              const SizedBox(height: 20),

              // 전체 보기 버튼 (🌟 [수정] 건물 이름을 쿼리로 전달)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 🌟 [수정] 건물 이름을 쿼리로 전달하여 해당 건물의 모든 강의실 검색 유도
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                SearchScreen(initialQuery: buildingName)));
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

  // 바텀 시트 보여주는 메서드 (기존과 동일)
  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                      const Text("필터로 찾아보기",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 필터 칩들
                  const Row(children: [
                    Chip(
                        label: Text("Wi-Fi"),
                        backgroundColor: Colors.blue,
                        labelStyle: TextStyle(color: Colors.white)),
                    SizedBox(width: 10),
                    Chip(label: Text("빔프로젝터")),
                  ]),
                  const SizedBox(height: 20),
                  const Text("인원 선택",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _peopleCount,
                    min: 0,
                    max: 50,
                    divisions: 5,
                    label: "${_peopleCount.round()}명",
                    onChanged: (val) => setModalState(() => _peopleCount = val),
                  ),
                  const Spacer(),
                  // 결과 보기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // 창 닫기
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SearchScreen())); // 이동!
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text("검색 결과 보기",
                          style: TextStyle(fontSize: 18)),
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
