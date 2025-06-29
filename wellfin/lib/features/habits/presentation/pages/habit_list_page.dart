import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/edit_habit_dialog.dart';

class HabitListPage extends ConsumerStatefulWidget {
  const HabitListPage({super.key});

  @override
  ConsumerState<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends ConsumerState<HabitListPage> {
  HabitStatus _selectedStatus = HabitStatus.active;

  @override
  void initState() {
    super.initState();
    // ページ読み込み時に全習慣を取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitProvider.notifier).loadAllHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsState = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('習慣'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(habitProvider.notifier).loadAllHabits();
            },
            tooltip: '更新',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              // 習慣統計ページに遷移
              _showHabitStatistics(context);
            },
            tooltip: '統計',
          ),
        ],
      ),
      body: Column(
        children: [
          // ステータスフィルター
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<HabitStatus>(
                    segments: const [
                      ButtonSegment<HabitStatus>(
                        value: HabitStatus.active,
                        label: Text('アクティブ'),
                        icon: Icon(Icons.play_arrow),
                      ),
                      ButtonSegment<HabitStatus>(
                        value: HabitStatus.paused,
                        label: Text('一時停止'),
                        icon: Icon(Icons.pause),
                      ),
                      ButtonSegment<HabitStatus>(
                        value: HabitStatus.finished,
                        label: Text('終了'),
                        icon: Icon(Icons.flag),
                      ),
                    ],
                    selected: {_selectedStatus},
                    onSelectionChanged: (Set<HabitStatus> selection) {
                      setState(() {
                        _selectedStatus = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // 習慣リスト
          Expanded(
            child: habitsState.when(
              data: (habits) {
                final filteredHabits = habits.where((habit) => habit.status == _selectedStatus).toList();
                if (filteredHabits.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildHabitList(filteredHabits);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'エラーが発生しました',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(habitProvider.notifier).loadAllHabits();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddHabitDialog(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subMessage;
    
    switch (_selectedStatus) {
      case HabitStatus.active:
        message = 'アクティブな習慣がありません';
        subMessage = '新しい習慣を作成するか、\n一時停止中の習慣を再開しましょう';
        break;
      case HabitStatus.paused:
        message = '一時停止中の習慣がありません';
        subMessage = 'アクティブな習慣を一時停止すると\nここに表示されます';
        break;
      case HabitStatus.finished:
        message = '終了した習慣がありません';
        subMessage = '習慣を終了すると\nここに表示されます';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedStatus == HabitStatus.active ? Icons.psychology :
            _selectedStatus == HabitStatus.paused ? Icons.pause_circle :
            Icons.flag,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedStatus == HabitStatus.active) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _showAddHabitDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('習慣を作成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitList(List<Habit> habits) {
    // 習慣をカテゴリ別にグループ化
    final habitsByCategory = <String, List<Habit>>{};
    for (final habit in habits) {
      final category = habit.category.label;
      habitsByCategory.putIfAbsent(category, () => []).add(habit);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habitsByCategory.length,
      itemBuilder: (context, index) {
        final category = habitsByCategory.keys.elementAt(index);
        final categoryHabits = habitsByCategory[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ...categoryHabits.map((habit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildHabitCard(habit),
            )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final isCompleted = habit.isCompleted;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          _getCategoryIcon(habit.category),
          color: _getCategoryColor(habit.category),
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                habit.title,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${habit.frequency.label} • ${habit.description.isNotEmpty ? habit.description : '説明なし'}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'finish':
                ref.read(habitProvider.notifier).finishHabit(habit.id);
                break;
              case 'pause':
                ref.read(habitProvider.notifier).pauseHabit(habit.id);
                break;
              case 'resume':
                ref.read(habitProvider.notifier).resumeHabit(habit.id);
                break;
              case 'delete':
                _showDeleteConfirmation(context, habit);
                break;
            }
          },
          itemBuilder: (context) => [
            if (habit.isInProgress)
              const PopupMenuItem(
                value: 'pause',
                child: Row(
                  children: [
                    Icon(Icons.pause, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('一時停止'),
                  ],
                ),
              ),
            if (habit.isPaused)
              const PopupMenuItem(
                value: 'resume',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, color: Colors.green),
                    SizedBox(width: 8),
                    Text('再開'),
                  ],
                ),
              ),
            if (!habit.isCompleted)
              const PopupMenuItem(
                value: 'finish',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('終了'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('削除'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _showHabitDetailDialog(context, habit);
        },
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

  IconData _getCategoryIcon(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Icons.health_and_safety;
      case HabitCategory.work:
        return Icons.work;
      case HabitCategory.learning:
        return Icons.book;
      case HabitCategory.fitness:
        return Icons.fitness_center;
      case HabitCategory.mindfulness:
        return Icons.self_improvement;
      case HabitCategory.social:
        return Icons.group;
      case HabitCategory.financial:
        return Icons.attach_money;
      case HabitCategory.creative:
        return Icons.palette;
      case HabitCategory.personal:
        return Icons.person;
      case HabitCategory.other:
        return Icons.help_outline;
    }
  }

  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );
  }

  void _showHabitDetailDialog(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(habit.category),
                      color: _getCategoryColor(habit.category),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditHabitDialog(context, habit);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHabitDetailContent(context, habit),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('閉じる'),
                    ),
                    if (habit.isInProgress && !habit.isCompletedToday)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.read(habitProvider.notifier).recordDailyCompletion(habit.id);
                        },
                        child: const Text('記録'),
                      ),
                    if (habit.isInProgress && habit.isCompletedToday)
                      ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('完了済み'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitDetailContent(BuildContext context, Habit habit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 説明
        if (habit.description.isNotEmpty) ...[
          Text(
            '説明',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            habit.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        
        // 基本情報
        _buildInfoRow(
          context,
          'カテゴリ',
          habit.category.label,
          _getCategoryIcon(habit.category),
          _getCategoryColor(habit.category),
        ),
        
        _buildInfoRow(
          context,
          '頻度',
          '${habit.frequency.label} - ${habit.frequency.description}',
          Icons.repeat,
          Colors.blue,
        ),
        
        if (habit.frequency == HabitFrequency.weekly && habit.targetDays.isNotEmpty)
          _buildInfoRow(
            context,
            '実行曜日',
            habit.targetDays.map((d) => d.label).join(', '),
            Icons.calendar_today,
            Colors.orange,
          ),
        
        _buildInfoRow(
          context,
          '優先度',
          habit.priority.label,
          Icons.priority_high,
          _getPriorityColor(habit.priority),
        ),
        
        _buildInfoRow(
          context,
          'ステータス',
          habit.status.label,
          _getStatusIcon(habit.status),
          _getStatusColor(habit.status),
        ),
        
        const SizedBox(height: 16),
        
        // 統計情報
        Text(
          '統計',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildInfoRow(
          context,
          '現在のストリーク',
          '${habit.currentStreak}日',
          Icons.local_fire_department,
          Colors.orange,
        ),
        
        _buildInfoRow(
          context,
          '最長ストリーク',
          '${habit.longestStreak}日',
          Icons.emoji_events,
          Colors.amber,
        ),
        
        _buildInfoRow(
          context,
          '総完了回数',
          '${habit.totalCompletions}回',
          Icons.check_circle,
          Colors.green,
        ),
        
        _buildInfoRow(
          context,
          '今日の取り組み',
          habit.isCompletedToday ? '完了済み' : '未完了',
          habit.isCompletedToday ? Icons.check_circle : Icons.pending,
          habit.isCompletedToday ? Colors.green : Colors.grey,
        ),
        
        if (habit.completions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '最近の完了履歴',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...habit.completions
              .take(5)
              .map((completion) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          '${completion.completedAt.year}/${completion.completedAt.month}/${completion.completedAt.day}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(HabitPriority priority) {
    switch (priority) {
      case HabitPriority.low:
        return Colors.green;
      case HabitPriority.medium:
        return Colors.orange;
      case HabitPriority.high:
        return Colors.red;
      case HabitPriority.critical:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(HabitStatus status) {
    switch (status) {
      case HabitStatus.active:
        return Icons.play_arrow;
      case HabitStatus.paused:
        return Icons.pause;
      case HabitStatus.finished:
        return Icons.flag;
    }
  }

  Color _getStatusColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.active:
        return Colors.green;
      case HabitStatus.paused:
        return Colors.orange;
      case HabitStatus.finished:
        return Colors.blue;
    }
  }

  void _showEditHabitDialog(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => EditHabitDialog(habit: habit),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('習慣を削除'),
        content: Text('「${habit.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(habitProvider.notifier).deleteHabit(habit.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showHabitStatistics(BuildContext context) {
    final habitsState = ref.watch(habitProvider);
    
    habitsState.when(
      data: (habits) {
        final activeHabits = habits.where((h) => h.status == HabitStatus.active).length;
        final pausedHabits = habits.where((h) => h.status == HabitStatus.paused).length;
        final finishedHabits = habits.where((h) => h.status == HabitStatus.finished).length;
        final totalHabits = habits.length;
        
        final totalCompletions = habits.fold<int>(0, (sum, habit) => sum + habit.totalCompletions);
        final averageStreak = habits.isEmpty ? 0.0 : 
            habits.map((h) => h.currentStreak).reduce((a, b) => a + b) / habits.length;
        
        final categoryDistribution = <String, int>{};
        for (final habit in habits) {
          final category = habit.category.label;
          categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
        }
        
        final mostPopularCategory = categoryDistribution.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('習慣統計'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 基本統計
                  _buildStatRow('総習慣数', '$totalHabits個'),
                  _buildStatRow('アクティブ', '$activeHabits個'),
                  _buildStatRow('一時停止', '$pausedHabits個'),
                  _buildStatRow('終了', '$finishedHabits個'),
                  
                  const SizedBox(height: 16),
                  
                  // パフォーマンス統計
                  _buildStatRow('総完了回数', '$totalCompletions回'),
                  _buildStatRow('平均ストリーク', '${averageStreak.toStringAsFixed(1)}日'),
                  _buildStatRow('人気カテゴリ', '${mostPopularCategory.key} (${mostPopularCategory.value}個)'),
                  
                  const SizedBox(height: 16),
                  
                  // カテゴリ分布
                  Text(
                    'カテゴリ分布',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...categoryDistribution.entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '${entry.value}個',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (habits.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    
                    // トップ習慣
                    Text(
                      'トップ習慣（ストリーク順）',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(() {
                      final topHabits = habits
                          .where((h) => h.currentStreak > 0)
                          .toList()
                        ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
                      
                      return topHabits.take(3).map((habit) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: Colors.orange[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                habit.title,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${habit.currentStreak}日',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      ));
                    })(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      },
      loading: () => showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          content: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: Text('統計の取得に失敗しました: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 