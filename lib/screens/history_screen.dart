import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/emotion_survey.dart';
import '../models/diary.dart';

// 진단 기록 화면
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<EmotionSurvey> _surveys = [];
  Map<String, Diary> _diaryMap = {};
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _userId = userId;
    });

    try {
      // 감정 설문 데이터 로드
      final surveys = await DatabaseHelper.instance.getEmotionSurveysByUser(userId);
      
      // 일기 데이터 로드
      final diaries = await DatabaseHelper.instance.getDiariesByUser(userId);
      
      // 날짜별로 일기 맵 생성
      Map<String, Diary> diaryMap = {};
      for (var diary in diaries) {
        final dateKey = '${diary.date.year}-${diary.date.month.toString().padLeft(2, '0')}-${diary.date.day.toString().padLeft(2, '0')}';
        diaryMap[dateKey] = diary;
      }

      setState(() {
        _surveys = surveys;
        _diaryMap = diaryMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
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
              '지난 감정 결과',
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
          ? const Center(child: CircularProgressIndicator())
          : _surveys.isEmpty
              ? const Center(
                  child: Text(
                    '아직 기록된 감정 설문이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _surveys.length,
                  itemBuilder: (context, index) {
                    final survey = _surveys[index];
                    final dateKey = '${survey.date.year}-${survey.date.month.toString().padLeft(2, '0')}-${survey.date.day.toString().padLeft(2, '0')}';
                    final diary = _diaryMap[dateKey];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜와 이모지
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(survey.date),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    survey.getEmotionState() + ' 상태',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                survey.getEmoji(),
                                style: const TextStyle(fontSize: 40),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // V/A 및 스트레스
                          Row(
                            children: [
                              _buildInfoChip(
                                'V: ${survey.valence.toStringAsFixed(2)}',
                                Colors.blue.shade50,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                'A: ${survey.arousal.toStringAsFixed(2)}',
                                Colors.purple.shade50,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                'Stress: ${survey.stress}/4',
                                _getStressColor(survey.stress),
                              ),
                            ],
                          ),
                          
                          // 일기 미리보기
                          if (diary != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.edit_note,
                                        size: 16,
                                        color: Colors.black87,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '일기',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    diary.content,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // 태그
                          if (survey.tags != null && survey.tags!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: survey.tags!.map((tag) {
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
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Color _getStressColor(int stress) {
    if (stress >= 4) return Colors.red.shade100;
    if (stress >= 3) return Colors.orange.shade100;
    if (stress >= 2) return Colors.yellow.shade100;
    return Colors.green.shade100;
  }
}

