import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/emotion_survey.dart';
import '../models/diary.dart';
import '../config/api_config.dart';

// 설문 결과 화면
class SurveyResultScreen extends StatefulWidget {
  final Map<String, dynamic> surveyResult;

  const SurveyResultScreen({super.key, required this.surveyResult});

  @override
  State<SurveyResultScreen> createState() => _SurveyResultScreenState();
}

class _SurveyResultScreenState extends State<SurveyResultScreen> {
  String _feedback = '';
  bool _isLoading = true;
  String? _summaryTitle;
  String? _empathyMessage;
  String? _actionTip;

  @override
  void initState() {
    super.initState();
    // Gemini API를 사용한 피드백 생성 시도
    _generateFeedbackWithGemini();
    _saveSurveyToDatabase();
  }

  // Gemini API를 사용한 피드백 생성
  Future<void> _generateFeedbackWithGemini() async {
    try {
      // API 키 확인
      if (!ApiConfig.isGeminiApiKeySet) {
        // API 키가 없으면 기본 피드백 사용
        _generateFeedback();
        return;
      }

      // 설문 결과 데이터 추출
      double valence = widget.surveyResult['valence'];
      double arousal = widget.surveyResult['arousal'];
      int stress = widget.surveyResult['stress'];
      int attention = widget.surveyResult['attention'];
      int disturbance = widget.surveyResult['disturbance'];
      int change = widget.surveyResult['change'];
      String diaryContent = widget.surveyResult['diaryContent'] ?? '';

      // Gemini 모델 초기화
      // 여러 모델명을 순차적으로 시도 (API 호출 시점에 모델이 지원되는지 확인)
      GenerativeModel? model;
      List<String> modelNames = [
        'gemini-2.5-flash', // 최신 모델 (예시 코드에서 사용)
        'gemini-2.0-flash-exp',
        'gemini-1.5-pro-latest',
        'gemini-1.5-flash-latest',
        'gemini-1.5-pro',
        'gemini-1.5-flash',
      ];
      
      // 먼저 첫 번째 모델로 초기화
      model = GenerativeModel(
        model: modelNames[0],
        apiKey: ApiConfig.geminiApiKey,
      );

      // 프롬프트 생성
      String prompt = _buildPrompt(
        valence,
        arousal,
        stress,
        attention,
        disturbance,
        change,
        diaryContent,
      );

      // Gemini API 호출 (여러 모델 시도)
      GenerateContentResponse? response;
      Exception? lastException;
      
      for (String modelName in modelNames) {
        try {
          final testModel = GenerativeModel(
            model: modelName,
            apiKey: ApiConfig.geminiApiKey,
          );
          response = await testModel.generateContent([Content.text(prompt)]);
          break; // 성공하면 루프 종료
        } catch (e) {
          lastException = e as Exception;
          if (modelName == modelNames.last) {
            // 모든 모델 실패 시 예외 던지기
            throw lastException;
          }
        }
      }
      
      if (response == null) {
        throw Exception('모든 모델 시도 실패');
      }
      
      if (mounted) {
        String responseText = response.text ?? '';
        
        // JSON 응답 파싱 시도
        try {
          // JSON 부분만 추출 (마크다운 코드 블록 제거)
          String jsonText = responseText;
          if (jsonText.contains('```json')) {
            jsonText = jsonText.split('```json')[1].split('```')[0].trim();
          } else if (jsonText.contains('```')) {
            jsonText = jsonText.split('```')[1].split('```')[0].trim();
          }
          
          // JSON 파싱
          final jsonData = json.decode(jsonText) as Map<String, dynamic>;
          
          setState(() {
            _summaryTitle = jsonData['summary_title'] as String?;
            _empathyMessage = jsonData['empathy_message'] as String?;
            _actionTip = jsonData['action_tip'] as String?;
            
            // UI 표시용 피드백 구성
            _feedback = '';
            if (_summaryTitle != null) {
              _feedback += '$_summaryTitle\n\n';
            }
            if (_empathyMessage != null) {
              _feedback += '$_empathyMessage\n\n';
            }
            if (_actionTip != null) {
              _feedback += '💡 $_actionTip';
            }
            
            _isLoading = false;
          });
        } catch (e) {
          // JSON 파싱 실패 시 원본 텍스트 사용
          setState(() {
            _feedback = responseText.isNotEmpty 
                ? responseText 
                : '피드백을 생성하는 중 오류가 발생했습니다.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // 오류 발생 시 기본 피드백 사용
      if (mounted) {
        _generateFeedback();
      }
    }
  }

  // Gemini API용 프롬프트 생성
  String _buildPrompt(
    double valence,
    double arousal,
    int stress,
    int attention,
    int disturbance,
    int change,
    String diaryContent,
  ) {
    // Stress를 0-100 범위로 변환 (현재는 0-4)
    int stressPercent = (stress * 25).clamp(0, 100);
    
    // Valence를 -1.0 ~ +1.0 범위로 변환 (현재는 -2 ~ +2)
    double normalizedValence = (valence / 2.0).clamp(-1.0, 1.0);
    
    // Arousal을 -1.0 ~ +1.0 범위로 변환 (현재는 0 ~ 1)
    double normalizedArousal = (arousal * 2.0 - 1.0).clamp(-1.0, 1.0);

    String prompt = '''# Role (역할 정의)

당신은 '마음온도' 앱의 AI 심리 상담가입니다.

당신은 Russell의 감정 모델(Valence-Arousal)과 인지행동치료(CBT) 기법을 기반으로 사용자의 마음을 치유합니다.

당신의 말투는 따뜻하고, 공감적이며, 전문적이어야 합니다. (해요체 사용)

# Goal (목표)

사용자가 입력한 감정 수치(V/A)와 일기 내용을 분석하여, 

1) 사용자의 현재 감정 상태를 명확히 정의하고,

2) 일기 내용에서 감정의 원인을 찾아 공감하며,

3) 구체적인 행동 지침(Action Plan)을 제공하세요.

# Input Data (입력 변수 설명)

1. Valence (쾌-불쾌): ${normalizedValence.toStringAsFixed(2)} (-1.0: 매우 불쾌 ~ +1.0: 매우 유쾌)

2. Arousal (각성-이완): ${normalizedArousal.toStringAsFixed(2)} (-1.0: 매우 이완/졸림 ~ +1.0: 매우 각성/긴장)

3. Stress: $stressPercent (0 ~ 100, 높을수록 스트레스 심함)

4. Diary: ${diaryContent.isNotEmpty ? diaryContent : '없음'}

# Guidelines for Variability (답변의 다양성 및 개인화 규칙) ★핵심

동일한 감정 점수라도 매번 다른 답변을 주기 위해 아래 규칙을 따르세요.

1. **일기가 있는 경우 (Priority: High):**

   - V/A 점수보다 '일기 내용'에 70%의 비중을 두세요.

   - 일기 속의 사건(Fact)과 감정(Emotion)을 연결하여 피드백하세요.

   - 텍스트에서 사용자의 '인지적 왜곡(과도한 일반화, 흑백논리 등)'이 보이면 이를 부드럽게 재해석(Reframing) 해주세요.

2. **일기가 없는 경우:**

   - V/A 좌표에 따라 현재 상태를 설명하되, 매번 다른 **'심리적 은유(Metaphor)'**를 사용하세요.

   - (예시: 날씨, 바다의 파도, 마음의 정원, 배터리 충전 등 다양한 비유 활용)

3. **CBT 기법 랜덤 적용:**

   - 답변의 끝부분에 제안하는 솔루션을 매번 조금씩 다르게 가져가세요.

   - (옵션: 호흡법, 그라운딩 기법, 감사 일기 쓰기, 오감 집중하기, 가벼운 스트레칭 중 상황에 맞는 것 1개 선택)

# Safety Protocol (안전 수칙)

- 사용자의 텍스트에서 자살, 자해, 죽음, 심각한 범죄 예고가 감지되면, 모든 상담을 중단하고 즉시 "전문가나 기관의 도움이 필요할 수 있습니다"라는 메시지와 함께 관련 핫라인 번호를 출력하세요.

# Output Format (출력 형식)

반드시 다음 JSON 포맷으로 출력하세요. (사용자에게는 JSON을 파싱해서 예쁘게 보여줄 예정)

{
  "summary_title": "한 줄 요약 (예: 비 온 뒤 맑음 같은 마음이네요)",
  "empathy_message": "공감 및 분석 메시지 (3~4문장)",
  "action_tip": "오늘의 추천 행동 (1문장)"
}

JSON만 출력하세요. 다른 설명이나 텍스트는 포함하지 마세요.''';

    return prompt;
  }

  Future<void> _saveSurveyToDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      if (userId == null) return;

      // 오늘 날짜의 기존 설문 확인
      final existingSurvey = await DatabaseHelper.instance.getEmotionSurveyByDate(
        userId,
        DateTime.now(),
      );

      if (existingSurvey != null) {
        // 기존 설문이 있으면 삭제 후 새로 저장 (업데이트와 동일한 효과)
        await DatabaseHelper.instance.deleteEmotionSurvey(existingSurvey.id!);
      }

      // 새 설문 저장
      final now = DateTime.now();
      final dateOnly = DateTime(now.year, now.month, now.day); // 시간 제거, 날짜만
      
      final survey = EmotionSurvey(
        userId: userId,
        valence: widget.surveyResult['valence'],
        arousal: widget.surveyResult['arousal'],
        stress: widget.surveyResult['stress'],
        attention: widget.surveyResult['attention'],
        duration: widget.surveyResult['duration'],
        disturbance: widget.surveyResult['disturbance'],
        change: widget.surveyResult['change'],
        date: dateOnly,
      );

      await DatabaseHelper.instance.saveEmotionSurvey(survey);

      // 일기 내용도 저장
      String diaryContent = widget.surveyResult['diaryContent'] ?? '';
      if (diaryContent.isNotEmpty) {
        // 오늘 날짜의 기존 일기 확인
        final existingDiary = await DatabaseHelper.instance.getDiaryByDate(
          userId,
          DateTime.now(),
        );

        if (existingDiary != null) {
          // 기존 일기가 있으면 업데이트
          final updatedDiary = existingDiary.copyWith(
            content: diaryContent,
            createdAt: DateTime.now(),
          );
          await DatabaseHelper.instance.updateDiary(updatedDiary);
        } else {
          // 새 일기 저장
          final now = DateTime.now();
          final dateOnly = DateTime(now.year, now.month, now.day);
          
          final diary = Diary(
            userId: userId,
            content: diaryContent,
            date: dateOnly,
          );
          await DatabaseHelper.instance.saveDiary(diary);
        }
      }
    } catch (e) {
      // 에러 발생 시 UI는 그대로 진행
    }
  }

  // 기본 피드백 생성 (Gemini API 실패 시 사용)
  void _generateFeedback() {
    // V/A 값에 따른 감정 상태 분석
    double valence = widget.surveyResult['valence'];
    double arousal = widget.surveyResult['arousal'];
    int stress = widget.surveyResult['stress'];
    int attention = widget.surveyResult['attention'];
    int disturbance = widget.surveyResult['disturbance'];
    int change = widget.surveyResult['change'];
    String diaryContent = widget.surveyResult['diaryContent'] ?? ''; // 일기 내용

    String emotionState = _getEmotionState(valence, arousal);
    String stressLevel = _getStressLevel(stress);
    String attentionLevel = _getAttentionLevel(attention);
    String changeStatus = _getChangeStatus(change);

    // AI 스타일의 피드백 생성
    String feedback = _createFeedback(
      emotionState,
      stressLevel,
      attentionLevel,
      changeStatus,
      valence,
      arousal,
      stress,
      disturbance,
      diaryContent, // 일기 내용 추가
    );

    setState(() {
      _feedback = feedback;
      _isLoading = false;
    });
  }

  String _getEmotionState(double valence, double arousal) {
    if (valence > 0.5 && arousal > 0.5) return '활기찬';
    if (valence > 0.5 && arousal <= 0.5) return '평온한';
    if (valence <= -0.5 && arousal > 0.5) return '긴장된';
    if (valence <= -0.5 && arousal <= 0.5) return '우울한';
    return '중립적인';
  }

  String _getStressLevel(int stress) {
    if (stress >= 4) return '매우 높은';
    if (stress == 3) return '높은';
    if (stress == 2) return '보통의';
    if (stress == 1) return '낮은';
    return '거의 없는';
  }

  String _getAttentionLevel(int attention) {
    if (attention >= 4) return '매우 높은';
    if (attention == 3) return '높은';
    if (attention == 2) return '보통의';
    if (attention == 1) return '낮은';
    return '매우 낮은';
  }

  String _getChangeStatus(int change) {
    if (change >= 4) return '많이 개선되고';
    if (change == 3) return '조금 좋아지고';
    if (change == 2) return '변화가 없고';
    if (change == 1) return '조금 나빠지고';
    return '많이 나빠지고';
  }

  String _createFeedback(
    String emotionState,
    String stressLevel,
    String attentionLevel,
    String changeStatus,
    double valence,
    double arousal,
    int stress,
    int disturbance,
    String diaryContent, // 일기 내용 추가
  ) {
    String feedback = '현재 당신의 감정 상태는 "$emotionState" 상태입니다.\n\n';

    // 일기 내용이 있으면 피드백에 포함
    if (diaryContent.isNotEmpty) {
      feedback += '오늘 하루를 기록해주신 내용을 보니, ';
      // 일기 내용의 감정 키워드 분석 (간단한 키워드 기반)
      if (diaryContent.contains('좋') || diaryContent.contains('행복') || diaryContent.contains('기쁨')) {
        feedback += '긍정적인 경험들이 있었던 것 같네요. ';
      } else if (diaryContent.contains('힘들') || diaryContent.contains('어려') || diaryContent.contains('스트레스')) {
        feedback += '오늘 하루가 쉽지 않으셨던 것 같습니다. ';
      } else if (diaryContent.contains('평범') || diaryContent.contains('보통')) {
        feedback += '평온한 하루를 보내셨네요. ';
      }
      feedback += '일기를 통해 자신의 감정과 경험을 정리하는 것은 매우 좋은 습관입니다.\n\n';
    }

    // 스트레스 관련 피드백
    if (stress >= 3) {
      feedback += '스트레스 수준이 $stressLevel 편이네요. ';
      feedback += '깊은 숨을 쉬며 잠시 휴식을 취하는 것은 어떨까요? ';
      feedback += '짧은 산책이나 스트레칭도 도움이 될 수 있습니다.\n\n';
    } else if (stress <= 1) {
      feedback += '스트레스가 $stressLevel 상태로 잘 관리되고 있네요! ';
      feedback += '현재의 평온한 상태를 잘 유지하고 계십니다.\n\n';
    }

    // 업무 방해 관련 피드백
    if (disturbance >= 3) {
      feedback += '감정이 일상생활에 많은 영향을 주고 있는 것 같습니다. ';
      feedback += '필요하다면 주변 사람들에게 도움을 요청하거나, 전문가와 상담하는 것을 고려해보세요.\n\n';
    }

    // 감정 변화 관련 피드백
    if (changeStatus.contains('개선') || changeStatus.contains('좋아')) {
      feedback += '감정이 ${changeStatus} 있다니 다행입니다! ';
      feedback += '긍정적인 변화가 계속되도록 현재 하고 있는 활동들을 이어가보세요.\n\n';
    } else if (changeStatus.contains('나빠')) {
      feedback += '최근 감정이 ${changeStatus} 있군요. ';
      feedback += '힘든 시기일 수 있지만, 이런 감정도 자연스러운 과정입니다. ';
      feedback += '스스로에게 친절하게 대해주세요.\n\n';
    }

    // 집중력 관련 피드백
    if (attentionLevel == '매우 낮은' || attentionLevel == '낮은') {
      feedback += '집중력이 $attentionLevel 상태입니다. ';
      feedback += '충분한 수면과 규칙적인 생활 패턴이 도움이 될 수 있습니다.\n\n';
    }

    // 마무리 메시지
    feedback += '오늘 하루도 수고하셨습니다. 당신의 감정을 돌아보는 것은 자기 돌봄의 중요한 첫걸음입니다. 💙';

    return feedback;
  }

  String _getEmoji(double valence, double arousal) {
    if (valence > 0.5 && arousal > 0.5) return '😄';
    if (valence > 0.5 && arousal <= 0.5) return '😊';
    if (valence > 0 && arousal > 0.5) return '🙂';
    if (valence > 0 && arousal <= 0.5) return '😌';
    if (valence < -0.5 && arousal > 0.5) return '😰';
    if (valence < -0.5 && arousal <= 0.5) return '😔';
    if (valence < 0 && arousal > 0.5) return '😟';
    if (valence < 0 && arousal <= 0.5) return '😐';
    return '😐';
  }

  @override
  Widget build(BuildContext context) {
    double valence = widget.surveyResult['valence'];
    double arousal = widget.surveyResult['arousal'];
    int stress = widget.surveyResult['stress'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '감정 분석 결과',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // V/A 값 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getEmoji(valence, arousal),
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _getEmotionState(valence, arousal) + ' 상태',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildValueBox('Valence', valence.toStringAsFixed(2)),
                            _buildValueBox('Arousal', arousal.toStringAsFixed(2)),
                            _buildValueBox('Stress', '$stress'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // AI 피드백
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology,
                              color: Color(0xFF5B9BD5),
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'AI 피드백',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _feedback,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 홈으로 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B9BD5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '홈으로 돌아가기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildValueBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

