import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/diary.dart';

// 일기 쓰기 화면
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _diaryController = TextEditingController();
  bool _isLoading = false;
  int? _userId;
  Diary? _existingDiary; // 기존 일기 저장

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadTodayDiary();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
  }

  Future<void> _loadTodayDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId == null) return;

    // 오늘 날짜의 일기가 있는지 확인
    final existingDiary = await DatabaseHelper.instance.getDiaryByDate(
      userId,
      DateTime.now(),
    );

    if (existingDiary != null && mounted) {
      setState(() {
        _existingDiary = existingDiary; // 기존 일기 저장
        _diaryController.text = existingDiary.content;
      });
    }
  }

  Future<void> _saveDiary() async {
    if (_diaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기 내용을 입력해주세요')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_existingDiary != null) {
        // 기존 일기가 있으면 업데이트
        final updatedDiary = _existingDiary!.copyWith(
          content: _diaryController.text,
          createdAt: DateTime.now(), // 수정 시 createdAt도 업데이트
        );
        await DatabaseHelper.instance.updateDiary(updatedDiary);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('일기가 수정되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // 새 일기 저장
        final now = DateTime.now();
        final dateOnly = DateTime(now.year, now.month, now.day); // 시간 제거, 날짜만
        
        final diary = Diary(
          userId: _userId!,
          content: _diaryController.text,
          date: dateOnly,
        );

        await DatabaseHelper.instance.saveDiary(diary);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('일기가 저장되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일기 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _diaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 뒤로가기 버튼
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF5A5A5A)),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 로고
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: 3),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '마음온도',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A5A5A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // 제목
              Text(
                _existingDiary != null ? '오늘의 일기 수정하기' : '오늘 하루는 어땠나요?',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF5A5A5A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              // 일기 입력 박스
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: TextField(
                    controller: _diaryController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: '일기를 작성하세요.',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFB0B0B0),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDiary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A5A5A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _existingDiary != null ? '수정' : '저장',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

