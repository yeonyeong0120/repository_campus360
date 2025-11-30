import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'firebase_options.dart'; // flutterfire configure가 생성한 파일
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart'; // 스플래시

void main() async {
  // Firebase가 네이티브 코드를 먼저 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null); // 한국어 문제 해결
  // Firebase 앱 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
