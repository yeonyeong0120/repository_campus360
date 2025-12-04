// lib/screens/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'reservation_form_screen.dart'; // 두 번째 페이지 import

class ReservationScreen extends StatefulWidget {
  final Map<String, dynamic> space; // 강의실 정보

  const ReservationScreen({super.key, required this.space});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  // 1. 달력 관련 변수
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  // 💡 [수정됨] 앱 시작 시 오늘 날짜가 기본으로 선택되도록 초기화
  DateTime? _selectedDay = DateTime.now();

  // 2. 시간 선택 관련 변수
  final List<String> _timeSlots = [
    "09:00 ~ 11:00",
    "11:00 ~ 13:00",
    "13:00 ~ 15:00",
    "15:00 ~ 17:00",
    "17:00 ~ 19:00",
  ];
  String? _selectedTime;

  // 다음 단계로 이동하는 함수
  void _goToNextStep() {
    if (_selectedDay == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("날짜와 시간을 모두 선택해주세요."),
          duration: Duration(seconds: 1), // 1초 뒤 사라짐
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationFormScreen(
          space: widget.space,
          selectedDay: _selectedDay!,
          selectedTime: _selectedTime!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 배경: 아주 연한 회색
      appBar: AppBar(
        title: Text(
          "${widget.space['name']} 예약",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 달력 섹션 (카드 디자인)
            _buildSectionTitle("날짜 선택"),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 15),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.now(),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    // 💡 [수정됨] 날짜를 바꿔도 선택한 시간이 사라지지 않도록 초기화 코드 삭제
                    // _selectedTime = null;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: Colors.grey),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue[800], // 학교 상징색
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: Colors.blue[800]),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. 시간 선택 섹션 (Grid Layout 적용)
            _buildSectionTitle("이용 시간 선택"),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true, // 스크롤 뷰 안에서 크기 오류 방지
              physics:
                  const NeverScrollableScrollPhysics(), // 스크롤 금지 (전체 스크롤 사용)
              itemCount: _timeSlots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 한 줄에 3개
                childAspectRatio: 2.4, // 버튼 비율 (가로/세로)
                crossAxisSpacing: 8, // 가로 간격
                mainAxisSpacing: 8, // 세로 간격
              ),
              itemBuilder: (context, index) {
                final time = _timeSlots[index];
                final isSelected = _selectedTime == time;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTime = isSelected ? null : time;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[800] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue[800]!
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12.5, // 3칸 배치에 맞춰 글자 크기 조정
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // 3. 다음 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _goToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTime != null && _selectedDay != null
                      ? Colors.blue[800]
                      : Colors.grey[300], // 선택 안되면 회색 처리
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "다음 단계",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 섹션 제목 스타일 위젯
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.blue[800],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
