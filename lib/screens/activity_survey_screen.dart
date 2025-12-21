import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/activity_survey.dart';

// 활동 문답표 화면
class ActivitySurveyScreen extends StatefulWidget {
  const ActivitySurveyScreen({super.key});

  @override
  State<ActivitySurveyScreen> createState() => _ActivitySurveyScreenState();
}

class _ActivitySurveyScreenState extends State<ActivitySurveyScreen> {
  final Map<String, ActivityItem> _selectedActivities = {};
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _hasExistingData = false; // 기존 데이터 존재 여부

  @override
  void initState() {
    super.initState();
    _loadTodayActivitySurvey();
  }

  Future<void> _loadTodayActivitySurvey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId != null) {
        // 오늘 날짜의 기존 활동 문답표 확인
        final existingActivitySurvey = await DatabaseHelper.instance.getActivitySurveyByDate(
          userId,
          DateTime.now(),
        );

        if (existingActivitySurvey != null && mounted) {
          setState(() {
            _hasExistingData = true;
            // 기존 활동들을 _selectedActivities에 추가
            for (var item in existingActivitySurvey.activities) {
              _selectedActivities[item.activityName] = item;
            }
          });
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _hasExistingData ? '오늘의 활동 수정하기' : '오늘의 활동 문답표',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          // 상단 설명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4F8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasExistingData 
                      ? '오늘의 활동을 수정하고,' 
                      : '오늘 하신 활동을 선택하고,',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const Text(
                  '각 활동이 기분에 미친 영향을 평가해주세요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // 활동 목록
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ActivityType.allActivities.map((activityName) {
                return _buildActivityCard(activityName);
              }).toList(),
            ),
          ),
          
          // 제출 버튼
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _selectedActivities.isEmpty || _isSubmitting
                    ? null
                    : _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B9BD5),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _hasExistingData 
                            ? '수정하기 (${_selectedActivities.length}개 활동)'
                            : '제출하기 (${_selectedActivities.length}개 활동)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String activityName) {
    final isSelected = _selectedActivities.containsKey(activityName);
    final impact = isSelected ? _selectedActivities[activityName]!.impact : 3;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isSelected ? const Color(0xFF5B9BD5) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 활동명과 체크박스
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedActivities[activityName] = ActivityItem(
                          activityName: activityName,
                          impact: 3, // 기본값 "보통"
                        );
                      } else {
                        _selectedActivities.remove(activityName);
                      }
                    });
                  },
                  activeColor: const Color(0xFF5B9BD5),
                ),
                const SizedBox(width: 8),
                Text(
                  activityName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            // 선택되었을 때만 영향 평가 슬라이더 표시
            if (isSelected) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '이 활동이 기분에 미친 영향',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: impact.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: const Color(0xFF5B9BD5),
                      label: ActivityItem(
                        activityName: activityName,
                        impact: impact,
                      ).getImpactText(),
                      onChanged: (value) {
                        setState(() {
                          _selectedActivities[activityName] = ActivityItem(
                            activityName: activityName,
                            impact: value.toInt(),
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ActivityItem(
                      activityName: activityName,
                      impact: impact,
                    ).getImpactEmoji(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ],
              ),
              Text(
                ActivityItem(
                  activityName: activityName,
                  impact: impact,
                ).getImpactText(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitSurvey() async {
    if (_selectedActivities.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다.');
      }

      // 오늘 날짜의 기존 활동 문답표 확인
      final existingActivitySurvey = await DatabaseHelper.instance.getActivitySurveyByDate(
        userId,
        DateTime.now(),
      );

      if (existingActivitySurvey != null) {
        // 기존 활동 문답표가 있으면 삭제
        await DatabaseHelper.instance.deleteActivitySurvey(existingActivitySurvey.id!);
      }

      // ActivitySurvey 객체 생성
      final now = DateTime.now();
      final dateOnly = DateTime(now.year, now.month, now.day); // 시간 제거, 날짜만
      
      final activitySurvey = ActivitySurvey(
        userId: userId,
        date: dateOnly,
        activities: _selectedActivities.values.toList(),
      );

      // 데이터베이스에 저장
      await DatabaseHelper.instance.saveActivitySurvey(activitySurvey);

      if (mounted) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingActivitySurvey != null 
                ? '활동 문답표가 수정되었습니다!' 
                : '활동 문답표가 저장되었습니다!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 이전 화면으로 돌아가기
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true); // true를 전달하여 저장 성공을 알림
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

