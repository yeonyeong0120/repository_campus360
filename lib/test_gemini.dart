// lib/test_gemini.dart
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  // 1. API 키 설정 (아까 복사한 거!)
  const apiKey = 'AIzaSyCR9N8bugWMjVZDWabz9r6qdN2HxrnraGg';

  // 2. 모델 설정 (가장 빠르고 가벼운 gemini-1.5-flash 사용)
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
    // 여기가 바로 "프롬프트(가스라이팅)" 하는 곳입니다! 😈
    systemInstruction: Content.system(
      '''
      너는 이제부터 한국폴리텍대학 인천캠퍼스의 똑똑한 도우미 챗봇이야.
      아래 정보를 바탕으로 학생에게 친절하고 정확하게 대답해줘. 모르는 내용은 솔직히 모른다고 해.
      
      [학교 정보]
      - 도서관 위치: 5기술관 1층
      - 학생식당 위치: 학생회관 2층
      - 점심시간: 11:30 ~ 13:30
      - 교무기획처 전화번호: 032-510-2114
      ''',
    ),
  );

  // 3. 질문 던지기
  final userQuestion = "점심시간 언제야?";
  // ignore: avoid_print
  print("나: $userQuestion");

  try {
    final response = await model.generateContent([Content.text(userQuestion)]);
    // ignore: avoid_print
    print("Gemini: ${response.text}");
  } catch (e) {
    // ignore: avoid_print
    print("에러 발생: $e");
  }
}