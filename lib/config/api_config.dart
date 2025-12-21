// API 설정 파일
// TODO: 실제 사용 시 API 키를 환경 변수나 안전한 저장소에서 가져오도록 변경하세요
class ApiConfig {
  // Gemini API 키
  // API 키를 얻으려면: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyDtPvaAtNvAkIYNNKxzPxy6lEx10p2WGqk';
  
  // API 키가 설정되었는지 확인
  static bool get isGeminiApiKeySet => 
      geminiApiKey.isNotEmpty && 
      geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE' &&
      geminiApiKey.startsWith('AIza');
}

