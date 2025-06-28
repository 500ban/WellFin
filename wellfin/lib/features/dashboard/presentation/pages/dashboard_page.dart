import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../tasks/presentation/pages/task_list_page.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/widgets/task_filter_bar.dart';
import '../../../habits/presentation/pages/habit_list_page.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../habits/domain/entities/habit.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // ダッシュボード読み込み時にタスクと習慣を取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadTasks();
      ref.read(habitProvider.notifier).loadTodayHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(currentUserDataProvider);
    final authActions = ref.watch(authActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WellFin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.task_alt),
            onPressed: () {
              _navigateToTaskListWithFilter(TaskFilter.all);
            },
            tooltip: 'タスク管理',
          ),
          IconButton(
            icon: const Icon(Icons.repeat),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HabitListPage(),
                ),
              );
            },
            tooltip: '習慣設定',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 設定ページに遷移
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authActions.signOut();
            },
          ),
        ],
      ),
      body: userData.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ユーザー情報が見つかりません'),
            );
          }
          return _buildDashboardContent(context, user);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー情報カード
          _buildUserInfoCard(user),
          const SizedBox(height: 24),
          
          // 今日のサマリー
          _buildTodaySummaryCard(user),
          const SizedBox(height: 24),
          
          // クイックアクセスメニュー
          _buildQuickAccessMenu(),
          const SizedBox(height: 24),
          
          // AI推奨セクション
          _buildAIRecommendationsCard(),
          const SizedBox(height: 24),
          
          // 習慣トラッキング
          _buildHabitsCard(),
          const SizedBox(height: 24),
          
          // 今日のタスク
          _buildTodayTasksCard(context),
          const SizedBox(height: 24),
          
          // 生産性分析
          _buildProductivityCard(user),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.displayName}さん',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '今日を楽しみましょう！',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日のサマリー',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final taskState = ref.watch(taskProvider);
                final habitState = ref.watch(habitProvider);
                
                return taskState.when(
                  data: (tasks) {
                    final todayTasks = tasks.where((t) => t.isToday).toList();
                    final completedToday = todayTasks.where((t) => t.isCompleted).length;
                    final totalToday = todayTasks.length;
                    final todayCompletionRate = totalToday > 0 ? completedToday / totalToday : 0.0;
                    final highPriorityToday = todayTasks.where((t) => 
                      (t.priority == TaskPriority.high || t.priority == TaskPriority.urgent) && 
                      !t.isCompleted
                    ).length;
                    
                    return habitState.when(
                      data: (habits) {
                        final activeHabits = habits.where((h) => h.status == HabitStatus.active).toList();
                        final completedHabits = activeHabits.where((h) => h.isCompletedToday).length;
                        final totalHabits = activeHabits.length;
                        final habitCompletionRate = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
                        
                        return Column(
                          children: [
                            // タスク統計
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    '今日のタスク',
                                    '$completedToday/$totalToday',
                                    Icons.task_alt,
                                    Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    'タスク完了率',
                                    '${(todayCompletionRate * 100).toInt()}%',
                                    Icons.trending_up,
                                    Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    '高優先度',
                                    '$highPriorityToday',
                                    Icons.priority_high,
                                    Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 習慣統計
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    '今日の習慣',
                                    '$completedHabits/$totalHabits',
                                    Icons.repeat,
                                    Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    '習慣完了率',
                                    '${(habitCompletionRate * 100).toInt()}%',
                                    Icons.check_circle,
                                    Colors.purple,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    '連続達成',
                                    '${user.stats.streakDays}日',
                                    Icons.local_fire_department,
                                    Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              '今日のタスク',
                              '$completedToday/$totalToday',
                              Icons.task_alt,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'タスク完了率',
                              '${(todayCompletionRate * 100).toInt()}%',
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              '高優先度',
                              '$highPriorityToday',
                              Icons.priority_high,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      error: (_, __) => Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              '今日のタスク',
                              '$completedToday/$totalToday',
                              Icons.task_alt,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'タスク完了率',
                              '${(todayCompletionRate * 100).toInt()}%',
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              '高優先度',
                              '$highPriorityToday',
                              Icons.priority_high,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          '今日のタスク',
                          '読み込み中...',
                          Icons.task_alt,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'タスク完了率',
                          '読み込み中...',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          '高優先度',
                          '読み込み中...',
                          Icons.priority_high,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  error: (_, __) => Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          '今日のタスク',
                          'エラー',
                          Icons.task_alt,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'タスク完了率',
                          'エラー',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          '高優先度',
                          'エラー',
                          Icons.priority_high,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessMenu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'クイックアクセス',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // メインアクション
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessItem(
                    'タスク',
                    Icons.task,
                    const Color(0xFF2196F3),
                    () => _navigateToTaskListWithFilter(TaskFilter.all),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessItem(
                    '習慣',
                    Icons.repeat,
                    Colors.green,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HabitListPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessItem(
                    '目標',
                    Icons.flag,
                    Colors.orange,
                    () {
                      // 目標管理機能は準備中です
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('目標管理機能は準備中です'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI推奨',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // AI推奨を更新
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '今日の生産性を向上させるための提案',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecommendationItem(
              '午前9時から11時は集中力が高い時間帯です。重要なタスクをこの時間に配置することをお勧めします。',
              Icons.lightbulb,
              Colors.amber,
            ),
            const SizedBox(height: 8),
            _buildRecommendationItem(
              '「運動」の習慣が3日間続いています。今日も継続して健康を維持しましょう。',
              Icons.fitness_center,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasksCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.today,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                const Text(
                  '今日のタスク',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer(
                  builder: (context, ref, child) {
                    final taskState = ref.watch(taskProvider);
                    return taskState.when(
                      data: (tasks) {
                        final todayTasks = tasks.where((task) => task.isToday).toList();
                        
                        if (todayTasks.isEmpty) return const SizedBox.shrink();
                        
                        return TextButton(
                          onPressed: () {
                            _navigateToTaskListWithFilter(TaskFilter.today);
                          },
                          child: const Text('設定'),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final taskState = ref.watch(taskProvider);
                return taskState.when(
                  data: (tasks) {
                    final todayTasks = tasks.where((task) => task.isToday).toList();
                    
                    if (todayTasks.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Colors.green[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '今日のタスクは完了です！',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '素晴らしい一日でした',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // 優先度順にソート
                    todayTasks.sort((a, b) {
                      if (a.isCompleted != b.isCompleted) {
                        return a.isCompleted ? 1 : -1;
                      }
                      return b.priority.index.compareTo(a.priority.index);
                    });
                    
                    return Column(
                      children: [
                        // 進捗バー
                        if (todayTasks.isNotEmpty) ...[
                          Consumer(
                            builder: (context, ref, child) {
                              final completedCount = todayTasks.where((t) => t.isCompleted).length;
                              final totalCount = todayTasks.length;
                              final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
                              
                              return Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(progress * 100).toInt()}% 完了',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                        ],
                        
                        // タスクリスト
                        ...todayTasks.map((task) => _buildTodayTaskItem(task, context)),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'タスクの読み込みに失敗しました',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(taskProvider.notifier).loadTasks();
                          },
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTaskItem(Task task, BuildContext context) {
    final isCompleted = task.isCompleted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // 完了チェックボックス
          GestureDetector(
            onTap: () {
              if (isCompleted) {
                ref.read(taskProvider.notifier).uncompleteTask(task.id);
              } else {
                ref.read(taskProvider.notifier).completeTask(task.id);
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // タスク情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タスクタイトルと優先度バッジを縦に配置
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey[600] : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // 優先度バッジとサブタスク情報を横に配置
                Row(
                  children: [
                    // 優先度バッジ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.priority.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    if (task.subTasks.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.subTasks.where((t) => t.isCompleted).length}/${task.subTasks.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // 操作ボタン
          if (!isCompleted) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TaskListPage(),
                  ),
                );
              },
              color: Colors.blue[600],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitsCard() {
    final habitsState = ref.watch(habitProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.repeat,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                const Text(
                  '習慣トラッキング',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HabitListPage(),
                      ),
                    );
                  },
                  child: const Text('設定'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            habitsState.when(
              data: (habits) {
                // statusがactiveの習慣のみ表示
                final activeHabits = habits.where((h) => h.status == HabitStatus.active).toList();
                if (activeHabits.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '今日の習慣はありません\n新しい習慣を作成しましょう',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }
                final completedHabits = activeHabits.where((h) => h.isCompletedToday).length;
                final totalHabits = activeHabits.length;
                final completionRate = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
                return Column(
                  children: [
                    // サマリー情報
                    Row(
                      children: [
                        Expanded(
                          child: _buildHabitSummaryItem(
                            '完了',
                            completedHabits,
                            totalHabits,
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildHabitSummaryItem(
                            '残り',
                            totalHabits - completedHabits,
                            totalHabits,
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 進捗バー
                    LinearProgressIndicator(
                      value: completionRate,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(completionRate * 100).toInt()}% 完了',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 習慣リスト（最大3つまで表示）
                    ...activeHabits.take(3).map((habit) => _buildHabitListItem(habit)),
                    if (activeHabits.length > 3) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '他 ${activeHabits.length - 3} 個の習慣...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '習慣の読み込みに失敗しました',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(habitProvider.notifier).loadTodayHabits();
                        },
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitSummaryItem(String label, int count, int total, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitListItem(Habit habit) {
    final isCompleted = habit.isCompletedToday;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _getCategoryColor(habit.category),
              child: Icon(
                habit.frequency.icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(habit.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          habit.category.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getCategoryColor(habit.category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        habit.frequency.icon,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        habit.frequency.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.currentStreak}日',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // 習慣の日々の取り組みを記録
                ref.read(habitProvider.notifier).recordDailyCompletion(habit.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Colors.green;
      case HabitCategory.work:
        return Colors.blue;
      case HabitCategory.learning:
        return Colors.purple;
      case HabitCategory.fitness:
        return Colors.orange;
      case HabitCategory.mindfulness:
        return Colors.teal;
      case HabitCategory.social:
        return Colors.pink;
      case HabitCategory.financial:
        return Colors.amber;
      case HabitCategory.creative:
        return Colors.indigo;
      case HabitCategory.personal:
        return Colors.cyan;
      case HabitCategory.other:
        return Colors.grey;
    }
  }

  Widget _buildProductivityCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(width: 8),
                const Text(
                  '生産性分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // 詳細分析ページに遷移
                  },
                  child: const Text('詳細'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // タスク統計
            Consumer(
              builder: (context, ref, child) {
                final taskState = ref.watch(taskProvider);
                return taskState.when(
                  data: (tasks) {
                    final totalTasks = tasks.length;
                    final completedTasks = tasks.where((t) => t.isCompleted).length;
                    final todayTasks = tasks.where((t) => t.isToday).toList();
                    final completedToday = todayTasks.where((t) => t.isCompleted).length;
                    final totalToday = todayTasks.length;
                    
                    // 優先度別分布
                    final highPriorityTasks = tasks.where((t) => t.priority == TaskPriority.high || t.priority == TaskPriority.urgent).length;
                    final mediumPriorityTasks = tasks.where((t) => t.priority == TaskPriority.medium).length;
                    final lowPriorityTasks = tasks.where((t) => t.priority == TaskPriority.low).length;
                    
                    // サブタスク統計
                    final totalSubTasks = tasks.fold<int>(0, (sum, task) => sum + task.subTasks.length);
                    final completedSubTasks = tasks.fold<int>(0, (sum, task) => sum + task.subTasks.where((st) => st.isCompleted).length);
                    
                    return Column(
                      children: [
                        // メイン統計
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '全体完了率',
                                '${totalTasks > 0 ? ((completedTasks / totalTasks) * 100).toInt() : 0}%',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatItem(
                                '今日の完了率',
                                '${totalToday > 0 ? ((completedToday / totalToday) * 100).toInt() : 0}%',
                                Icons.today,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 優先度分布
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '高優先度',
                                '$highPriorityTasks',
                                Icons.priority_high,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatItem(
                                '中優先度',
                                '$mediumPriorityTasks',
                                Icons.remove,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatItem(
                                '低優先度',
                                '$lowPriorityTasks',
                                Icons.keyboard_arrow_down,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // サブタスク進捗
                        if (totalSubTasks > 0) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'サブタスク',
                                  '$completedSubTasks/$totalSubTasks',
                                  Icons.checklist,
                                  Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatItem(
                                  'サブタスク完了率',
                                  '${totalSubTasks > 0 ? ((completedSubTasks / totalSubTasks) * 100).toInt() : 0}%',
                                  Icons.analytics,
                                  Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // ユーザー統計
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '今週の完了率',
                                '${(user.stats.completionRate * 100).toInt()}%',
                                Icons.trending_up,
                                const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatItem(
                                '連続達成日数',
                                '${user.stats.streakDays}日',
                                Icons.local_fire_department,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '統計の読み込みに失敗しました',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  void _navigateToTaskListWithFilter(TaskFilter filter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskListPage(initialFilter: filter),
      ),
    );
  }
} 