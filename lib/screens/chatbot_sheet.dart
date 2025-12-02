// lib/screens/chatbot_sheet.dart
// 나중에 수정할때 참고...
// nextId -> 다음질문 // answer -> 종착지?
// lib/screens/chatbot_sheet.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // AI 패키지
import '../consts/school_info.dart'; // 프롬프트 데이터

class ChatbotSheet extends StatefulWidget {
  const ChatbotSheet({super.key});

  @override
  State<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<ChatbotSheet> {
  final List<Map<String, String>> _chatHistory = []; // 대화 기록
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  late final GenerativeModel _model;
  final String _apiKey = 'AIzaSyBNGBbI0MPi6oc3xvPJJmxuk3IztsJVH50'; 

  @override
  void initState() {
    super.initState();
    // 챗봇 시작할 때 환영 메시지 하나 넣어주기
    _chatHistory.add({'role': 'bot', 'text': '안녕하세요! 캠퍼스 톡입니다. 무엇을 도와드릴까요? 😊'});
    
    // Gemini 설정
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(schoolPrompt),
    );
  }

  // 메시지 전송 함수
  Future<void> _sendMessage({String? text}) async {
    final message = text ?? _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'text': message});
      if (text == null) _textController.clear(); // 버튼 클릭이 아닐 때만 지움
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);

      setState(() {
        _chatHistory.add({'role': 'bot', 'text': response.text ?? "답변을 생성하지 못했습니다."});
      });
    } catch (e) {
      setState(() {
        _chatHistory.add({'role': 'bot', 'text': "오류가 발생했습니다: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 키보드 올라왔을 때 가림 방지
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. 헤더
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("캠퍼스 톡 (AI)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. 채팅 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                final isUser = chat['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(chat['text']!, style: const TextStyle(fontSize: 15)),
                  ),
                );
              },
            ),
          ),

          // 3. 로딩 인디케이터
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // 4. 추천 버튼 (Firestore 'start' 문서에서 가져오기)
          SizedBox(
            height: 50,
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chatbot_qna').doc('start').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) return const SizedBox();
                final branches = data['branches'] as List<dynamic>? ?? [];

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final btn = branches[index];
                    return ActionChip(
                      label: Text(btn['label'] ?? '질문'),
                      backgroundColor: Colors.blue[50],
                      onPressed: () {
                        // 버튼을 누르면 그 텍스트 그대로 AI에게 질문!
                        _sendMessage(text: btn['label'] ?? '질문');
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 5. 입력창
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "궁금한 점을 물어보세요...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}