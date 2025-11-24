// lib/screens/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅용
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ReservationScreen extends StatefulWidget {
  final Map<String, dynamic> space; // 어떤 강의실을 예약하는지

  const ReservationScreen({super.key, required this.space});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  // 1. 달력 관련 변수들
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay; // 선택된 날짜

  // 2. 시간 선택 관련 변수들
  final List<String> _timeSlots = [
    "09:00 ~ 11:00",
    "11:00 ~ 13:00",
    "13:00 ~ 15:00",
    "15:00 ~ 17:00",
    "17:00 ~ 19:00",
  ];
  String? _selectedTime; // 선택된 시간

  // 3. 예약 저장 함수
  void _handleReserve() async {
    if (_selectedDay == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("날짜와 시간을 모두 선택해주세요.")),
      );
      return;
    }

    // 로그인한 유저 정보 가져오기
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    try {
      // 선택한 시간 문자열 파싱 (예: "09:00 ~ 11:00")
      // 시작 시간만 계산해서 저장 // 편의상 '날짜'와 '시간대' 텍스트를 저장
      
      String dateString = DateFormat('yyyy-MM-dd').format(_selectedDay!);

      // DB 'reservations' 컬렉션에 저장
      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user.uid,
        'userName': user.name, // 편의상 이름도 같이 저장
        'spaceId': widget.space['name'], // 공간 이름 // 일단 ID대신 이름으로?
        'spaceName': widget.space['name'],
        'date': dateString, // 2025-11-24
        'timeSlot': _selectedTime, // 09:00 ~ 11:00
        'status': 'confirmed', // 예약 확정 상태
        'createdAt': FieldValue.serverTimestamp(), // 예약한 시간
      });

      if (mounted) {
        // 성공 알림 -> 홈으로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("예약이 완료되었습니다!")),
        );
        // 메인 화면으로
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("예약 실패: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.space['name']} 예약")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 달력 (TableCalendar)
            const Text("날짜 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TableCalendar(
              locale: 'ko_KR', // 한국어 달력 (main.dart에서 설정 필요, 일단 기본값 사용)
              firstDay: DateTime.now(),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // 2주/월 보기 버튼 숨김
                titleCentered: true,
              ),
            ),

            const SizedBox(height: 30),

            // 2. 시간 선택 (Chips)
            const Text("시간 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTime == time;
                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedTime = selected ? time : null;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 50),

            // 3. 예약하기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleReserve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("예약 확정하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}