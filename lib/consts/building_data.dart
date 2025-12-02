// lib/consts/building_data.dart

// 전역 변수(const)로 선언하여 어디서든 쓸 수 있게 합니다.
const Map<String, List<Map<String, dynamic>>> buildingData = {
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
  // ... 필요한 만큼 추가하세요!
};