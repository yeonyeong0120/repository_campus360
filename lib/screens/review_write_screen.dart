import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용

// 리뷰 작성 페이지 위젯
class ReviewScreen extends StatefulWidget {
  // 리뷰를 남길 시설의 ID 등을 받아서 사용한다고 가정합니다.
  final String facilityId;

  const ReviewScreen({
    Key? key,
    required this.facilityId,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // 현재 선택된 별점 (1~5점)
  int _currentRating = 5;
  // 리뷰 내용 입력 컨트롤러
  final TextEditingController _reviewController =
      TextEditingController(text: '와 짱이에요');
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // 로딩 상태 (리뷰 등록 중 중복 요청 방지)
  bool _isLoading = false;

  // 별점 위젯을 생성하는 함수
  Widget _buildStar(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentRating = index + 1;
        });
      },
      child: Icon(
        index < _currentRating ? Icons.star : Icons.star_border,
        color: Colors.blue,
        size: 36.0,
      ),
    );
  }

  // Firestore에 리뷰를 제출하는 함수 (오류 발생 가능성 수정)
  // 오류가 [cloud_firestore/not-found] 였으므로, 문서 존재 확인 없이 바로
  // 새 리뷰 문서를 'add'하거나, 특정 경로에 'set'하는 방식으로 수정했습니다.
  // 이 예시에서는 'reviews'라는 컬렉션에 새 문서를 추가하는 방식을 사용합니다.
  Future<void> _submitReview() async {
    if (_isLoading) return; // 중복 제출 방지

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 리뷰 데이터 구조 정의
      final reviewData = {
        'facilityId': widget.facilityId, // 리뷰 대상 시설 ID
        'rating': _currentRating, // 별점
        'comment': _reviewController.text.trim(), // 리뷰 내용
        'timestamp': FieldValue.serverTimestamp(), // 서버 시간 기록
        'userId': 'user_001', // 실제 사용자 ID로 대체 필요
      };

      // 2. Firestore에 데이터 추가 (가장 일반적인 리뷰 추가 방식)
      // 'reviews' 컬렉션에 새로운 문서(Document)를 추가합니다.
      // 이렇게 하면 'not-found' 오류 없이 새로운 데이터가 생성됩니다.
      await _firestore.collection('reviews').add(reviewData);

      // 3. 성공 처리 및 창 닫기
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰 등록이 완료되었습니다.')),
        );
        Navigator.pop(context); // 이전 화면으로 돌아가기
      }
    } on FirebaseException catch (e) {
      // 4. Firestore 관련 오류 처리
      // 이전에 발생했던 오류('[cloud_firestore/not-found]')를 포함하여 모든 오류를 처리
      print('Firestore 오류 발생: $e'); // 콘솔에 상세 오류 출력
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: ${e.code} - ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 5. 기타 일반 오류 처리
      print('일반 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예기치 않은 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. 로딩 상태 해제
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 앱바 배경색 및 Elevation 설정 (선택 사항)
        backgroundColor: Colors.white,
        elevation: 0,
        // 뒤로가기 버튼
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 제목 텍스트 (기본 폰트 사용)
        title: const Text(
          '리뷰 작성',
          style: TextStyle(
            color: Colors.black,
            // 폰트 패밀리 지정 없이 기본 폰트 사용
            // fontFamily: 'CustomFont', // <- 커스텀 폰트를 사용했다면 이 줄을 제거하세요.
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 질문 텍스트 (기본 폰트 사용)
            const Text(
              '디지털데이터활용실습실 이용은 어떠셨나요?',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                // fontFamily: 'CustomFont', // <- 커스텀 폰트를 사용했다면 이 줄을 제거하세요.
              ),
            ),
            const SizedBox(height: 20.0),

            // 별점 위젯
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (index) => _buildStar(index)),
            ),
            const SizedBox(height: 30.0),

            // 리뷰 내용 입력 필드
            Container(
              height: 150.0,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: null, // 여러 줄 입력 허용
                // 텍스트 필드 스타일 (기본 폰트 사용)
                style: const TextStyle(
                  // fontFamily: 'CustomFont', // <- 커스텀 폰트를 사용했다면 이 줄을 제거하세요.
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  hintText: '리뷰를 작성해 주세요.',
                  border: InputBorder.none, // 기본 밑줄 제거
                  contentPadding: EdgeInsets.zero, // 패딩 제거
                ),
              ),
            ),
            const SizedBox(height: 30.0),

            // 리뷰 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // 버튼 배경색
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '리뷰 등록하기',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          // fontFamily: 'CustomFont', // <- 커스텀 폰트를 사용했다면 이 줄을 제거하세요.
                        ),
                      ),
              ),
            ),

            // 원래 오류 팝업이 뜨던 위치를 재현한 Placeholder (실제 앱에서는 제거)
            // const SizedBox(height: 50),
            // const Text(
            //   '오류 발생: [cloud_firestore/not-found] Some requested document was not found.',
            //   style: TextStyle(color: Colors.red, fontSize: 14),
            // ),
          ],
        ),
      ),
    );
  }
}

// 예시 실행을 위한 main 함수 (필요시 사용)
// void main() {
//   // Firebase 초기화 코드가 필요합니다.
//   // WidgetsFlutterBinding.ensureInitialized();
//   // await Firebase.initializeApp();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Review App',
//       theme: ThemeData(
//         // 전체 앱에 적용되는 기본 폰트를 설정할 수 있습니다.
//         // 여기서 fontFamily를 지정하지 않으면 Flutter의 기본 폰트(Roboto)가 사용됩니다.
//         // fontFamily: 'NotoSansKR', // <- 만약 다른 곳에서 커스텀 폰트를 사용하고 있다면 이 줄을 제거/수정해야 합니다.
//         primarySwatch: Colors.blue,
//       ),
//       home: const ReviewScreen(facilityId: '실습실_001'),
//     );
//   }
// }
