import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:repository_campus360/screens/login_screen.dart';
import 'providers/user_provider.dart';
import 'firebase_options.dart'; // flutterfire configure가 생성한 파일

void main() async {
  // Firebase가 네이티브 코드를 먼저 초기화
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 앱을 초기화하는 코드
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 모든 준비가 끝나면 앱을 실행
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(), // "전광판" 설치
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
        colorScheme:  ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
