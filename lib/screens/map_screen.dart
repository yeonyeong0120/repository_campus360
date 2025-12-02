// lib/screens/map_screen.dart
import 'dart:async'; // Completer
import 'package:google_maps_flutter/google_maps_flutter.dart'; // 구글맵 패키지
import 'package:flutter/material.dart';
import 'search_screen.dart'; // 검색결과랑 연결
import 'detail_screen.dart'; // 🌟 [필수] 상세 화면 연결

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 구글맵 컨트롤러 (지도를 코드로 움직일 때 사용)
  final Completer<GoogleMapController> _controller = Completer();

  // 🏫 학교 중심 좌표 (한국폴리텍대학 인천캠퍼스 본관 근처)
  static const CameraPosition _kSchoolCenter = CameraPosition(
    target: LatLng(37.5096, 126.7219), // 학교 중심 위도, 경도
    zoom: 17.5, // 줌 레벨 (숫자가 클수록 확대)
  );

  // 📍 마커(핀) 목록을 저장할 변수
  Set<Marker> _markers = {};

  // 필터용 변수 (기존 유지)
  double _peopleCount = 10.0;

  // 🌟 [데이터] 건물별 상세 정보 (기존 데이터 유지!)
  final Map<String, List<Map<String, dynamic>>> buildingData = {
    "하이테크관": [
      {'floor': '3F', 'rooms': ['디지털데이터활용실습실', '강의실 2']},
      {'floor': '2F', 'rooms': ['컨퍼런스룸']},
    ],
    "1기술관": [
      {'floor': '2F', 'rooms': ['CAD실습실', '콘트롤러실습실']},
    ],
    "5기술관": [
      {'floor': '3F', 'rooms': ['반도체제어실', '전자CAD실']},
      {'floor': '1F', 'rooms': ['개인미디어실', '세미나실']},
    ],
    "대학 본관": [
      {'floor': '1F', 'rooms': ['행정실', '학생식당']},
    ],
    // ... 나머지 건물 데이터도 여기에 추가 ...
  };

  @override
  void initState() {
    super.initState();
    _createMarkers(); // 앱 시작 시 마커 생성
  }

  // 📍 마커 생성 함수 (좌표는 구글맵에서 찍어서 확인 필요!)
  void _createMarkers() {
    setState(() {
      _markers = {
        // 1. 하이테크관 마커
        Marker(
          markerId: const MarkerId('hitech'),
          position: const LatLng(37.5093, 126.7225), // 📍 실제 좌표로 수정 필요
          infoWindow: const InfoWindow(title: '하이테크관'),
          onTap: () => _showBuildingDetail('하이테크관'),
        ),
        // 2. 5기술관 마커
        Marker(
          markerId: const MarkerId('tech5'),
          position: const LatLng(37.5088, 126.7215), // 📍 실제 좌표로 수정 필요
          infoWindow: const InfoWindow(title: '5기술관'),
          onTap: () => _showBuildingDetail('5기술관'),
        ),
        // 3. 대학 본관 마커
        Marker(
          markerId: const MarkerId('main_hall'),
          position: const LatLng(37.5100, 126.7218), // 📍 실제 좌표로 수정 필요
          infoWindow: const InfoWindow(title: '대학 본관'),
          onTap: () => _showBuildingDetail('대학 본관'),
        ),
        // ... 다른 건물 마커도 이렇게 추가 ...
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("캠퍼스 맵")),
      body: Stack(
        children: [
          // 🗺️ 구글맵 영역
          GoogleMap(
            mapType: MapType.normal, // 일반 지도 (satellite: 위성)
            initialCameraPosition: _kSchoolCenter, // 시작 위치
            markers: _markers, // 마커 표시
            zoomControlsEnabled: false, // 줌 버튼 숨김 (깔끔하게)
            myLocationEnabled: true, // 내 위치 표시 (권한 필요)
            myLocationButtonEnabled: false, // 내 위치로 가기 버튼 숨김 (커스텀 버튼 사용)
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // 🔍 필터 버튼 (우측 상단)
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'filter',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF16366D),
              onPressed: () => _showFilterModal(context),
              child: const Icon(Icons.filter_list_alt),
            ),
          ),

          // 🎯 학교 중심으로 돌아오기 버튼 (우측 하단)
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'center',
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              onPressed: _goToSchoolCenter,
              child: const Icon(Icons.school),
            ),
          ),
        ],
      ),
    );
  }

  // 학교 중심으로 카메라 이동
  Future<void> _goToSchoolCenter() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kSchoolCenter));
  }

  // 👇 기존 로직 그대로 유지 (바텀 시트) 👇
  void _showBuildingDetail(String buildingName) {
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(buildingName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text("추천 강의실", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              
              if (floors.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("등록된 강의실 정보가 없습니다.")),
                )
              else
                ...floors.map((floorData) {
                  final floor = floorData['floor'] as String;
                  final rooms = floorData['rooms'] as List<String>;
                  final recommendedRoom = rooms.first;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: Text(floor, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                    title: Text("$recommendedRoom (추천)"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      // 상세 페이지 이동 로직 (기존과 동일)
                      final spaceData = {
                        'name': recommendedRoom,
                        'location': '$buildingName $floor',
                        'capacity': '정보 없음',
                      };
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(space: spaceData)));
                    },
                  );
                }),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: buildingName)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 15)
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
