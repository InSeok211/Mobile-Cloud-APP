import 'package:flutter/material.dart';
import 'survey_result_screen.dart';

// 감정 설문지 화면
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // 설문 응답 저장 (모두 0-4 범위, 5단계)
  int? q1Valence; // 감정의 긍정성/부정성 (0: 매우 부정 ~ 4: 매우 긍정)
  int? q2Arousal; // 각성 정도 (0: 매우 차분 ~ 4: 매우 흥분)
  int? q3Attention; // 주의 집중 정도 (0: 전혀 집중 안됨 ~ 4: 매우 집중)
  int? q4Stress; // 스트레스 수준 (0: 없음 ~ 4: 매우 높음)
  int? q5Duration; // 감정 지속 시간 (0: 방금 ~ 4: 하루 이상)
  int? q6Disturbance; // 과업 방해 정도 (0: 전혀 없음 ~ 4: 매우 심각)
  int? q7Change; // 감정 변화 (0: 매우 나빠짐 ~ 4: 매우 좋아짐)
  final TextEditingController _diaryController = TextEditingController(); // 일기 내용

  @override
  void dispose() {
    _pageController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: return q1Valence != null;
      case 1: return q2Arousal != null;
      case 2: return q3Attention != null;
      case 3: return q4Stress != null;
      case 4: return q5Duration != null;
      case 5: return q6Disturbance != null;
      case 6: return q7Change != null;
      case 7: return _diaryController.text.trim().isNotEmpty; // 일기 입력 필수
      default: return false;
    }
  }

  void _nextPage() {
    if (_currentPage < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 마지막 페이지 - V/A 계산 및 결과 화면으로 이동
      _calculateAndShowResult();
    }
  }

  void _calculateAndShowResult() {
    // V/A 값 계산
    // Valence: Q1 기반 (-2 ~ 2로 정규화)
    double valence = ((q1Valence! - 2) / 2.0);
    
    // Arousal: Q2 기반 (0 ~ 1로 정규화)
    double arousal = (q2Arousal! / 4.0);
    
    // 전체 데이터 수집
    Map<String, dynamic> surveyResult = {
      'valence': valence,
      'arousal': arousal,
      'attention': q3Attention,
      'stress': q4Stress,
      'duration': q5Duration,
      'disturbance': q6Disturbance,
      'change': q7Change,
      'diaryContent': _diaryController.text.trim(), // 일기 내용 추가
    };

    // 결과 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyResultScreen(surveyResult: surveyResult),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
              ),
              child: const Icon(
                Icons.thermostat,
                size: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '마음온도',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 진행 표시기
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(8, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= _currentPage 
                          ? Colors.black87 
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ),
            // 질문 페이지
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildQ1Valence(),
                  _buildQ2Arousal(),
                  _buildQ3Attention(),
                  _buildQ4Stress(),
                  _buildQ5Duration(),
                  _buildQ6Disturbance(),
                  _buildQ7Change(),
                  _buildDiaryPage(), // 일기 입력 페이지 추가
                ],
              ),
            ),
            // 다음 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6EAF8),
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < 7 ? '다음' : '완료',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Q1: Valence - 감정의 긍정성/부정성
  Widget _buildQ1Valence() {
    return _buildQuestionPage(
      title: 'Q1. 감정 상태',
      question: '지금 느끼는 감정은 어떠신가요?',
      child: Column(
        children: [
          _buildMoodButton('😊', '매우 긍정', () => setState(() => q1Valence = 4)),
          const SizedBox(height: 12),
          _buildMoodButton('🙂', '긍정', () => setState(() => q1Valence = 3)),
          const SizedBox(height: 12),
          _buildMoodButton('😐', '보통', () => setState(() => q1Valence = 2)),
          const SizedBox(height: 12),
          _buildMoodButton('☹️', '부정', () => setState(() => q1Valence = 1)),
          const SizedBox(height: 12),
          _buildMoodButton('😞', '매우 부정', () => setState(() => q1Valence = 0)),
        ],
      ),
    );
  }

  // Q2: Arousal - 각성 정도
  Widget _buildQ2Arousal() {
    return _buildQuestionPage(
      title: 'Q2. 각성 수준',
      question: '지금 얼마나 긴장되거나 흥분되어 있나요?',
      child: Column(
        children: [
          _buildOptionButton('매우 흥분됨', q2Arousal == 4, () => setState(() => q2Arousal = 4), emoji: '😤'),
          const SizedBox(height: 12),
          _buildOptionButton('흥분됨', q2Arousal == 3, () => setState(() => q2Arousal = 3), emoji: '😃'),
          const SizedBox(height: 12),
          _buildOptionButton('보통', q2Arousal == 2, () => setState(() => q2Arousal = 2), emoji: '😊'),
          const SizedBox(height: 12),
          _buildOptionButton('차분함', q2Arousal == 1, () => setState(() => q2Arousal = 1), emoji: '😌'),
          const SizedBox(height: 12),
          _buildOptionButton('매우 차분함', q2Arousal == 0, () => setState(() => q2Arousal = 0), emoji: '😴'),
        ],
      ),
    );
  }

  // Q3: Attention - 주의 집중 정도
  Widget _buildQ3Attention() {
    return _buildQuestionPage(
      title: 'Q3. 집중력',
      question: '현재 얼마나 집중할 수 있나요?',
      child: Column(
        children: [
          _buildOptionButton('매우 집중됨', q3Attention == 4, () => setState(() => q3Attention = 4), emoji: '🎯'),
          const SizedBox(height: 12),
          _buildOptionButton('집중됨', q3Attention == 3, () => setState(() => q3Attention = 3), emoji: '👀'),
          const SizedBox(height: 12),
          _buildOptionButton('보통', q3Attention == 2, () => setState(() => q3Attention = 2), emoji: '😐'),
          const SizedBox(height: 12),
          _buildOptionButton('집중 안됨', q3Attention == 1, () => setState(() => q3Attention = 1), emoji: '😑'),
          const SizedBox(height: 12),
          _buildOptionButton('전혀 집중 안됨', q3Attention == 0, () => setState(() => q3Attention = 0), emoji: '😵‍💫'),
        ],
      ),
    );
  }

  // Q4: Stress - 스트레스 수준
  Widget _buildQ4Stress() {
    return _buildQuestionPage(
      title: 'Q4. 스트레스',
      question: '현재 느끼는 스트레스 수준은?',
      child: Column(
        children: [
          _buildOptionButton('매우 높음', q4Stress == 4, () => setState(() => q4Stress = 4), emoji: '😰'),
          const SizedBox(height: 12),
          _buildOptionButton('높음', q4Stress == 3, () => setState(() => q4Stress = 3), emoji: '😟'),
          const SizedBox(height: 12),
          _buildOptionButton('보통', q4Stress == 2, () => setState(() => q4Stress = 2), emoji: '😐'),
          const SizedBox(height: 12),
          _buildOptionButton('약간 있음', q4Stress == 1, () => setState(() => q4Stress = 1), emoji: '🙂'),
          const SizedBox(height: 12),
          _buildOptionButton('스트레스 없음', q4Stress == 0, () => setState(() => q4Stress = 0), emoji: '😊'),
        ],
      ),
    );
  }

  // Q5: Emotion Duration - 감정 지속 시간
  Widget _buildQ5Duration() {
    return _buildQuestionPage(
      title: 'Q5. 감정 지속 시간',
      question: '이 감정을 얼마나 오래 느끼고 있나요?',
      child: Column(
        children: [
          _buildOptionButton('하루 이상', q5Duration == 4, () => setState(() => q5Duration = 4), emoji: '📅'),
          const SizedBox(height: 12),
          _buildOptionButton('수 시간 전부터', q5Duration == 3, () => setState(() => q5Duration = 3), emoji: '⏰'),
          const SizedBox(height: 12),
          _buildOptionButton('약 1시간 전부터', q5Duration == 2, () => setState(() => q5Duration = 2), emoji: '⏱️'),
          const SizedBox(height: 12),
          _buildOptionButton('몇 분 전부터', q5Duration == 1, () => setState(() => q5Duration = 1), emoji: '⏲️'),
          const SizedBox(height: 12),
          _buildOptionButton('방금 느끼기 시작했어요', q5Duration == 0, () => setState(() => q5Duration = 0), emoji: '⚡'),
        ],
      ),
    );
  }

  // Q6: Task Disturbance - 과업 방해 정도
  Widget _buildQ6Disturbance() {
    return _buildQuestionPage(
      title: 'Q6. 업무/활동 영향',
      question: '이 감정이 현재 하고 있는 일에 영향을 주나요?',
      child: Column(
        children: [
          _buildOptionButton('매우 심각하게 방해됨', q6Disturbance == 4, () => setState(() => q6Disturbance = 4), emoji: '🚫'),
          const SizedBox(height: 12),
          _buildOptionButton('많이 방해됨', q6Disturbance == 3, () => setState(() => q6Disturbance = 3), emoji: '⚠️'),
          const SizedBox(height: 12),
          _buildOptionButton('보통 방해됨', q6Disturbance == 2, () => setState(() => q6Disturbance = 2), emoji: '😕'),
          const SizedBox(height: 12),
          _buildOptionButton('약간 방해됨', q6Disturbance == 1, () => setState(() => q6Disturbance = 1), emoji: '😐'),
          const SizedBox(height: 12),
          _buildOptionButton('전혀 방해되지 않음', q6Disturbance == 0, () => setState(() => q6Disturbance = 0), emoji: '✅'),
        ],
      ),
    );
  }

  // Q7: Emotion Change - 감정 변화
  Widget _buildQ7Change() {
    return _buildQuestionPage(
      title: 'Q7. 감정 변화',
      question: '최근 감정이 어떻게 변화했나요?',
      child: Column(
        children: [
          _buildOptionButton('매우 좋아지고 있어요', q7Change == 4, () => setState(() => q7Change = 4), emoji: '📈'),
          const SizedBox(height: 12),
          _buildOptionButton('약간 좋아지고 있어요', q7Change == 3, () => setState(() => q7Change = 3), emoji: '↗️'),
          const SizedBox(height: 12),
          _buildOptionButton('변화 없음 (같은 상태)', q7Change == 2, () => setState(() => q7Change = 2), emoji: '➡️'),
          const SizedBox(height: 12),
          _buildOptionButton('약간 나빠지고 있어요', q7Change == 1, () => setState(() => q7Change = 1), emoji: '↘️'),
          const SizedBox(height: 12),
          _buildOptionButton('매우 나빠지고 있어요', q7Change == 0, () => setState(() => q7Change = 0), emoji: '📉'),
        ],
      ),
    );
  }

  // 일기 입력 페이지
  Widget _buildDiaryPage() {
    return _buildQuestionPage(
      title: '일기 쓰기',
      question: '오늘 하루를 기록해보세요',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: TextField(
          controller: _diaryController,
          maxLines: 12,
          onChanged: (value) {
            // 텍스트 변경 시 상태 업데이트하여 버튼 활성화/비활성화
            setState(() {});
          },
          decoration: const InputDecoration(
            hintText: '오늘 하루 있었던 일, 느낀 점, 생각 등을 자유롭게 적어주세요...',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(20),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage({
    required String title,
    required String question,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String label, VoidCallback onTap) {
    bool isSelected = false;
    if (emoji == '😊') isSelected = q1Valence == 4;
    if (emoji == '🙂') isSelected = q1Valence == 3;
    if (emoji == '😐') isSelected = q1Valence == 2;
    if (emoji == '☹️') isSelected = q1Valence == 1;
    if (emoji == '😞') isSelected = q1Valence == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: isSelected ? Colors.black87 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String label, bool isSelected, VoidCallback onTap, {String? emoji}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: emoji != null
            ? Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 15),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.black87 : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
      ),
    );
  }
}

