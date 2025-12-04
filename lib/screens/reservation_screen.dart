import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용
import 'reservation_form_screen.dart';

class ReservationScreen extends StatefulWidget {
  final Map<String, dynamic> space;

  const ReservationScreen({super.key, required this.space});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 🔥 [수정] 앱 켜자마자 '오늘'이 선택되도록 설정
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  final List<String> _timeSlots = [
    "09:00 ~ 11:00",
    "11:00 ~ 13:00",
    "13:00 ~ 15:00",
    "15:00 ~ 17:00",
    "17:00 ~ 19:00",
  ];
  String? _selectedTime;

  // 🔥 [핵심] 시간 비교 로직 강화 (이미 지난 시간 잠그기)
  bool _isTimeDisabled(String timeSlot) {
    if (_selectedDay == null) return true;

    final now = DateTime.now();

    // 시간/분/초를 떼고 '날짜'만 비교하기 위해 정리 (년,월,일 만 사용)
    final selectedDate =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final todayDate = DateTime(now.year, now.month, now.day);

    // 1. 과거 날짜를 선택했다면 -> 모든 시간 잠금
    if (selectedDate.isBefore(todayDate)) {
      return true;
    }

    // 2. 미래 날짜를 선택했다면 -> 모든 시간 열림
    if (selectedDate.isAfter(todayDate)) {
      return false;
    }

    // 3. 오늘 날짜라면? -> 현재 시간과 비교해서 지난 시간 잠금
    try {
      // "09:00 ~ 11:00" 에서 앞의 "09"와 "00"을 추출
      final startTimeString = timeSlot.split(' ~ ')[0];
      final startHour = int.parse(startTimeString.split(':')[0]);
      final startMinute = int.parse(startTimeString.split(':')[1]);

      // 현재 시간이 슬롯 시작 시간보다 늦으면 true (잠금)
      // 예: 지금 19:01인데 슬롯이 17:00 시작이면 -> 잠금
      if (now.hour > startHour) return true;
      if (now.hour == startHour && now.minute >= startMinute) return true;

      return false; // 아직 안 지났으면 열림
    } catch (e) {
      return false;
    }
  }

  void _goToNextStep() {
    if (_selectedDay == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("날짜와 시간을 모두 선택해주세요."),
          duration: Duration(seconds: 1),
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "${widget.space['name']} 예약",
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'manru'),
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
            // 1. 날짜 선택 섹션
            _buildSectionTitle("날짜 선택"),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                firstDay: DateTime.now(), // 오늘 이전 날짜는 아예 막음
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,

                // 🔥 [수정] 저번달, 다음달 날짜 안 보이게 숨김
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue[800],
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                      color: Colors.blue[800], fontWeight: FontWeight.bold),
                ),

                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTime = null; // 날짜 바꾸면 시간 선택 초기화
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
                  titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'manru'),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. 시간 선택 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("이용 시간 선택"),
                // 날짜 확인용 텍스트 추가
                if (_selectedDay != null)
                  Text(
                    DateFormat('MM월 dd일 (E)', 'ko_KR').format(_selectedDay!),
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeSlots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final time = _timeSlots[index];

                // 🔥 이미 지난 시간인지 확인 (오늘 날짜 기준)
                final bool isDisabled = _isTimeDisabled(time);
                final bool isSelected = _selectedTime == time;

                return GestureDetector(
                  onTap: isDisabled
                      ? null // 비활성화면 클릭 안됨
                      : () {
                          setState(() {
                            _selectedTime = isSelected ? null : time;
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      // 비활성화(회색) vs 선택됨(파랑) vs 기본(흰색)
                      color: isDisabled
                          ? Colors.grey[200]
                          : (isSelected ? Colors.blue[800] : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDisabled
                            ? Colors.transparent
                            : (isSelected
                                ? Colors.blue[800]!
                                : Colors.grey.withValues(alpha: 0.3)),
                        width: 1.5,
                      ),
                      boxShadow: isSelected && !isDisabled
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
                        color: isDisabled
                            ? Colors.grey[400]
                            : (isSelected ? Colors.white : Colors.grey[800]),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                        fontFamily: 'manru',
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
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "다음 단계",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'manru'),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
            fontFamily: 'manru',
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
