// lib/screens/review_write_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart'; // UserProvider import 필요

class ReviewWriteScreen extends StatefulWidget {
  final Map<String, dynamic> reservationData; // 예약 정보 받아옴

  const ReviewWriteScreen({super.key, required this.reservationData});

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  final TextEditingController _contentController = TextEditingController();
  int _rating = 5; // 기본 별점 5점
  bool _isSubmitting = false;

  void _submitReview() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("리뷰 내용을 입력해주세요.")));
      return;
    }

    setState(() => _isSubmitting = true);

    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user == null) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("로그인 정보 오류.")));
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      // 1. 'reviews' 컬렉션에 리뷰 추가
      await FirebaseFirestore.instance.collection('reviews').add({
        'userId': user.uid,
        'userName': user.name,
        'spaceName': widget.reservationData['spaceName'],
        'reservationId': widget.reservationData['docId'],
        'rating': _rating,
        'content': _contentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. 'reservations' 문서에 'hasReview: true' 표시 (중복 작성 방지)
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationData['docId'])
          .update({'hasReview': true});

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("리뷰가 등록되었습니다!")));
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("오류 발생: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("리뷰 작성",
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'manru',
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.reservationData['spaceName']} 이용은 어떠셨나요?",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'manru')),
            const SizedBox(height: 20),

            // 별점 선택
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      Icons.star_rounded,
                      size: 40,
                      color: index < _rating
                          ? const Color(0xFF4282CB)
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 30),

            // 리뷰 내용 입력
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "솔직한 이용 후기를 남겨주세요.",
                filled: true,
                // 🌟 [수정 완료] withOpacity 대신 withValues(alpha: ...) 또는 명시적 Color
                fillColor: Colors.grey[100]!, // F5F7FA와 비슷한 톤
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),

            // 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4282CB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("리뷰 등록하기",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
