import 'dart:convert';
import 'package:logger/logger.dart';
import '../../core/config/google_cloud_config.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../../features/analytics/presentation/providers/analytics_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

// AI分析結果のモデル
class TaskAnalysisResult {
  final String title;
  final String description;
  final String category;
  final String priority;
  final int estimatedDuration;
  final String complexity;
  final List<String> tags;
  final List<String> suggestions;
  final ExecutionResult execution;
  final Map<String, dynamic> metadata;

  TaskAnalysisResult({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.estimatedDuration,
    required this.complexity,
    required this.tags,
    required this.suggestions,
    required this.execution,
    required this.metadata,
  });

  factory TaskAnalysisResult.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>;
    return TaskAnalysisResult(
      title: analysis['title'] ?? '',
      description: analysis['description'] ?? '',
      category: analysis['category'] ?? 'other',
      priority: analysis['priority'] ?? 'medium',
      estimatedDuration: analysis['estimatedDuration'] ?? 60,
      complexity: analysis['complexity'] ?? 'medium',
      tags: List<String>.from(analysis['tags'] ?? []),
      suggestions: List<String>.from(analysis['suggestions'] ?? []),
      execution: ExecutionResult.fromJson(json['execution'] ?? {}),
      metadata: json['metadata'] ?? {},
    );
  }
}

class ScheduleOptimizationResult {
  final List<OptimizedTask> optimizedSchedule;
  final ExecutionResult execution;
  final ScheduleSummary summary;
  final Map<String, dynamic> metadata;

  ScheduleOptimizationResult({
    required this.optimizedSchedule,
    required this.execution,
    required this.summary,
    required this.metadata,
  });

  factory ScheduleOptimizationResult.fromJson(Map<String, dynamic> json) {
    return ScheduleOptimizationResult(
      optimizedSchedule: (json['optimizedSchedule'] as List)
          .map((item) => OptimizedTask.fromJson(item))
          .toList(),
      execution: ExecutionResult.fromJson(json['execution'] ?? {}),
      summary: ScheduleSummary.fromJson(json['summary'] ?? {}),
      metadata: json['metadata'] ?? {},
    );
  }
}

class RecommendationsResult {
  final List<Recommendation> recommendations;
  final ExecutionResult execution;
  final Map<String, dynamic> insights;
  final Map<String, dynamic> metadata;

  RecommendationsResult({
    required this.recommendations,
    required this.execution,
    required this.insights,
    required this.metadata,
  });

  factory RecommendationsResult.fromJson(Map<String, dynamic> json) {
    return RecommendationsResult(
      recommendations: (json['recommendations'] as List)
          .map((item) => Recommendation.fromJson(item))
          .toList(),
      execution: ExecutionResult.fromJson(json['execution'] ?? {}),
      insights: json['insights'] ?? {},
      metadata: json['metadata'] ?? {},
    );
  }
}

class ExecutionResult {
  final String status;
  final List<ExecutionAction> actions;
  final List<String> recommendations;
  final List<String>? optimizations;
  final List<String>? improvements;

  ExecutionResult({
    required this.status,
    required this.actions,
    required this.recommendations,
    this.optimizations,
    this.improvements,
  });

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    return ExecutionResult(
      status: json['status'] ?? 'unknown',
      actions: (json['actions'] as List? ?? [])
          .map((item) => ExecutionAction.fromJson(item))
          .toList(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      optimizations: json['optimizations'] != null 
          ? List<String>.from(json['optimizations']) 
          : null,
      improvements: json['improvements'] != null 
          ? List<String>.from(json['improvements']) 
          : null,
    );
  }
}

class ExecutionAction {
  final String type;
  final String description;
  final Map<String, dynamic> details;

  ExecutionAction({
    required this.type,
    required this.description,
    required this.details,
  });

  factory ExecutionAction.fromJson(Map<String, dynamic> json) {
    return ExecutionAction(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      details: json['details'] ?? {},
    );
  }
}

class OptimizedTask {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String priority;
  final String category;
  final String status;

  OptimizedTask({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.priority,
    required this.category,
    required this.status,
  });

  factory OptimizedTask.fromJson(Map<String, dynamic> json) {
    return OptimizedTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? 'other',
      status: json['status'] ?? 'scheduled',
    );
  }
}

class ScheduleSummary {
  final int totalTasks;
  final int totalDuration;
  final double efficiency;
  final int improvementPercentage;

  ScheduleSummary({
    required this.totalTasks,
    required this.totalDuration,
    required this.efficiency,
    required this.improvementPercentage,
  });

  factory ScheduleSummary.fromJson(Map<String, dynamic> json) {
    return ScheduleSummary(
      totalTasks: json['totalTasks'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      efficiency: (json['efficiency'] ?? 0.0).toDouble(),
      improvementPercentage: json['improvementPercentage'] ?? 0,
    );
  }
}

class Recommendation {
  final String id;
  final String type;
  final String title;
  final String description;
  final String priority;
  final bool actionable;
  final String estimatedImpact;
  final String status;

  Recommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.actionable,
    required this.estimatedImpact,
    required this.status,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      actionable: json['actionable'] ?? false,
      estimatedImpact: json['estimatedImpact'] ?? 'medium',
      status: json['status'] ?? 'suggested',
    );
  }
}

/// 分析データに基づくAI最適化提案
class AnalyticsOptimizationResult {
  final List<Recommendation> recommendations;
  final ScheduleOptimization scheduleOptimization;
  final ProductivityInsights insights;
  final ExecutionResult execution;
  final Map<String, dynamic> metadata;

  AnalyticsOptimizationResult({
    required this.recommendations,
    required this.scheduleOptimization,
    required this.insights,
    required this.execution,
    required this.metadata,
  });

  factory AnalyticsOptimizationResult.fromJson(Map<String, dynamic> json) {
    return AnalyticsOptimizationResult(
      recommendations: (json['recommendations'] as List? ?? [])
          .map((item) => Recommendation.fromJson(item))
          .toList(),
      scheduleOptimization: ScheduleOptimization.fromJson(json['scheduleOptimization'] ?? {}),
      insights: ProductivityInsights.fromJson(json['insights'] ?? {}),
      execution: ExecutionResult.fromJson(json['execution'] ?? {}),
      metadata: json['metadata'] ?? {},
    );
  }
}

class ScheduleOptimization {
  final List<String> timeSlotOptimizations;
  final List<String> categoryBalancing;
  final List<String> efficiencyImprovements;
  final double potentialEfficiencyGain;

  ScheduleOptimization({
    required this.timeSlotOptimizations,
    required this.categoryBalancing,
    required this.efficiencyImprovements,
    required this.potentialEfficiencyGain,
  });

  factory ScheduleOptimization.fromJson(Map<String, dynamic> json) {
    return ScheduleOptimization(
      timeSlotOptimizations: List<String>.from(json['timeSlotOptimizations'] ?? []),
      categoryBalancing: List<String>.from(json['categoryBalancing'] ?? []),
      efficiencyImprovements: List<String>.from(json['efficiencyImprovements'] ?? []),
      potentialEfficiencyGain: (json['potentialEfficiencyGain'] ?? 0.0).toDouble(),
    );
  }
}

class ProductivityInsights {
  final List<String> peakPerformanceTimes;
  final List<String> lowProductivityTimes;
  final List<String> habitRecommendations;
  final List<String> goalStrategies;
  final double overallScore;

  ProductivityInsights({
    required this.peakPerformanceTimes,
    required this.lowProductivityTimes,
    required this.habitRecommendations,
    required this.goalStrategies,
    required this.overallScore,
  });

  factory ProductivityInsights.fromJson(Map<String, dynamic> json) {
    return ProductivityInsights(
      peakPerformanceTimes: List<String>.from(json['peakPerformanceTimes'] ?? []),
      lowProductivityTimes: List<String>.from(json['lowProductivityTimes'] ?? []),
      habitRecommendations: List<String>.from(json['habitRecommendations'] ?? []),
      goalStrategies: List<String>.from(json['goalStrategies'] ?? []),
      overallScore: (json['overallScore'] ?? 0.0).toDouble(),
    );
  }
}

class AIAgentService {
  static final Logger _logger = Logger();
  
  // Cloud Run Functions API URL（ビルド時に設定）
  static String get _baseUrl => const String.fromEnvironment(
    'WELLFIN_API_URL',
    defaultValue: 'http://localhost:8080', // ローカル開発用フォールバック
  );
  
  // デバッグモード判定（開発中は詳細ログ出力）
  static bool get _isDebugMode => const bool.fromEnvironment('dart.vm.product') == false;
  
  // APIキーを環境変数から取得
  static String get _apiKey => const String.fromEnvironment(
    'WELLFIN_API_KEY',
    defaultValue: 'dev-secret-key',
  );
  
  // APIキー認証ヘッダー（統一）
  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'X-API-Key': _apiKey,
    'X-App-Version': '1.0.0',
    'X-Platform': Platform.operatingSystem,
    };
  
  // ヘルスチェック
  static Future<bool> healthCheck() async {
    try {
      final url = '$_baseUrl/health';
      
      if (_isDebugMode) {
      print('=== AIAgentService Debug Info ===');
      print('Health check URL: $url');
      print('Platform: ${Platform.operatingSystem}');
        print('Debug Mode: $_isDebugMode');
        print('API Base URL: $_baseUrl');
        print('API Key Set: ${_apiKey.isNotEmpty}');
        print('WELLFIN_API_URL env: ${const String.fromEnvironment('WELLFIN_API_URL', defaultValue: 'NOT SET')}');
      print('================================');
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (_isDebugMode) {
      print('Health check response: ${response.statusCode}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Health check failed: $e');
      return false;
    }
  }
  
  // APIキー認証状態の詳細チェック
  static Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      final apiKey = _apiKey;
      final isValidKey = apiKey.isNotEmpty && apiKey != 'dev-secret-key';
      
      return {
        'authenticated': true,
        'authMethod': 'API Key',
        'apiKeySet': apiKey.isNotEmpty,
        'apiKeyLength': apiKey.length,
        'isDefaultKey': apiKey == 'dev-secret-key',
        'isValidKey': isValidKey,
        'baseUrl': _baseUrl,
        'platform': Platform.operatingSystem,
        'isDebugMode': _isDebugMode,
      };
    } catch (e) {
      return {
        'authenticated': false,
        'error': e.toString(),
      };
    }
  }
  
  // 現在のベースURLを取得
  static String get currentBaseUrl => _baseUrl;
  
  // タスク分析・実行（新API）
  static Future<TaskAnalysisResult> analyzeTask({
    required String userInput,
  }) async {
    try {
      final headers = _authHeaders;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/analyze-task'),
        headers: headers,
        body: jsonEncode({
          'userInput': userInput,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TaskAnalysisResult.fromJson(data);
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to analyze task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.e('Error analyzing task: $e');
      rethrow;
    }
  }
  
  // スケジュール最適化・実行（新API）
  static Future<ScheduleOptimizationResult> optimizeSchedule({
    required List<Map<String, dynamic>> tasks,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final headers = _authHeaders;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/optimize-schedule'),
        headers: headers,
        body: jsonEncode({
          'tasks': tasks,
          if (preferences != null) 'preferences': preferences,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ScheduleOptimizationResult.fromJson(data);
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to optimize schedule: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.e('Error optimizing schedule: $e');
      rethrow;
    }
  }
  
  // 推奨事項生成・実行（新API）
  static Future<RecommendationsResult> getRecommendations({
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? context,
  }) async {
    try {
              _logger.d('推奨事項を取得中... (プラットフォーム: ${Platform.operatingSystem}, デバッグモード: $_isDebugMode, URL: $_baseUrl)');
        
        final headers = _authHeaders;
      final requestBody = {
        if (userProfile != null) 'userProfile': userProfile,
        if (context != null) 'context': context,
      };
      
      _logger.d('リクエストヘッダー: ${headers.keys.toList()}');
      _logger.d('リクエストボディキー: ${requestBody.keys.toList()}');
      
      final uri = Uri.parse('$_baseUrl/api/v1/recommendations');
      _logger.d('リクエストURI: $uri');
      
      // Android固有の設定でHTTPクライアントを作成
      final client = http.Client();
      
      try {
        final response = await client.post(
          uri,
          headers: headers,
          body: jsonEncode(requestBody),
        ).timeout(
          const Duration(seconds: 30), // 30秒でタイムアウト
          onTimeout: () {
            _logger.e('API呼び出しがタイムアウトしました');
            throw Exception('API request timeout');
          },
        );
        
        _logger.d('APIレスポンス: ${response.statusCode}');
        _logger.d('レスポンスヘッダー: ${response.headers}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            _logger.d('推奨事項を正常に取得しました');
            return RecommendationsResult.fromJson(data);
          } else {
            _logger.e('API returned success: false - Response: ${response.body}');
            throw Exception('API returned success: false');
          }
        } else if (response.statusCode == 401) {
          _logger.e('認証エラー - トークンが無効または期限切れの可能性があります');
          throw Exception('Authentication failed - token may be invalid or expired');
        } else if (response.statusCode == 403) {
          _logger.e('アクセス拒否 - 権限が不足している可能性があります');
          throw Exception('Access denied - insufficient permissions');
        } else {
          _logger.e('推奨事項取得APIエラー: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to get recommendations: ${response.statusCode} - ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      _logger.e('推奨事項取得中にエラーが発生しました: $e');
      rethrow;
    }
  }

  // レガシーAPIクライアント版メソッド（後方互換性のため保持）
  
  // タスク分析（レガシーAPIクライアント版）
  static Future<Map<String, dynamic>> analyzeTaskViaAPI({
    required String title,
    required String description,
    String? priority,
    String? deadline,
    double? estimatedHours,
  }) async {
    final headers = _authHeaders;
    
    final body = <String, dynamic>{
      'userInput': '$title: $description',
      if (priority != null) 'priority': priority,
      if (deadline != null) 'deadline': deadline,
      if (estimatedHours != null) 'estimatedHours': estimatedHours,
    };
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/analyze-task'),
      headers: headers,
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze task: ${response.statusCode} - ${response.body}');
    }
  }
  
  // スケジュール最適化（レガシーAPIクライアント版）
  static Future<Map<String, dynamic>> optimizeScheduleViaAPI({
    required List<Map<String, dynamic>> tasks,
    Map<String, dynamic>? preferences,
  }) async {
    final headers = _authHeaders;
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/optimize-schedule'),
      headers: headers,
      body: jsonEncode({
        'tasks': tasks,
        if (preferences != null) 'preferences': preferences,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to optimize schedule: ${response.statusCode} - ${response.body}');
    }
  }
  
  // 推奨事項生成（レガシーAPIクライアント版）
  static Future<Map<String, dynamic>> getRecommendationsViaAPI({
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? context,
  }) async {
    final headers = _authHeaders;
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/recommendations'),
      headers: headers,
      body: jsonEncode({
        if (userProfile != null) 'userProfile': userProfile,
        if (context != null) 'context': context,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get recommendations: ${response.statusCode} - ${response.body}');
    }
  }

  // Gemini APIを使用した自然言語タスク解析
  static Future<TaskModel> parseNaturalLanguageTask(
    String userInput, 
    String userId,
    DateTime scheduledDate,
  ) async {
    try {
      final client = await GoogleCloudConfig.getAuthenticatedClient();
      
      final prompt = '''
以下のユーザーの入力からタスク情報を抽出してください。
入力: "$userInput"
予定日: ${scheduledDate.toIso8601String()}

以下のJSON形式で返してください:
{
  "title": "タスクのタイトル",
  "description": "詳細な説明",
  "priority": 1-5の優先度,
  "difficulty": 1-5の難易度,
  "estimatedDuration": 予想所要時間（分）,
  "tags": ["タグ1", "タグ2"],
  "isSkippable": true/false
}
''';

      final response = await client.post(
        Uri.parse(GoogleCloudConfig.getGeminiEndpoint()),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // JSON部分を抽出
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
        if (jsonMatch != null) {
          final taskData = jsonDecode(jsonMatch.group(0)!);
          
          return TaskModel(
            id: '', // Firestoreで生成
            title: taskData['title'] ?? '新しいタスク',
            description: taskData['description'] ?? '',
            createdAt: DateTime.now(),
            scheduledDate: scheduledDate,
            priority: taskData['priority'] ?? 3,
            difficulty: taskData['difficulty'] ?? 3,
            estimatedDuration: taskData['estimatedDuration'] ?? 60,
            tags: List<String>.from(taskData['tags'] ?? []),
            isSkippable: taskData['isSkippable'] ?? false,
          );
        }
      }
      
      throw Exception('Failed to parse task from natural language');
    } catch (e) {
      _logger.e('Error parsing natural language task: $e');
      rethrow;
    }
  }

  // レガシー: Vertex AIを使用したスケジュール最適化（後方互換性のため）
  static Future<List<TaskModel>> optimizeScheduleViaVertexAI(
    List<TaskModel> tasks,
    UserModel user,
  ) async {
    try {
      final client = await GoogleCloudConfig.getAuthenticatedClient();
      
      // タスクデータを準備
      final taskData = tasks.map((task) => {
        'id': task.id,
        'title': task.title,
        'priority': task.priority,
        'difficulty': task.difficulty,
        'estimatedDuration': task.estimatedDuration,
        'scheduledDate': task.scheduledDate.toIso8601String(),
        'procrastinationRisk': task.procrastinationRisk,
      }).toList();

      final requestBody = {
        'instances': [
          {
            'tasks': taskData,
            'userPreferences': {
              'productivityPeakHours': user.preferences.productivityPeakHours,
              'timeZone': user.timeZone,
            },
          },
        ],
      };

      final response = await client.post(
        Uri.parse(GoogleCloudConfig.getVertexAiEndpoint('schedule-optimizer')),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'][0];
        
        // 最適化されたスケジュールを適用
        final optimizedTasks = <TaskModel>[];
        for (int i = 0; i < tasks.length; i++) {
          final task = tasks[i];
          final optimization = predictions['taskOptimizations'][i];
          
          optimizedTasks.add(task.copyWith(
            scheduledTimeStart: DateTime.parse(optimization['optimalStartTime']),
            scheduledTimeEnd: DateTime.parse(optimization['optimalEndTime']),
            procrastinationRisk: optimization['procrastinationRisk'].toDouble(),
          ));
        }
        
        return optimizedTasks;
      }
      
      throw Exception('Failed to optimize schedule');
    } catch (e) {
      _logger.e('Error optimizing schedule: $e');
      rethrow;
    }
  }

  // Natural Language AIを使用した感情分析
  static Future<Map<String, dynamic>> analyzeTaskSentiment(String taskDescription) async {
    try {
      final client = await GoogleCloudConfig.getAuthenticatedClient();
      
      final requestBody = {
        'document': {
          'type': 'PLAIN_TEXT',
          'content': taskDescription,
        },
        'encodingType': 'UTF8',
      };

      final response = await client.post(
        Uri.parse(GoogleCloudConfig.getNaturalLanguageEndpoint()),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sentiment = data['documentSentiment'];
        
        return {
          'score': sentiment['score'],
          'magnitude': sentiment['magnitude'],
          'entities': data['entities'] ?? [],
        };
      }
      
      throw Exception('Failed to analyze sentiment');
    } catch (e) {
      _logger.e('Error analyzing sentiment: $e');
      rethrow;
    }
  }

  // Recommendations AIを使用したタスク推奨
  static Future<List<TaskModel>> getTaskRecommendations(
    UserModel user,
    List<TaskModel> recentTasks,
  ) async {
    try {
      final client = await GoogleCloudConfig.getAuthenticatedClient();
      
      // ユーザーイベントを記録
      await client.post(
        Uri.parse(GoogleCloudConfig.getRecommendationsEndpoint()),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userEvent': {
            'eventType': 'page-view',
            'userInfo': {
              'visitorId': user.uid,
            },
            'eventDetail': {
              'pageViewEvent': {
                'pageCategories': ['task-management'],
                'uri': '/dashboard',
              },
            },
          },
        }),
      );

      // 推奨タスクを取得
      final recommendationsResponse = await client.get(
        Uri.parse('${GoogleCloudConfig.recommendationsApiUrl}/v1beta1/projects/${GoogleCloudConfig.projectId}/locations/global/catalogs/default_catalog/eventStores/default_event_store/placements/recommend'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (recommendationsResponse.statusCode == 200) {
        final data = jsonDecode(recommendationsResponse.body);
        final recommendations = data['results'] as List;
        
        return recommendations.map((rec) {
          final item = rec['item'];
          return TaskModel(
            id: '',
            title: item['title'] ?? '推奨タスク',
            description: item['description'] ?? '',
            createdAt: DateTime.now(),
            scheduledDate: DateTime.now().add(const Duration(days: 1)),
            priority: item['priority'] ?? 3,
            difficulty: item['difficulty'] ?? 3,
            estimatedDuration: item['estimatedDuration'] ?? 60,
            tags: List<String>.from(item['tags'] ?? []),
          );
        }).toList();
      }
      
      throw Exception('Failed to get recommendations');
    } catch (e) {
      _logger.e('Error getting recommendations: $e');
      rethrow;
    }
  }

  // Vertex AI Vector Searchを使用した類似タスク検索
  static Future<List<TaskModel>> findSimilarTasks(
    TaskModel task,
    List<TaskModel> allTasks,
  ) async {
    try {
      final client = await GoogleCloudConfig.getAuthenticatedClient();
      
      // タスクのベクトル表現を取得
      final vectorResponse = await client.post(
        Uri.parse('${GoogleCloudConfig.vertexAiBaseUrl}/v1/projects/${GoogleCloudConfig.projectId}/locations/us-central1/indexes/task-embeddings:findNeighbors'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deployedIndexId': 'task-embeddings-index',
          'queries': [
            {
              'datapoint': {
                'datapointId': task.id,
                'featureVector': _generateTaskVector(task),
              },
              'neighborCount': 5,
            },
          ],
        }),
      );

      if (vectorResponse.statusCode == 200) {
        final data = jsonDecode(vectorResponse.body);
        final neighbors = data['nearestNeighbors'][0]['neighbors'];
        
        return neighbors.map((neighbor) {
          final taskId = neighbor['datapoint']['datapointId'];
          return allTasks.firstWhere((t) => t.id == taskId);
        }).toList();
      }
      
      throw Exception('Failed to find similar tasks');
    } catch (e) {
      _logger.e('Error finding similar tasks: $e');
      rethrow;
    }
  }

  // タスクのベクトル表現を生成（簡易版）
  static List<double> _generateTaskVector(TaskModel task) {
    // 実際の実装では、より高度な埋め込みモデルを使用
    return [
      task.priority.toDouble(),
      task.difficulty.toDouble(),
      task.estimatedDuration.toDouble(),
      task.procrastinationRisk,
      task.tags.length.toDouble(),
    ];
  }

  /// 分析データに基づくAI最適化提案を取得
  static Future<AnalyticsOptimizationResult> getAnalyticsOptimization(
    AnalyticsData analyticsData,
    UserModel user,
  ) async {
    try {
      final String baseUrl = _baseUrl;
      final String apiKey = _apiKey;

      final requestBody = {
        'analyticsData': {
          'todayCompletionRate': analyticsData.todayCompletionRate,
          'todayEfficiencyScore': analyticsData.todayEfficiencyScore,
          'todayPlannedHours': analyticsData.todayPlannedHours,
          'todayActualHours': analyticsData.todayActualHours,
          'weeklyProgress': analyticsData.weeklyProgress,
          'categoryDistribution': analyticsData.categoryDistribution,
          'hourlyDistribution': analyticsData.hourlyDistribution,
          'focusTimeHours': analyticsData.focusTimeHours,
          'interruptionCount': analyticsData.interruptionCount,
          'multitaskingRate': analyticsData.multitaskingRate,
          'totalTasks': analyticsData.totalTasks,
          'completedTasks': analyticsData.completedTasks,
          'totalHabits': analyticsData.totalHabits,
          'completedHabits': analyticsData.completedHabits,
          'totalGoals': analyticsData.totalGoals,
          'completedGoals': analyticsData.completedGoals,
        },
        'userProfile': {
          'userId': user.uid,
          'preferences': {
            'workStyle': 'balanced', // ユーザー設定から取得（将来実装）
            'productivityGoals': ['efficiency', 'consistency'],
          },
        },
        'optimizationGoals': [
          'improve_time_management',
          'reduce_procrastination',
          'increase_focus_time',
          'balance_work_categories',
        ],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/recommendations'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // AI Agent APIからの実際のレスポンスを待ってAnalyticsOptimizationResult.fromJsonで処理
        return AnalyticsOptimizationResult.fromJson(data);
      } else if (response.statusCode == 503) {
        // サービス利用不可の場合は模擬データを返す
        return _generateMockOptimizationResult(analyticsData);
      } else {
        _logger.w('AI Agent API error: ${response.statusCode}');
        // エラーの場合も模擬データを返す
        return _generateMockOptimizationResult(analyticsData);
      }
    } catch (e) {
      _logger.e('Error getting analytics optimization: $e');
      // エラーの場合は模擬データを返す
      return _generateMockOptimizationResult(analyticsData);
    }
  }

  /// 模擬的なAI最適化提案データを生成
  static AnalyticsOptimizationResult _generateMockOptimizationResult(AnalyticsData analyticsData) {
    final List<Recommendation> recommendations = [];
    
    // 完了率に基づく提案
    if (analyticsData.todayCompletionRate < 0.7) {
      recommendations.add(Recommendation(
        id: 'task_completion_${DateTime.now().millisecondsSinceEpoch}',
        type: 'task_management',
        title: '📋 タスク分割の提案',
        description: '大きなタスクを小さな単位に分割することで、完了率を向上させることができます。',
        priority: 'high',
        actionable: true,
        estimatedImpact: 'high',
        status: 'suggested',
      ));
    }

    // 効率性スコアに基づく提案
    if (analyticsData.todayEfficiencyScore < 7.0) {
      recommendations.add(Recommendation(
        id: 'time_management_${DateTime.now().millisecondsSinceEpoch}',
        type: 'time_management',
        title: '⏰ 時間管理の改善',
        description: '計画時間と実際時間の差を縮めるため、より正確な時間見積もりを心がけましょう。',
        priority: 'medium',
        actionable: true,
        estimatedImpact: 'medium',
        status: 'suggested',
      ));
    }

    // 集中時間に基づく提案
    if (analyticsData.focusTimeHours < 4.0) {
      recommendations.add(Recommendation(
        id: 'focus_improvement_${DateTime.now().millisecondsSinceEpoch}',
        type: 'focus_improvement',
        title: '🎯 集中時間の確保',
        description: '集中時間を増やすため、まとまった時間ブロックを確保することをお勧めします。',
        priority: 'high',
        actionable: true,
        estimatedImpact: 'high',
        status: 'suggested',
      ));
    }

    // 中断回数に基づく提案
    if (analyticsData.interruptionCount > 10) {
      recommendations.add(Recommendation(
        id: 'interruption_reduction_${DateTime.now().millisecondsSinceEpoch}',
        type: 'interruption_reduction',
        title: '🔕 中断の削減',
        description: '通知をオフにする、作業環境を整えるなどして中断を減らしましょう。',
        priority: 'medium',
        actionable: true,
        estimatedImpact: 'medium',
        status: 'suggested',
      ));
    }

    // 週間進捗に基づく提案
    final weeklyAverage = analyticsData.weeklyProgress.isEmpty 
        ? 0.0 
        : analyticsData.weeklyProgress.reduce((a, b) => a + b) / analyticsData.weeklyProgress.length;
    
    if (weeklyAverage < 0.8) {
      recommendations.add(Recommendation(
        id: 'consistency_improvement_${DateTime.now().millisecondsSinceEpoch}',
        type: 'consistency_improvement',
        title: '📈 継続性の向上',
        description: '週間を通じた安定したパフォーマンスを維持するため、毎日の習慣を見直しましょう。',
        priority: 'medium',
        actionable: true,
        estimatedImpact: 'medium',
        status: 'suggested',
      ));
    }

    return AnalyticsOptimizationResult(
      recommendations: recommendations,
      scheduleOptimization: ScheduleOptimization(
        timeSlotOptimizations: [
          '午前中の集中時間を増やすことで、効率を${(analyticsData.todayEfficiencyScore < 7 ? 15 : 10)}%向上できます',
          '定期的な休憩を取ることで、長期的な生産性を維持できます',
          '似たカテゴリのタスクをまとめて処理することで、コンテキストスイッチを減らせます',
        ],
        categoryBalancing: [
          '仕事と個人タスクのバランスを${(analyticsData.categoryDistribution['仕事'] ?? 0) > 6 ? '調整' : '維持'}することをお勧めします',
          '学習時間を${(analyticsData.categoryDistribution['学習'] ?? 0) < 2 ? '増やす' : '維持する'}と良いでしょう',
        ],
        efficiencyImprovements: [
          'ポモドーロテクニックを使用して集中時間を最大化',
          'タスクの優先度付けを明確にして重要なタスクに集中',
          '同じ時間帯に同種のタスクをグループ化',
        ],
        potentialEfficiencyGain: analyticsData.todayEfficiencyScore < 7 ? 0.25 : 0.15,
      ),
      insights: ProductivityInsights(
        peakPerformanceTimes: _generatePeakTimes(analyticsData.hourlyDistribution),
        lowProductivityTimes: _generateLowTimes(analyticsData.hourlyDistribution),
        habitRecommendations: [
          '朝のルーティンを確立して一日を効率的に開始',
          '定期的な運動で集中力を向上',
          '十分な睡眠で翌日のパフォーマンスを最適化',
        ],
        goalStrategies: [
          '週次レビューで進捗を確認し軌道修正',
          '大きな目標を小さなマイルストーンに分割',
          '達成した目標を記録してモチベーション維持',
        ],
        overallScore: _calculateOverallProductivityScore(analyticsData),
      ),
      execution: ExecutionResult(
        status: 'completed',
        actions: [
          ExecutionAction(
            type: 'analysis_generated',
            description: '分析データに基づく最適化提案を生成しました',
            details: {'recommendationCount': recommendations.length},
          ),
        ],
        recommendations: [
          '提案された改善策を段階的に実施してください',
          '変更の効果を1週間後に確認することをお勧めします',
        ],
      ),
      metadata: {
        'generatedAt': DateTime.now().toIso8601String(),
        'analysisVersion': '1.0',
        'modelType': 'mock_optimization',
        'dataPoints': analyticsData.totalTasks + analyticsData.totalHabits + analyticsData.totalCalendarEvents,
      },
    );
  }

  /// 時間別分布から最高パフォーマンス時間を特定
  static List<String> _generatePeakTimes(Map<int, int> hourlyDistribution) {
    if (hourlyDistribution.isEmpty) return ['9:00-11:00', '14:00-16:00'];
    
    final sortedHours = hourlyDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final peakHours = sortedHours.take(2).map((entry) {
      final hour = entry.key;
      return '${hour}:00-${hour + 1}:00';
    }).toList();
    
    return peakHours.isEmpty ? ['9:00-11:00', '14:00-16:00'] : peakHours;
  }

  /// 時間別分布から低生産性時間を特定
  static List<String> _generateLowTimes(Map<int, int> hourlyDistribution) {
    if (hourlyDistribution.isEmpty) return ['13:00-14:00', '16:00-17:00'];
    
    final sortedHours = hourlyDistribution.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final lowHours = sortedHours.take(2).map((entry) {
      final hour = entry.key;
      return '${hour}:00-${hour + 1}:00';
    }).toList();
    
    return lowHours.isEmpty ? ['13:00-14:00', '16:00-17:00'] : lowHours;
  }

  /// 総合生産性スコアを計算
  static double _calculateOverallProductivityScore(AnalyticsData analyticsData) {
    double score = 0.0;
    
    // 完了率（40%の重み）
    score += analyticsData.todayCompletionRate * 40;
    
    // 効率性スコア（30%の重み）
    score += (analyticsData.todayEfficiencyScore / 10) * 30;
    
    // 集中時間（20%の重み）
    final focusRatio = analyticsData.todayActualHours > 0 
        ? (analyticsData.focusTimeHours / analyticsData.todayActualHours).clamp(0.0, 1.0)
        : 0.0;
    score += focusRatio * 20;
    
    // 中断の少なさ（10%の重み）
    final interruptionScore = (1.0 - (analyticsData.interruptionCount / 20).clamp(0.0, 1.0));
    score += interruptionScore * 10;
    
    return score.clamp(0.0, 100.0);
  }
} 