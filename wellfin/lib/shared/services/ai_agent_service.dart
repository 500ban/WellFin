import 'dart:convert';
import 'package:logger/logger.dart';
import '../../core/config/google_cloud_config.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
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
} 