// lib/widgets/common_image.dart
// 이미지 모아두는 용도로 쓸거임
import 'package:flutter/material.dart';

class CommonImage extends StatelessWidget {
  final String? url; // 이미지 주소
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const CommonImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 모서리 둥글게 깎기
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // 2. URL이 없거나 비어있으면 -> 에러 화면 표시
    if (url == null || url!.isEmpty) {
      return _buildErrorWidget();
    }

    // 3. 인터넷 이미지 (http로 시작)
    if (url!.startsWith('http')) {
      return Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(), // 로딩 실패시 에러 화면
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget(); // 로딩 중일 때 표시
        },
      );
    } 
    // 4. 로컬 자산 이미지 (assets로 시작)
    else if (url!.startsWith('assets/')) {
      return Image.asset(
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
    
    // 5. 그 외 이상한 주소 -> 에러 화면
    return _buildErrorWidget();
  }

  // 🚨 [준비중입니다] 에러 위젯
  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200], // 회색 배경
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 일단 에러메시지 이미지 사용하고 없으면... 흠...
          Image.asset(
            'assets/images/errorImage.png', 
            width: 50, 
            height: 50,
            // 최후의 방어선
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
          ),
          const SizedBox(height: 8),
          const Text(
            "준비중입니다...😅",
            style: TextStyle(
              color: Colors.grey, 
              fontSize: 10, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  // ⏳ 로딩 중 위젯 (회색 박스에 빙글빙글)
  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: const Center(
        child: SizedBox(
          width: 20, 
          height: 20, 
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      ),
    );
  }
}