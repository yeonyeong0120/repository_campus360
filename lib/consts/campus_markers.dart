// lib/consts/campus_markers.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 마커 생성을 위한 데이터 모델
class MarkerInfo {
  final String id;
  final String title;
  final LatLng position;

  const MarkerInfo({
    required this.id,
    required this.title,
    required this.position,
  });
}

final List<MarkerInfo> campusMarkerData = [
  // 하이테크관 마커
  const MarkerInfo(
    id: 'hitech',
    title: '하이테크관',
    position: LatLng(37.476920, 126.755066),
  ),
  
  // 5기술관 마커
  const MarkerInfo(
    id: 'tech5',
    title: '5기술관',
    position: LatLng(37.480033, 126.755020),
  ),
  
  // 대학 본관 마커
  const MarkerInfo(
    id: 'main_hall',
    title: '대학 본관',
    position: LatLng(37.478398, 126.755721),
  ),
  
  // 정문
  const MarkerInfo(
    id: 'main_gate',
    title: '학교 정문',
    position: LatLng(37.478871, 126.753714),
  ),
  
  // 1기술관
  const MarkerInfo(
    id: 'tech1',
    title: '1기술관',
    position: LatLng(37.477906, 126.753370),
  ),

  // 2기술관
  const MarkerInfo(
    id: 'tech2',
    title: '2기술관',
    position: LatLng(37.477956, 126.754424),
  ),

  // 3기술관
  const MarkerInfo(
    id: 'tech3',
    title: '3기술관',
    position: LatLng(37.477481, 126.754837),
  ),

  // 6기술관
  const MarkerInfo(
    id: 'tech6',
    title: '6기술관',
    position: LatLng(37.478102, 126.755132),
  ),

  // 7기술관
  const MarkerInfo(
    id: 'tech7',
    title: '7기술관',
    position: LatLng(37.477048, 126.755358),
  ),

  // 학생회관
  const MarkerInfo(
    id: 'student_union',
    title: '학생회관',
    position: LatLng(37.479040, 126.754130),
  ),

  // 산학협력관
  const MarkerInfo(
    id: 'cooperation',
    title: '산학협력관',
    position: LatLng(37.479420, 126.756077),
  ),

  // 폴90도 (카페)
  const MarkerInfo(
    id: 'cafe',
    title: '폴90도 (카페)',
    position: LatLng(37.478980, 126.755663),
  ),

  // 역사관
  const MarkerInfo(
    id: 'history',
    title: '역사관',
    position: LatLng(37.479016, 126.756143),
  ),


  // 더추가...
];
