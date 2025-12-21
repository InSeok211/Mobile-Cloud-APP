import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/diary.dart';
import '../models/emotion_survey.dart';
import '../models/activity_survey.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('maum_ondo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 사용자 테이블
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 일기 테이블
    await db.execute('''
      CREATE TABLE diaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // 감정 설문 테이블
    await db.execute('''
      CREATE TABLE emotion_surveys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        valence REAL NOT NULL,
        arousal REAL NOT NULL,
        stress INTEGER NOT NULL,
        attention INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        disturbance INTEGER NOT NULL,
        change INTEGER NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // 감정 태그 테이블
    await db.execute('''
      CREATE TABLE emotion_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surveyId INTEGER NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (surveyId) REFERENCES emotion_surveys (id)
      )
    ''');

    // 활동 설문 테이블
    await db.execute('''
      CREATE TABLE activity_surveys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // 활동 아이템 테이블
    await db.execute('''
      CREATE TABLE activity_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activitySurveyId INTEGER NOT NULL,
        activityName TEXT NOT NULL,
        impact INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (activitySurveyId) REFERENCES activity_surveys (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 활동 설문 테이블 추가
      await db.execute('''
        CREATE TABLE activity_surveys (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          date TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');

      // 활동 아이템 테이블 추가
      await db.execute('''
        CREATE TABLE activity_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activitySurveyId INTEGER NOT NULL,
          activityName TEXT NOT NULL,
          impact INTEGER NOT NULL,
          note TEXT,
          FOREIGN KEY (activitySurveyId) REFERENCES activity_surveys (id)
        )
      ''');
    }
  }

  // 비밀번호 해싱
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 사용자 등록
  Future<User?> registerUser(String email, String password, {String? name}) async {
    final db = await database;

    // 이메일 중복 체크
    final existingUsers = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existingUsers.isNotEmpty) {
      return null; // 이미 존재하는 이메일
    }

    // 비밀번호 해싱
    final hashedPassword = hashPassword(password);

    final user = User(
      email: email,
      password: hashedPassword,
      name: name,
    );

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  // 로그인
  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final hashedPassword = hashPassword(password);

    final results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    if (results.isEmpty) {
      return null; // 로그인 실패
    }

    return User.fromMap(results.first);
  }

  // 사용자 조회 (이메일로)
  Future<User?> getUserByEmail(String email) async {
    final db = await database;

    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isEmpty) {
      return null;
    }

    return User.fromMap(results.first);
  }

  // 사용자 조회 (ID로)
  Future<User?> getUserById(int id) async {
    final db = await database;

    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) {
      return null;
    }

    return User.fromMap(results.first);
  }

  // 소셜 로그인 사용자 등록 또는 로그인
  Future<User?> loginOrRegisterSocialUser(String email, String name) async {
    final db = await database;

    // 기존 사용자 조회
    final existingUser = await getUserByEmail(email);

    if (existingUser != null) {
      // 기존 사용자가 소셜 로그인 사용자인지 확인
      // password가 "SOCIAL_LOGIN"이면 소셜 로그인 사용자
      if (existingUser.password == 'SOCIAL_LOGIN') {
        return existingUser;
      } else {
        // 일반 회원가입 사용자인 경우 null 반환 (소셜 로그인 불가)
        return null;
      }
    }

    // 신규 사용자 등록
    final user = User(
      email: email,
      password: 'SOCIAL_LOGIN', // 소셜 로그인 사용자 표시
      name: name,
    );

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  // ========== 일기 관련 메서드 ==========
  
  // 일기 저장
  Future<Diary> saveDiary(Diary diary) async {
    final db = await database;
    final id = await db.insert('diaries', diary.toMap());
    return diary.copyWith(id: id);
  }

  // 특정 날짜의 일기 조회
  Future<Diary?> getDiaryByDate(int userId, DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD만 추출
    
    final results = await db.query(
      'diaries',
      where: 'userId = ? AND date LIKE ?',
      whereArgs: [userId, '$dateStr%'],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    final diary = Diary.fromMap(results.first);
    return diary;
  }

  // 사용자의 모든 일기 조회
  Future<List<Diary>> getDiariesByUser(int userId, {int? limit}) async {
    final db = await database;
    
    final results = await db.query(
      'diaries',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );

    return results.map((map) => Diary.fromMap(map)).toList();
  }

  // 일기 수정
  Future<int> updateDiary(Diary diary) async {
    final db = await database;
    
    final result = await db.update(
      'diaries',
      diary.toMap(),
      where: 'id = ?',
      whereArgs: [diary.id],
    );
    
    return result;
  }

  // 일기 삭제
  Future<int> deleteDiary(int id) async {
    final db = await database;
    
    return await db.delete(
      'diaries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== 감정 설문 관련 메서드 ==========
  
  // 감정 설문 저장 (태그 포함)
  Future<EmotionSurvey> saveEmotionSurvey(EmotionSurvey survey) async {
    final db = await database;
    
    // 설문 저장
    final id = await db.insert('emotion_surveys', survey.toMap());
    
    // 태그 저장
    if (survey.tags != null && survey.tags!.isNotEmpty) {
      for (String tag in survey.tags!) {
        await db.insert('emotion_tags', {
          'surveyId': id,
          'tag': tag,
        });
      }
    }
    
    return survey.copyWith(id: id);
  }

  // 특정 날짜의 감정 설문 조회
  Future<EmotionSurvey?> getEmotionSurveyByDate(int userId, DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD만 추출
    
    final results = await db.query(
      'emotion_surveys',
      where: 'userId = ? AND date LIKE ?',
      whereArgs: [userId, '$dateStr%'],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    final surveyId = results.first['id'] as int;
    final tags = await _getTagsBySurveyId(surveyId);
    
    return EmotionSurvey.fromMap(results.first, tags: tags);
  }

  // 사용자의 모든 감정 설문 조회
  Future<List<EmotionSurvey>> getEmotionSurveysByUser(int userId, {int? limit}) async {
    final db = await database;
    
    final results = await db.query(
      'emotion_surveys',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );

    List<EmotionSurvey> surveys = [];
    for (var map in results) {
      final surveyId = map['id'] as int;
      final tags = await _getTagsBySurveyId(surveyId);
      surveys.add(EmotionSurvey.fromMap(map, tags: tags));
    }

    return surveys;
  }

  // 특정 기간의 감정 설문 조회
  Future<List<EmotionSurvey>> getEmotionSurveysByDateRange(
    int userId, 
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final db = await database;
    
    final results = await db.query(
      'emotion_surveys',
      where: 'userId = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    List<EmotionSurvey> surveys = [];
    for (var map in results) {
      final surveyId = map['id'] as int;
      final tags = await _getTagsBySurveyId(surveyId);
      surveys.add(EmotionSurvey.fromMap(map, tags: tags));
    }

    return surveys;
  }

  // 설문 ID로 태그 조회 (내부 메서드)
  Future<List<String>> _getTagsBySurveyId(int surveyId) async {
    final db = await database;
    
    final results = await db.query(
      'emotion_tags',
      where: 'surveyId = ?',
      whereArgs: [surveyId],
    );

    return results.map((map) => map['tag'] as String).toList();
  }

  // 감정 설문 삭제
  Future<int> deleteEmotionSurvey(int id) async {
    final db = await database;
    
    // 태그도 함께 삭제
    await db.delete(
      'emotion_tags',
      where: 'surveyId = ?',
      whereArgs: [id],
    );
    
    return await db.delete(
      'emotion_surveys',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== 활동 문답표 관련 메서드 ==========
  
  // 활동 문답표 저장 (활동 아이템들 포함)
  Future<ActivitySurvey> saveActivitySurvey(ActivitySurvey survey) async {
    final db = await database;
    
    // 설문 저장
    final id = await db.insert('activity_surveys', survey.toMap());
    
    // 활동 아이템들 저장
    List<ActivityItem> savedItems = [];
    for (ActivityItem item in survey.activities) {
      final itemId = await db.insert('activity_items', {
        'activitySurveyId': id,
        'activityName': item.activityName,
        'impact': item.impact,
        'note': item.note,
      });
      savedItems.add(item.copyWith(id: itemId, activitySurveyId: id));
    }
    
    return survey.copyWith(id: id, activities: savedItems);
  }

  // 특정 날짜의 활동 문답표 조회
  Future<ActivitySurvey?> getActivitySurveyByDate(int userId, DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD만 추출
    
    final results = await db.query(
      'activity_surveys',
      where: 'userId = ? AND date LIKE ?',
      whereArgs: [userId, '$dateStr%'],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    final surveyId = results.first['id'] as int;
    final activities = await _getActivityItemsBySurveyId(surveyId);
    
    return ActivitySurvey.fromMap(results.first, activities);
  }

  // 사용자의 모든 활동 문답표 조회
  Future<List<ActivitySurvey>> getActivitySurveysByUser(int userId, {int? limit}) async {
    final db = await database;
    
    final results = await db.query(
      'activity_surveys',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );

    List<ActivitySurvey> surveys = [];
    for (var map in results) {
      final surveyId = map['id'] as int;
      final activities = await _getActivityItemsBySurveyId(surveyId);
      surveys.add(ActivitySurvey.fromMap(map, activities));
    }

    return surveys;
  }

  // 특정 기간의 활동 문답표 조회
  Future<List<ActivitySurvey>> getActivitySurveysByDateRange(
    int userId, 
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final db = await database;
    
    final results = await db.query(
      'activity_surveys',
      where: 'userId = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    List<ActivitySurvey> surveys = [];
    for (var map in results) {
      final surveyId = map['id'] as int;
      final activities = await _getActivityItemsBySurveyId(surveyId);
      surveys.add(ActivitySurvey.fromMap(map, activities));
    }

    return surveys;
  }

  // 설문 ID로 활동 아이템 조회 (내부 메서드)
  Future<List<ActivityItem>> _getActivityItemsBySurveyId(int surveyId) async {
    final db = await database;
    
    final results = await db.query(
      'activity_items',
      where: 'activitySurveyId = ?',
      whereArgs: [surveyId],
    );

    return results.map((map) => ActivityItem.fromMap(map)).toList();
  }

  // 활동 문답표 삭제
  Future<int> deleteActivitySurvey(int id) async {
    final db = await database;
    
    // 활동 아이템들도 함께 삭제
    await db.delete(
      'activity_items',
      where: 'activitySurveyId = ?',
      whereArgs: [id],
    );
    
    return await db.delete(
      'activity_surveys',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

