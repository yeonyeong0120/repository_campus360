// lib/screens/map_screen.dart

import 'dart:async'; // Completer
import 'package:google_maps_flutter/google_maps_flutter.dart'; // 구글맵 패키지
import 'package:flutter/material.dart';
import 'package:repository_campus360/consts/campus_markers.dart';
import 'search_screen.dart'; // 검색결과랑 연결
import 'detail_screen.dart'; // 상세 화면 연결

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 구글맵 컨트롤러
  final Completer<GoogleMapController> _controller = Completer();

  // 🏫 학교 중심 좌표
  static const CameraPosition _kSchoolCenter = CameraPosition(
    target: LatLng(37.478624, 126.754742),
    zoom: 17.5,
  );

  // 📍 마커(핀) 목록
  Set<Marker> _markers = {};

  // 필터용 변수
  double _peopleCount = 10.0;

  // 🔥 [핵심 추가] 전체 공간 데이터 (실제 상세 내역과 동일한 데이터베이스)
  // 원래는 별도 파일(예: data/room_data.dart)에 있어야 하지만,
  // 설명을 위해 여기에 포함했습니다. 이 데이터가 '정답지'입니다.
  final List<Map<String, String>> _allSpacesDatabase = [
    // ---------------- [하이테크관] ----------------
    {'name': '디지털데이터활용실습실', 'capacity': '42', 'location': '하이테크관 3F'},
    {'name': '강의실 2', 'capacity': '30', 'location': '하이테크관 3F'},
    {'name': '컨퍼런스룸', 'capacity': '20', 'location': '하이테크관 2F'},
    // ---------------- [1기술관] ----------------
    {'name': 'CAD실습실', 'capacity': '36', 'location': '1기술관 2F'},
    {'name': '콘트롤러실습실', 'capacity': '30', 'location': '1기술관 2F'},
    // ---------------- [2기술관] ----------------
    {'name': '자동차과이론강의실', 'capacity': '48', 'location': '2기술관 3F'},
    {'name': 'PLC실습실', 'capacity': '24', 'location': '2기술관 3F'},
    {'name': 'CAD/CAE실', 'capacity': '30', 'location': '2기술관 2F'},
    {'name': 'CATIA실습실', 'capacity': '32', 'location': '2기술관 1F'},
    {'name': '전기자동차실습실', 'capacity': '20', 'location': '2기술관 1F'},
    // ---------------- [3기술관] ----------------
    {'name': '아이디어 존', 'capacity': '15', 'location': '3기술관 1F'},
    // ---------------- [5기술관] ----------------
    {'name': '시제품창의개발실', 'capacity': '20', 'location': '5기술관 4F'},
    {'name': '아이디어카페', 'capacity': '50', 'location': '5기술관 4F'},
    {'name': '디자인워크샵실습실', 'capacity': '30', 'location': '5기술관 4F'},
    {'name': '융합디자인실습실', 'capacity': '35', 'location': '5기술관 4F'},
    {'name': '디지털디자인실습실', 'capacity': '30', 'location': '5기술관 4F'},
    {'name': '미디어창작실습실', 'capacity': '25', 'location': '5기술관 4F'},
    {'name': '강의실', 'capacity': '40', 'location': '5기술관 3F'},
    {'name': '스터디룸', 'capacity': '8', 'location': '5기술관 3F'},
    {'name': '반도체제어실', 'capacity': '30', 'location': '5기술관 3F'},
    {'name': '전자CAD실', 'capacity': '35', 'location': '5기술관 3F'},
    {'name': '기초전자실습실', 'capacity': '35', 'location': '5기술관 3F'},
    {'name': 'AI융합프로젝트실습실', 'capacity': '40', 'location': '5기술관 2F'},
    {'name': '인공지능프로그래밍실습실', 'capacity': '40', 'location': '5기술관 2F'},
    {'name': 'ioT제어실습실', 'capacity': '30', 'location': '5기술관 2F'},
    {'name': '개인미디어실', 'capacity': '4', 'location': '5기술관 1F'},
    {'name': '세미나실', 'capacity': '15', 'location': '5기술관 1F'},
    {'name': '미디어편집실', 'capacity': '20', 'location': '5기술관 1F'},
    {'name': 'AR그래픽실', 'capacity': '25', 'location': '5기술관 1F'},
    {'name': '실감형콘텐츠운영실습실', 'capacity': '30', 'location': '5기술관 1F'},
    // ---------------- [6기술관] ----------------
    {'name': '건축설계과', 'capacity': '60', 'location': '6기술관 1F'},
    // ---------------- [7기술관] ----------------
    {'name': '소그룹실', 'capacity': '8', 'location': '7기술관 3F'},
    {'name': '강의실', 'capacity': '40', 'location': '7기술관 3F'},
    {'name': '반도체 시스템 제작실', 'capacity': '25', 'location': '7기술관 3F'},
    // ---------------- [대학 본관] ----------------
    {'name': '로비', 'capacity': '100', 'location': '대학 본관 1F'},
    {'name': '행정실', 'capacity': '20', 'location': '대학 본관 1F'},
  ];

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  // 📍 마커 생성 함수
  void _createMarkers() {
    final buildingMarkers = campusMarkerData.map((info) {
      final bool isGreen = ['학교 정문', '폴90도 (카페)'].contains(info.title);
      final bool isNonClickable =
          ['학교 정문', '폴90도 (카페)', '역사관'].contains(info.title);

      return Marker(
        markerId: MarkerId(info.id),
        position: info.position,
        infoWindow: InfoWindow(title: info.title),
        icon: isGreen
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarker,
        onTap: isNonClickable ? null : () => _showBuildingDetail(info.title),
      );
    }).toSet();

    setState(() {
      _markers = buildingMarkers;
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
            mapType: MapType.normal,
            initialCameraPosition: _kSchoolCenter,
            markers: _markers,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // 🎯 학교 중심으로 돌아오기 버튼
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'center',
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              onPressed: _goToSchoolCenter,
              child: const Icon(
                Icons.center_focus_strong,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToSchoolCenter() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kSchoolCenter));
  }

  // 👇 바텀 시트 (강의실 목록)
  void _showBuildingDetail(String buildingName) {
    // 🌟 1. 지도 바텀시트에 표시할 "목차(Index)" 데이터
    // 여기에는 방 이름과 층수만 있으면 됩니다.
    final Map<String, List<Map<String, dynamic>>> localBuildingIndex = {
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

    final floors = localBuildingIndex[buildingName] ?? [];

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

              const Text("추천 강의실",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),

              if (floors.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("등록된 강의실 정보가 없습니다.")),
                )
              else
                ...floors.map((floorData) {
                  final floor = floorData['floor'] as String;
                  final rooms = floorData['rooms'] as List<String>;
                  final recommendedRoomName = rooms.first; // 이름만 가져옴

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
                    title: Text("$recommendedRoomName (추천)"),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);

                      // 🌟 2. [핵심 수정] 실제 데이터베이스(_allSpacesDatabase)에서 찾기!
                      // "이름이 recommendedRoomName인 데이터를 찾아라"
                      Map<String, String> foundData;
                      try {
                        foundData = _allSpacesDatabase.firstWhere(
                          (element) => element['name'] == recommendedRoomName,
                          // 만약 못 찾으면 기본값 제공 (안전장치)
                          orElse: () => {
                            'name': recommendedRoomName,
                            'location': '$buildingName $floor',
                            'capacity': '0' // 정보 없음
                          },
                        );
                      } catch (e) {
                        foundData = {
                          'name': recommendedRoomName,
                          'location': '$buildingName $floor',
                          'capacity': '0'
                        };
                      }

                      // 찾은 실제 데이터(capacity 포함)를 전달
                      final spaceData = {
                        'name': foundData['name'],
                        'location': foundData['location'], // DB에 있는 정확한 위치
                        'capacity': foundData['capacity'], // 🔥 실제 수용 인원!
                        'mainImageUrl': '',
                      };

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetailScreen(space: spaceData)));
                    },
                  );
                }),

              const SizedBox(height: 20),

              // 전체 보기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => SearchScreen()));
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
