// lib/screens/reservation_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

// 💡 클래스 이름을 ReservationDetailScreen -> ReservationFormScreen으로 변경
class ReservationFormScreen extends StatefulWidget {
  final Map<String, dynamic> space;
  final DateTime selectedDay;
  final String selectedTime;

  const ReservationFormScreen({
    super.key,
    required this.space,
    required this.selectedDay,
    required this.selectedTime,
  });

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  int _headCount = 1;
  bool _useProjector = false;
  bool _useMic = false;
  bool _agreedToRules = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _purposeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submitReservation() async {
    if (_purposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("사용 목적을 입력해주세요."),
        duration: Duration(seconds: 1), // 1초 뒤 사라짐
      ));
      return;
    }
    if (_contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("연락처를 입력해주세요."),
        duration: Duration(seconds: 1), // 1초 뒤 사라짐
      ));
      return;
    }
    if (!_agreedToRules) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("이용 수칙에 동의해주세요."),
        duration: Duration(seconds: 1), // 1초 뒤 사라짐
      ));
      return;
    }

    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("로그인이 필요합니다."),
        duration: Duration(seconds: 1), // 1초 뒤 사라짐
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final timeParts = widget.selectedTime.split(' ~ ');
      final startTimeStr = timeParts[0];
      final endTimeStr = timeParts[1];

      final startHour = int.parse(startTimeStr.split(':')[0]);
      final startMinute = int.parse(startTimeStr.split(':')[1]);
      final startTimeDateTime = DateTime(
          widget.selectedDay.year,
          widget.selectedDay.month,
          widget.selectedDay.day,
          startHour,
          startMinute);

      final endHour = int.parse(endTimeStr.split(':')[0]);
      final endMinute = int.parse(endTimeStr.split(':')[1]);
      final endTimeDateTime = DateTime(widget.selectedDay.year,
          widget.selectedDay.month, widget.selectedDay.day, endHour, endMinute);

      String dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDay);

      List<String> equipment = [];
      if (_useProjector) equipment.add("빔 프로젝터");
      if (_useMic) equipment.add("마이크");

      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user.uid,
        'userName': user.name,
        'spaceName': widget.space['name'],
        'date': dateString,
        'timeSlot': widget.selectedTime,
        'startTime': Timestamp.fromDate(startTimeDateTime),
        'endTime': Timestamp.fromDate(endTimeDateTime),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'purpose': _purposeController.text.trim(),
        'contact': _contactController.text.trim(),
        'headCount': _headCount,
        'equipment': equipment,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("예약 신청이 완료되었습니다!"),
            duration: Duration(seconds: 1), // 1초 뒤 사라짐
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("예약 실패: $e"),
          duration: const Duration(seconds: 1), // 1초 뒤 사라짐
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("예약 정보 입력 (2/2)"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요약 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16), bottom: Radius.circular(4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.space['name'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(widget.selectedDay)}  |  ${widget.selectedTime}",
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(color: Colors.white, height: 2),

            // 📦 [상세 입력 폼 박스 시작] 📦
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4), bottom: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 사용 인원
                  const Text("사용 인원",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_headCount > 1) setState(() => _headCount--);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text("$_headCount명",
                          style: const TextStyle(fontSize: 18)),
                      IconButton(
                        onPressed: () {
                          if (_headCount < 50) setState(() => _headCount++);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // 2. 사용 목적
                  const Text("사용 목적",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _purposeController,
                    decoration: InputDecoration(
                      hintText: "예: 조별 과제 회의, 동아리 모임",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. 연락처
                  const Text("대표자 연락처",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "010-0000-0000",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const Divider(height: 40),

                  // 4. 필요 기자재
                  const Text("필요 기자재 (선택)",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 15),

                  // [빔 프로젝터]
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _useProjector,
                          activeColor: Colors.blue[800],
                          onChanged: (val) =>
                              setState(() => _useProjector = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _useProjector = !_useProjector),
                        child: const Text(
                          "빔 프로젝터",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15), // 간격 8 -> 15 (사용자 코드 반영)

                  // [마이크]
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _useMic,
                          activeColor: Colors.blue[800],
                          onChanged: (val) => setState(() => _useMic = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _useMic = !_useMic),
                        child: const Text(
                          "마이크",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 📦 [상세 입력 폼 박스 끝] 📦 (여기서 흰색 박스가 닫힙니다!)

            const SizedBox(height: 20),

            // 5. 이용 수칙 동의 (이제 박스 밖에 위치함)
            Transform.translate(
              offset: const Offset(0, 0), // 왼쪽으로 10만큼 이동 (5로 되어 있어서 유지)
              child: Row(
                children: [
                  Checkbox(
                    value: _agreedToRules,
                    activeColor: Colors.blue[800],
                    onChanged: (val) =>
                        setState(() => _agreedToRules = val ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Expanded(
                    child: Text(
                      "시설 이용 수칙을 준수하며, 파손 시 배상 책임에 동의함",
                      style: TextStyle(
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 최종 예약 버튼 (이제 박스 밖에 위치함)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("예약 확정하기",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
