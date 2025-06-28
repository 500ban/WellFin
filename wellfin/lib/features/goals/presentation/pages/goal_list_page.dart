import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_provider.dart';
import '../widgets/goal_card.dart';
import '../widgets/add_goal_dialog.dart';
import '../widgets/goal_filter_bar.dart';
import '../widgets/goal_stats_widget.dart';
import '../widgets/goal_detail_dialog.dart';

/// 目標一覧ページ
class GoalListPage extends ConsumerStatefulWidget {
  const GoalListPage({super.key});

  @override
  ConsumerState<GoalListPage> createState() => _GoalListPageState();
}

class _GoalListPageState extends ConsumerState<GoalListPage> {
  GoalCategory? _selectedCategory;
  GoalPriority? _selectedPriority;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // 初期データを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalNotifierProvider.notifier).loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalNotifierProvider);
    final statisticsAsync = ref.watch(goalStatisticsEfficientProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目標'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 統計情報
          statisticsAsync.when(
            data: (statistics) => GoalStatsWidget(statistics: statistics),
            loading: () => const Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('統計情報の読み込みに失敗しました: $error'),
              ),
            ),
          ),
          
          // フィルターバー
          GoalFilterBar(
            selectedCategory: _selectedCategory,
            selectedPriority: _selectedPriority,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            onPriorityChanged: (priority) {
              setState(() {
                _selectedPriority = priority;
              });
            },
          ),
          
          // 目標一覧
          Expanded(
            child: goalsAsync.when(
              data: (goals) {
                final filteredGoals = _filterGoals(goals);
                
                if (filteredGoals.isEmpty) {
                  return _buildEmptyState();
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(goalNotifierProvider.notifier).loadGoals();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: filteredGoals.length,
                    itemBuilder: (context, index) {
                      final goal = filteredGoals[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GoalCard(
                          goal: goal,
                          onTap: () => _showGoalDetailDialog(goal),
                          onEdit: () => _showEditGoalDialog(goal),
                          onDelete: () => _showDeleteConfirmation(goal),
                          onProgressUpdate: (progress) {
                            ref.read(goalNotifierProvider.notifier)
                                .updateGoalProgress(goal.id, progress);
                          },
                          onStatusChange: (status) {
                            _updateGoalStatus(goal, status);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('目標の読み込みに失敗しました'),
                    const SizedBox(height: 8),
                    Text('$error', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(goalNotifierProvider.notifier).loadGoals();
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
        onPressed: () => _showAddGoalDialog(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 目標をフィルター
  List<Goal> _filterGoals(List<Goal> goals) {
    return goals.where((goal) {
      // カテゴリフィルター
      if (_selectedCategory != null && goal.category != _selectedCategory) {
        return false;
      }
      
      // 優先度フィルター
      if (_selectedPriority != null && goal.priority != _selectedPriority) {
        return false;
      }
      
      // 検索フィルター
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = goal.title.toLowerCase().contains(query);
        final matchesDescription = goal.description.toLowerCase().contains(query);
        final matchesTags = goal.tags.any((tag) => tag.toLowerCase().contains(query));
        
        if (!matchesTitle && !matchesDescription && !matchesTags) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// 空の状態を表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'アクティブな目標がありません',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '新しい目標を作成して始めましょう',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddGoalDialog(),
            icon: const Icon(Icons.add),
            label: const Text('目標を作成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 目標追加ダイアログを表示
  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddGoalDialog(),
    );
  }

  /// 目標編集ダイアログを表示
  void _showEditGoalDialog(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AddGoalDialog(goal: goal),
    );
  }

  /// 目標詳細ダイアログを表示
  void _showGoalDetailDialog(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => GoalDetailDialog(goal: goal),
    );
  }

  /// 削除確認ダイアログを表示
  void _showDeleteConfirmation(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('目標を削除'),
        content: Text('「${goal.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(goalNotifierProvider.notifier).deleteGoal(goal.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('目標を削除しました')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 検索ダイアログを表示
  void _showSearchDialog() {
    final controller = TextEditingController(text: _searchQuery);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('目標を検索'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '検索キーワード',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('検索'),
          ),
        ],
      ),
    );
  }

  /// 並び替えダイアログを表示
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('並び替え'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GoalSortOption.values.map((option) {
            return ListTile(
              title: Text(option.label),
              onTap: () {
                Navigator.pop(context);
                // TODO: 並び替え機能を実装
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 目標ステータスを更新
  void _updateGoalStatus(Goal goal, GoalStatus status) {
    switch (status) {
      case GoalStatus.completed:
        ref.read(goalNotifierProvider.notifier).markGoalAsCompleted(goal.id);
        break;
      case GoalStatus.paused:
        ref.read(goalNotifierProvider.notifier).pauseGoal(goal.id);
        break;
      case GoalStatus.active:
        ref.read(goalNotifierProvider.notifier).resumeGoal(goal.id);
        break;
      case GoalStatus.cancelled:
        ref.read(goalNotifierProvider.notifier).cancelGoal(goal.id);
        break;
    }
  }
} 