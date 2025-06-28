import 'dart:convert';
import 'package:logger/logger.dart';
import '../../core/config/google_cloud_config.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class AIAgentService {
  static final Logger _logger = Logger();
  
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

  // Vertex AIを使用したスケジュール最適化
  static Future<List<TaskModel>> optimizeSchedule(
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