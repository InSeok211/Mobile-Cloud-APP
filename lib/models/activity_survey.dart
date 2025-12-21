// 활동 문답표 모델
class ActivitySurvey {
  final int? id;
  final int userId;
  final DateTime date;
  final DateTime createdAt;
  final List<ActivityItem> activities;

  ActivitySurvey({
    this.id,
    required this.userId,
    required this.date,
    DateTime? createdAt,
    required this.activities,
  }) : createdAt = createdAt ?? DateTime.now();

  // Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Map에서 ActivitySurvey 객체 생성 (데이터베이스 읽기용)
  factory ActivitySurvey.fromMap(Map<String, dynamic> map, List<ActivityItem> activities) {
    return ActivitySurvey(
      id: map['id'],
      userId: map['userId'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
      activities: activities,
    );
  }

  // 복사본 생성
  ActivitySurvey copyWith({
    int? id,
    int? userId,
    DateTime? date,
    DateTime? createdAt,
    List<ActivityItem>? activities,
  }) {
    return ActivitySurvey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      activities: activities ?? this.activities,
    );
  }
}

// 개별 활동 아이템
class ActivityItem {
  final int? id;
  final int? activitySurveyId;
  final String activityName;  // 활동명 (예: "운동", "친구 만남", "휴식" 등)
  final int impact;            // 기분에 미친 영향 (1: 매우 나쁨 ~ 5: 매우 좋음)
  final String? note;          // 추가 메모 (선택사항)

  ActivityItem({
    this.id,
    this.activitySurveyId,
    required this.activityName,
    required this.impact,
    this.note,
  });

  // Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activitySurveyId': activitySurveyId,
      'activityName': activityName,
      'impact': impact,
      'note': note,
    };
  }

  // Map에서 ActivityItem 객체 생성
  factory ActivityItem.fromMap(Map<String, dynamic> map) {
    return ActivityItem(
      id: map['id'],
      activitySurveyId: map['activitySurveyId'],
      activityName: map['activityName'],
      impact: map['impact'],
      note: map['note'],
    );
  }

  // 복사본 생성
  ActivityItem copyWith({
    int? id,
    int? activitySurveyId,
    String? activityName,
    int? impact,
    String? note,
  }) {
    return ActivityItem(
      id: id ?? this.id,
      activitySurveyId: activitySurveyId ?? this.activitySurveyId,
      activityName: activityName ?? this.activityName,
      impact: impact ?? this.impact,
      note: note ?? this.note,
    );
  }

  // 영향 레벨 텍스트
  String getImpactText() {
    switch (impact) {
      case 1:
        return '매우 나쁨';
      case 2:
        return '나쁨';
      case 3:
        return '보통';
      case 4:
        return '좋음';
      case 5:
        return '매우 좋음';
      default:
        return '보통';
    }
  }

  // 영향 이모지
  String getImpactEmoji() {
    switch (impact) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }
}

// 미리 정의된 활동 목록
class ActivityType {
  static const String exercise = '운동';
  static const String social = '친구/가족 만남';
  static const String hobby = '취미 활동';
  static const String work = '업무/공부';
  static const String rest = '휴식';
  static const String entertainment = '영화/게임/독서';
  static const String outdoor = '야외 활동';
  static const String meditation = '명상/요가';
  static const String shopping = '쇼핑';
  static const String cooking = '요리';
  static const String cleaning = '청소/정리';
  static const String other = '기타';

  static List<String> get allActivities => [
        exercise,
        social,
        hobby,
        work,
        rest,
        entertainment,
        outdoor,
        meditation,
        shopping,
        cooking,
        cleaning,
        other,
      ];
}

