import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class GoogleCloudConfig {
  // Vertex AI API設定
  static const String vertexAiBaseUrl = 'https://us-central1-aiplatform.googleapis.com';
  static const String projectId = 'your-project-id'; // 実際のプロジェクトIDに変更
  
  // Gemini API設定
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com';
  static const String geminiModel = 'gemini-pro';
  
  // Recommendations AI設定
  static const String recommendationsApiUrl = 'https://recommendationengine.googleapis.com';
  
  // Natural Language AI設定
  static const String naturalLanguageApiUrl = 'https://language.googleapis.com';
  
  // API認証設定
  static ServiceAccountCredentials? _credentials;
  
  static Future<void> initialize() async {
    // サービスアカウント認証情報の読み込み
    // 実際の実装では、Secret Managerから取得することを推奨
    // _credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
  }
  
  static Future<http.Client> getAuthenticatedClient() async {
    if (_credentials == null) {
      await initialize();
    }
    
    if (_credentials == null) {
      throw Exception('Google Cloud credentials not initialized');
    }
    
    // TODO: Google Cloud認証の型エラーを修正
    // return authenticatedClient(http.Client(), _credentials!);
    return http.Client();
  }
  
  // Vertex AI API エンドポイント
  static String getVertexAiEndpoint(String model) {
    return '$vertexAiBaseUrl/v1/projects/$projectId/locations/us-central1/models/$model:predict';
  }
  
  // Gemini API エンドポイント
  static String getGeminiEndpoint() {
    return '$geminiApiUrl/v1beta/models/$geminiModel:generateContent';
  }
  
  // Recommendations AI エンドポイント
  static String getRecommendationsEndpoint() {
    return '$recommendationsApiUrl/v1beta1/projects/$projectId/locations/global/catalogs/default_catalog/eventStores/default_event_store/userEvents:write';
  }
  
  // Natural Language AI エンドポイント
  static String getNaturalLanguageEndpoint() {
    return '$naturalLanguageApiUrl/v1/documents:analyzeSentiment';
  }
} 