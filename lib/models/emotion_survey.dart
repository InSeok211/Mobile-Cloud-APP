// 감정 설문 모델
class EmotionSurvey {
  final int? id;
  final int userId;
  final double valence;      // 감정의 긍정성/부정성 (-1.0 ~ 1.0)
  final double arousal;       // 각성 정도 (0.0 ~ 1.0)
  final int stress;           // 스트레스 수준 (0 ~ 4)
  final int attention;        // 주의 집중 정도 (0 ~ 4)
  final int duration;         // 감정 지속 시간 (0 ~ 4)
  final int disturbance;      // 과업 방해 정도 (0 ~ 4)
  final int change;           // 감정 변화 (0 ~ 4)
  final DateTime date;
  final DateTime createdAt;
  final List<String>? tags;   // 감정 태그 (선택사항)

  EmotionSurvey({
    this.id,
    required this.userId,
    required this.valence,
    required this.arousal,
    required this.stress,
    required this.attention,
    required this.duration,
    required this.disturbance,
    required this.change,
    required this.date,
    DateTime? createdAt,
    this.tags,
  }) : createdAt = createdAt ?? DateTime.now();

  // Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'valence': valence,
      'arousal': arousal,
      'stress': stress,
      'attention': attention,
      'duration': duration,
      'disturbance': disturbance,
      'change': change,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Map에서 EmotionSurvey 객체 생성 (데이터베이스 읽기용)
  factory EmotionSurvey.fromMap(Map<String, dynamic> map, {List<String>? tags}) {
    return EmotionSurvey(
      id: map['id'],
      userId: map['userId'],
      valence: map['valence'],
      arousal: map['arousal'],
      stress: map['stress'],
      attention: map['attention'],
      duration: map['duration'],
      disturbance: map['disturbance'],
      change: map['change'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
      tags: tags,
    );
  }

  // 복사본 생성
  EmotionSurvey copyWith({
    int? id,
    int? userId,
    double? valence,
    double? arousal,
    int? stress,
    int? attention,
    int? duration,
    int? disturbance,
    int? change,
    DateTime? date,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return EmotionSurvey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      valence: valence ?? this.valence,
      arousal: arousal ?? this.arousal,
      stress: stress ?? this.stress,
      attention: attention ?? this.attention,
      duration: duration ?? this.duration,
      disturbance: disturbance ?? this.disturbance,
      change: change ?? this.change,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  // 감정 상태 문자열 반환
  String getEmotionState() {
    if (valence > 0.5 && arousal > 0.5) return '활기찬';
    if (valence > 0.5 && arousal <= 0.5) return '평온한';
    if (valence <= -0.5 && arousal > 0.5) return '긴장된';
    if (valence <= -0.5 && arousal <= 0.5) return '우울한';
    return '중립적인';
  }

  // 이모지 반환
  String getEmoji() {
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
}

