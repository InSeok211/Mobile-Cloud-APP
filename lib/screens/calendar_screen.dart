import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/emotion_survey.dart';
import '../models/diary.dart';
import '../models/activity_survey.dart';
import 'diary_screen.dart';
import 'survey_screen.dart';
import 'history_screen.dart';
import 'activity_survey_screen.dart';

// 캘린더 화면
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  int? _userId;
  Map<String, EmotionSurvey> _emotionData = {};
  Map<String, Diary> _diaryData = {};
  Map<String, ActivitySurvey> _activityData = {};
  bool _isLoading = true;
  Map<int, double> _weeklyMoodData = {}; // 요일별 마음온도 (0=일요일 ~ 6=토요일)
  double _averageWeeklyMood = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId == null) return;

    setState(() {
      _userId = userId;
    });

    await _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 월의 시작과 끝
      final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);

      // 감정 설문 데이터 로드
      final surveys = await DatabaseHelper.instance.getEmotionSurveysByDateRange(
        _userId!,
        startOfMonth,
        endOfMonth,
      );

      // 일기 데이터 로드
      final diaries = await DatabaseHelper.instance.getDiariesByUser(_userId!);

      // 활동 문답표 데이터 로드
      final activities = await DatabaseHelper.instance.getActivitySurveysByDateRange(
        _userId!,
        startOfMonth,
        endOfMonth,
      );

      // 이번 주 마음온도 데이터 계산
      await _calculateWeeklyMood();

      // Map으로 변환 (날짜별로)
      Map<String, EmotionSurvey> emotionMap = {};
      for (var survey in surveys) {
        final dateKey = '${survey.date.year}-${survey.date.month.toString().padLeft(2, '0')}-${survey.date.day.toString().padLeft(2, '0')}';
        emotionMap[dateKey] = survey;
      }

      Map<String, Diary> diaryMap = {};
      for (var diary in diaries) {
        final dateKey = '${diary.date.year}-${diary.date.month.toString().padLeft(2, '0')}-${diary.date.day.toString().padLeft(2, '0')}';
        // 현재 월에 속하는 일기만
        if (diary.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            diary.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
          // 같은 날짜의 일기가 이미 있으면, 더 최근에 작성된 것만 저장 (createdAt 비교)
          if (diaryMap.containsKey(dateKey)) {
            if (diary.createdAt.isAfter(diaryMap[dateKey]!.createdAt)) {
              diaryMap[dateKey] = diary;
            }
          } else {
            diaryMap[dateKey] = diary;
          }
        }
      }

      Map<String, ActivitySurvey> activityMap = {};
      for (var activity in activities) {
        final dateKey = '${activity.date.year}-${activity.date.month.toString().padLeft(2, '0')}-${activity.date.day.toString().padLeft(2, '0')}';
        activityMap[dateKey] = activity;
      }

      setState(() {
        _emotionData = emotionMap;
        _diaryData = diaryMap;
        _activityData = activityMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateWeeklyMood() async {
    if (_userId == null) return;

    // 현재 주의 일요일과 토요일 계산
    final now = DateTime.now();
    final weekday = now.weekday % 7; // 일요일=0, 월요일=1, ..., 토요일=6
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    // 이번 주 감정 설문 데이터 로드
    final weeklySurveys = await DatabaseHelper.instance.getEmotionSurveysByDateRange(
      _userId!,
      startOfWeek,
      endOfWeek,
    );

    // 요일별 마음온도 계산 (마음온도 = (valence + 1) * 50, 0~100 범위)
    Map<int, double> weekData = {};
    for (var survey in weeklySurveys) {
      final dayOfWeek = survey.date.weekday % 7; // 일요일=0, 월요일=1, ..., 토요일=6
      final moodScore = (survey.valence + 1) * 50; // -1~1을 0~100으로 변환
      
      // 같은 날 여러 설문이 있으면 평균
      if (weekData.containsKey(dayOfWeek)) {
        weekData[dayOfWeek] = (weekData[dayOfWeek]! + moodScore) / 2;
      } else {
        weekData[dayOfWeek] = moodScore;
      }
    }

    // 평균 마음온도 계산
    double average = 0;
    if (weekData.isNotEmpty) {
      average = weekData.values.reduce((a, b) => a + b) / weekData.length;
    }

    setState(() {
      _weeklyMoodData = weekData;
      _averageWeeklyMood = average;
    });
  }

  Color _getColorForEmotion(EmotionSurvey survey) {
    // 스트레스 수준에 따라 색상 결정
    if (survey.stress >= 4) return Colors.red;
    if (survey.stress >= 3) return Colors.orange;
    if (survey.stress >= 2) return Colors.yellow;
    return Colors.green;
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
        title: const Text(
          '마음온도',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 월간 달력
              _buildMonthCalendar(),
              const SizedBox(height: 30),
              // 하단 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomButton(
                    Icons.edit_note,
                    '일기 쓰기',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiaryScreen(),
                        ),
                      );
                      await _loadMonthData(); // 돌아왔을 때 데이터 새로고침 (await 추가)
                    },
                  ),
                  _buildBottomButton(
                    Icons.assignment,
                    '감정 설문지',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SurveyScreen(),
                        ),
                      );
                      await _loadMonthData(); // 돌아왔을 때 데이터 새로고침 (await 추가)
                    },
                  ),
                  _buildBottomButton(
                    Icons.bar_chart,
                    '지난 감정\n결과',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildBottomButton(
                    Icons.auto_awesome,
                    '오늘의\n활동 문답표',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivitySurveyScreen(),
                        ),
                      );
                      await _loadMonthData(); // 돌아왔을 때 데이터 새로고침 (await 추가)
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // 선택된 날짜 상세 정보
              if (_selectedDate != null) _buildSelectedDateInfo(),
              if (_selectedDate != null) const SizedBox(height: 30),
              // 이번 주 마음온도 그래프
              _buildWeeklyMoodGraph(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCalendar() {
    return Column(
      children: [
        // 월/년 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month - 1,
                  );
                  _selectedDate = null;
                });
                _loadMonthData();
              },
            ),
            Text(
              '${_currentMonth.year}.${_currentMonth.month}월',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month + 1,
                  );
                  _selectedDate = null;
                });
                _loadMonthData();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 요일 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
            return SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 15),
        // 날짜 그리드
        _buildDateGrid(),
      ],
    );
  }

  Widget _buildDateGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 일요일 = 0
    
    List<Widget> dateWidgets = [];
    
    // 빈 칸 추가 (이전 달)
    for (int i = 0; i < firstWeekday; i++) {
      dateWidgets.add(const SizedBox(width: 40, height: 50));
    }
    
    // 날짜 추가
    final today = DateTime.now();
    
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hasEmotion = _emotionData.containsKey(dateKey);
      final hasDiary = _diaryData.containsKey(dateKey);
      final hasActivity = _activityData.containsKey(dateKey);
      final hasData = hasEmotion || hasDiary || hasActivity;
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      
      dateWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              // 같은 날짜를 다시 클릭하면 선택 해제, 다른 날짜를 클릭하면 선택
              if (_selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day) {
                _selectedDate = null; // 토글: 숨기기
              } else {
                _selectedDate = date; // 새로운 날짜 선택
              }
            });
          },
          child: Container(
            width: 40,
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF5B9BD5)
                        : isToday
                            ? Colors.black87
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 16,
                        color: (isSelected || isToday) ? Colors.white : Colors.black87,
                        fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                if (hasData)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasEmotion 
                          ? _getColorForEmotion(_emotionData[dateKey]!)
                          : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    // 마지막 주를 7칸으로 맞추기 위해 빈 칸 추가
    while (dateWidgets.length % 7 != 0) {
      dateWidgets.add(const SizedBox(width: 40, height: 50));
    }
    
    // 주 단위로 정렬
    List<Widget> rows = [];
    for (int i = 0; i < dateWidgets.length; i += 7) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dateWidgets.skip(i).take(7).toList(),
        ),
      );
      if (i + 7 < dateWidgets.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    
    return Column(children: rows);
  }

  Widget _buildBottomButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4F8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 32, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateInfo() {
    final dateKey = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final emotionSurvey = _emotionData[dateKey];
    final diary = _diaryData[dateKey];
    final activitySurvey = _activityData[dateKey];
    
    if (emotionSurvey == null && diary == null && activitySurvey == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            '이 날짜에는 기록이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedDate!.year}.${_selectedDate!.month}.${_selectedDate!.day} (${_getWeekday(_selectedDate!)})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // 감정 설문 정보
          if (emotionSurvey != null) ...[
            Row(
              children: [
                Text(
                  emotionSurvey.getEmoji(),
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emotionSurvey.getEmotionState() + ' 상태',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'V: ${emotionSurvey.valence.toStringAsFixed(2)} / A: ${emotionSurvey.arousal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '스트레스: ${emotionSurvey.stress}/4',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (emotionSurvey.tags != null && emotionSurvey.tags!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emotionSurvey.tags!.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
          
          // 일기 정보
          if (diary != null) ...[
            if (emotionSurvey != null) const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      const Text(
                        '일기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    diary.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          
          // 활동 문답표 정보
          if (activitySurvey != null) ...[
            if (emotionSurvey != null || diary != null) const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      const Text(
                        '오늘의 활동',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...activitySurvey.activities.map((activity) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            activity.getImpactEmoji(),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activity.activityName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activity.getImpactText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8F4F8),
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return weekdays[date.weekday % 7];
  }

  Widget _buildWeeklyMoodGraph() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '이번 주 마음온도',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (_weeklyMoodData.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '평균 ${_averageWeeklyMood.toInt()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B9BD5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_weeklyMoodData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  '이번 주 감정 설문 기록이 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  maxY: 100,
                  minY: 0,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black87,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final weekday = ['일', '월', '화', '수', '목', '금', '토'][spot.x.toInt()];
                          return LineTooltipItem(
                            '$weekday\n${spot.y.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
                          if (value < 0 || value >= 7) return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              weekdays[value.toInt()],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.black12,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.black26, width: 1),
                      left: BorderSide(color: Colors.black26, width: 1),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildLineChartSpots(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: const Color(0xFF5B9BD5),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: _getMoodColor(spot.y),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF5B9BD5).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<FlSpot> _buildLineChartSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      if (_weeklyMoodData.containsKey(i)) {
        spots.add(FlSpot(i.toDouble(), _weeklyMoodData[i]!));
      }
    }
    return spots;
  }

  Color _getMoodColor(double moodValue) {
    if (moodValue >= 75) return Colors.green;
    if (moodValue >= 50) return const Color(0xFF5B9BD5);
    if (moodValue >= 25) return Colors.orange;
    return Colors.red;
  }
}

