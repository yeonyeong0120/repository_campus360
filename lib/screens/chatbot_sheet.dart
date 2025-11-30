// lib/screens/chatbot_sheet.dart
// 나중에 수정할때 참고...
// nextId -> 다음질문 // answer -> 종착지?
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotSheet extends StatefulWidget {
  const ChatbotSheet({super.key});

  @override
  State<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<ChatbotSheet> {
  // start부터 시작
  String _currentDocId = 'start';
  
  // 답변을 보여줄 때 사용할 변수들
  String? _selectedAnswer;
  String? _selectedImage;

  // [기능] 버튼 눌렀을 때 처리 로직
  void _handleButtonPress(Map<String, dynamic> branch) {
    // 1. 다음 질문으로 넘어가는 경우 (nextId가 있을 때)
    if (branch.containsKey('nextId')) {
      setState(() {
        _currentDocId = branch['nextId']; // 문서 ID 변경 -> 화면 갱신
        _selectedAnswer = null; // 답변 초기화
        _selectedImage = null;
      });
    } 
    // 2. 답변을 보여주는 경우 (answer가 있을 때)
    else if (branch.containsKey('answer')) {
      setState(() {
        _selectedAnswer = branch['answer']; // 답변 텍스트 저장
        _selectedImage = branch['image'];   // 이미지 경로 저장 (있으면)
      });
    }
  }

  // [기능] 다시 처음으로 돌아가기 (초기화)
  void _resetChat() {
    setState(() {
      _currentDocId = 'start';
      _selectedAnswer = null;
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500, // 시트 높이
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. 헤더 (아이콘 + 제목 + 닫기 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("캠퍼스 톡", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 44, 90, 149))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          
          // 2. 대화 내용 영역 (DB 연동)
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatbot_qna')
                  .doc(_currentDocId)
                  .snapshots(),
              builder: (context, snapshot) {
                // 로딩 중
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // 데이터 가져오기
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) return const Text("데이터 오류");

                final String msg = data['msg'] ?? "질문 내용이 없습니다.";
                final List<dynamic> branches = data['branches'] ?? [];

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // 🤖 봇의 질문 (왼쪽 말풍선)
                      _buildChatBubble(msg, isBot: true),
                      
                      const SizedBox(height: 20),

                      // 👉 사용자 선택지 (답변이 아직 없을 때만 보임)
                      if (_selectedAnswer == null)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.end, // 오른쪽 정렬
                          children: branches.map((branch) {
                            return ActionChip(
                              label: Text(branch['label'] ?? '버튼'),
                              backgroundColor: Colors.blue[50],
                              labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              onPressed: () => _handleButtonPress(branch),
                            );
                          }).toList(),
                        ),

                      // 💡 답변 결과 (답변이 선택되었을 때 보임)
                      if (_selectedAnswer != null) ...[
                        const SizedBox(height: 20),
                        // 답변 텍스트
                        _buildChatBubble(_selectedAnswer!, isBot: true, isAnswer: true),
                        
                        // 🖼️ 약도 이미지
                        if (_selectedImage != null && _selectedImage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10, left: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                color: Colors.grey[200],
                                width: 200,
                                height: 150,
                                // 나중에 assets 이미지가 준비되면 Image.asset(_selectedImage!)로 변경하면 됨
                                child: _buildSmartImage(_selectedImage!),
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),
                        
                        // 처음으로 돌아가기 버튼
                        Center(
                          child: TextButton.icon(
                            onPressed: _resetChat,
                            style: TextButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 18), // 텍스트 크기
                            iconSize: 24, // 아이콘 크기 (기본 24)
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text("처음부터 다시 물어보기"),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 말풍선 디자인 위젯
  Widget _buildChatBubble(String text, {required bool isBot, bool isAnswer = false}) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: isAnswer ? Colors.green[50] : (isBot ? Colors.grey[200] : Colors.blue[100]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
            bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: isAnswer ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // DB랑 이미지파일 연결
  Widget _buildSmartImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Text("이미지 파일 없음"));
        },
      );
    } else {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image));
        },
      );
    }
  }
}