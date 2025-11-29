// lib/screens/repair_screen.dart
import 'dart:io'; // 파일 처리를 위해.......
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 갤러리/카메라 접근
import 'package:firebase_storage/firebase_storage.dart'; // 사진 저장소
import 'package:cloud_firestore/cloud_firestore.dart'; // 데이터베이스
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class RepairScreen extends StatefulWidget {
  final Map<String, dynamic> space; // 어느 강의실인지 정보 받기

  const RepairScreen({super.key, required this.space});

  @override
  State<RepairScreen> createState() => _RepairScreenState();
}

class _RepairScreenState extends State<RepairScreen> {
  final _descriptionController = TextEditingController();
  File? _selectedImage; // 선택된 사진 파일
  bool _isUploading = false; // 로딩 상태 확인

  final ImagePicker _picker = ImagePicker();

  // 1. 갤러리에서 사진 가져오기
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, // 카메라로 하려면 ImageSource.camera
      imageQuality: 80, // 용량 최적화용
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // 2. 수리 요청 제출 (사진 업로드 -> DB 저장)
  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("고장 내용을 입력해주세요.")),
      );
      return;
    }

    setState(() {
      _isUploading = true; // 로딩 시작
    });

    try {
      final user = context.read<UserProvider>().currentUser;
      if (user == null) return;

      String? imageUrl;

      // [Step A] 사진이 있다면 Firebase Storage에 업로드
      if (_selectedImage != null) {
        // 파일 이름: repair_images/유저ID/현재시간.jpg (중복 방지)
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('repair_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        // 업로드 수행
        await storageRef.putFile(_selectedImage!);
        
        // 업로드된 사진의 인터넷 주소(URL) 가져오기
        imageUrl = await storageRef.getDownloadURL();
      }

      // [Step B] Firestore DB에 요청 내용 저장
      await FirebaseFirestore.instance.collection('repairRequests').add({
        'spaceId': widget.space['name'], // 편의상 이름 사용
        'spaceName': widget.space['name'],
        'userId': user.uid,
        'userName': user.name,
        'description': _descriptionController.text,
        'imageUrl': imageUrl ?? '', // 사진 없으면 빈 문자열
        'status': 'pending', // 초기 상태: 처리 대기중
        'requestedAt': FieldValue.serverTimestamp(), // 요청 시간
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("수리 요청이 접수되었습니다.")),
        );
        Navigator.pop(context); // 화면 닫기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("오류 발생: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false; // 로딩 끝
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("수리/불편 신고")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 공간 정보 표시
            Text(
              "공간: ${widget.space['name']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 사진 첨부 영역
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text("여기를 눌러 사진을 첨부하세요", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 설명 입력창
            TextField(
              controller: _descriptionController,
              maxLines: 5, // 여러 줄 입력 가능
              decoration: const InputDecoration(
                hintText: "어떤 문제가 있나요? 상세하게 적어주세요.\n(예: 모니터 전원이 안 켜져요)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // 제출 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitReport, // 로딩 중엔 버튼 비활성화
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("신고 접수하기", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}