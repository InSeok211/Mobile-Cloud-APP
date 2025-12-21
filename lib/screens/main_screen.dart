import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'survey_screen.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

// 메인 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime selectedDate = DateTime.now();
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('isLoggedIn');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 로그아웃 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black87),
                    onPressed: _logout,
                    tooltip: '로그아웃',
                  ),
                ],
              ),
              // 로고
              _buildLogo(),
              const SizedBox(height: 40),
              // 달력
              _buildCalendar(),
              const SizedBox(height: 40),
              // 메뉴 버튼들
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuButton(
                      icon: Icons.assignment,
                      text: '감정 설문지',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SurveyScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildMenuButton(
                      icon: Icons.calendar_month,
                      text: '캘린더',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildMenuButton(
                      icon: Icons.access_time,
                      text: '지난 감정 결과',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade400, width: 2),
          ),
          child: const Icon(
            Icons.thermostat,
            size: 30,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '마음온도',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    DateTime now = DateTime.now();
    // 일요일을 주의 시작으로 계산 (weekday: 월=1, 일=7)
    int daysFromSunday = now.weekday % 7; // 일요일=0, 월요일=1, ..., 토요일=6
    DateTime startOfWeek = now.subtract(Duration(days: daysFromSunday));
    
    return Column(
      children: [
        // 요일
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
        // 날짜
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            DateTime date = startOfWeek.add(Duration(days: index));
            bool isToday = date.day == now.day && 
                          date.month == now.month && 
                          date.year == now.year;
            
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isToday ? Colors.black87 : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isToday ? Colors.black87 : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isToday ? Colors.white : Colors.black87,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.black87),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

