import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
// flutterfire configure가 생성한 파일
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🌟 [추가됨] .env 파일 로드용 패키지
import 'screens/splash_screen.dart'; // 스플래시
import 'firebase_options.dart'; // 🌟 [핵심 추가] 파이어베이스 설정 파일 가져오기

void main() async {
  // Firebase가 네이티브 코드를 먼저 초기화
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null); // 한국어 문제 해결

  // 🌟 [추가됨] 챗봇 API 키가 들어있는 .env 파일을 미리 열어둡니다.
  // 이 코드가 없으면 챗봇 화면에서 키를 부를 때 "준비 안 됨(NotInitializedError)" 에러가 뜹니다.
  await dotenv.load(fileName: ".env");

  // Firebase 앱 초기화
  // 🌟 [수정] options를 넣어줘야 앱이 어떤 파이어베이스 프로젝트인지 정확히 알고 연결합니다.
  // 이게 없으면 연결 대기 상태에서 앱이 멈출 수 있습니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(), // 전광판 설치
      child: const Campus360App(),
    ),
  );
}

class Campus360App extends StatelessWidget {
  const Campus360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Room 360',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // 🌟 [핵심] 여기에 폰트 이름을 등록해야 앱 전체가 이 폰트로 바뀝니다!
        // pubspec.yaml에 등록한 family 이름과 토씨 하나 틀리지 않게 적어야 합니다.
        fontFamily: 'manru',
      ),
      // 여기부터 한국어 문제 해결
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Material 위젯의 텍스트 지원 (예: 확인, 취소)
        GlobalWidgetsLocalizations.delegate, // 위젯의 텍스트 방향 지원
        GlobalCupertinoLocalizations.delegate, // iOS 스타일 위젯의 텍스트 지원
      ],

      // 지원 언어 목록 설정
      supportedLocales: const [
        Locale('en', 'US'), // 기본 영어
        Locale('ko', 'KR'), // 한국어 지원 명시
      ],

      // 기본 Locale을 한국어로 설정
      locale: const Locale('ko', 'KR'),

      home: const SplashScreen(),
    );
  }
}
