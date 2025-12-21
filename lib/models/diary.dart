// 일기 모델
class Diary {
  final int? id;
  final int userId;
  final String content;
  final DateTime date;
  final DateTime createdAt;

  Diary({
    this.id,
    required this.userId,
    required this.content,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Map에서 Diary 객체 생성 (데이터베이스 읽기용)
  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'],
      userId: map['userId'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // 복사본 생성
  Diary copyWith({
    int? id,
    int? userId,
    String? content,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Diary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

