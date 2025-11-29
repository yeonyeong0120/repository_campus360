// lib/screens/webview_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // [cite: 499]

// WebView 화면을 위한 StatefullWidget을 생성합니다.
class WebViewScreen extends StatefulWidget {
  // 공간 문서에 저장된 360도 뷰어의 URL을 받기 위한 변수입니다. [cite: 264]
  final String view360Url;

  const WebViewScreen({super.key, required this.view360Url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  // WebView를 제어하기 위한 컨트롤러입니다.
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    // 1. 컨트롤러를 초기화하고
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // JS 허용
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 로딩 진행률을 표시하는 로직을 여기에 추가할 수 있습니다.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            // 웹 페이지 로딩 오류 처리
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('웹뷰 로딩 오류: ${error.description}')),
            );
          },
        ),
      )
      // 2. 전달받은 URL을 로드합니다. [cite: 501, 502]
      ..loadRequest(Uri.parse(widget.view360Url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('360도 공간 미리보기 📷'), // 사용자에게 360도 뷰임을 명시
      ),
      // WebView를 화면에 표시합니다.
      body: WebViewWidget(controller: controller),
    );
  }
}
