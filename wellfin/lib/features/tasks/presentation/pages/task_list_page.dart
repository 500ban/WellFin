import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_detail_dialog.dart';
import '../widgets/edit_task_dialog.dart';
import '../providers/task_provider.dart';

/// タスク一覧ページ
class TaskListPage extends ConsumerStatefulWidget {
  final TaskFilter? initialFilter;
  
  const TaskListPage({super.key, this.initialFilter});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  late TaskFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter ?? TaskFilter.all;
    // ページ読み込み時にタスクを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 検索機能を実装
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // フィルターバー
          TaskFilterBar(
            currentFilter: _currentFilter,
            onFilterChanged: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
          ),
          // タスク一覧
          Expanded(
            child: taskState.when(
              data: (tasks) => _buildTaskList(tasks),
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
                      style: Theme.of(context).textTheme.titleLarge,
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
                        ref.read(taskProvider.notifier).loadTasks();
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
          _showAddTaskDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    // フィルターに応じてタスクをフィルタリング
    final filteredTasks = _filterTasks(tasks);

    if (filteredTasks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(
            task: task,
            onTap: () => _showTaskDetailDialog(task),
            onComplete: () => _completeTask(task),
            onDelete: () => _deleteTask(task),
            onEdit: () => _showEditTaskDialog(task),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyStateIcon(),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubMessage(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTaskDialog(),
            icon: const Icon(Icons.add),
            label: const Text('タスクを追加'),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_currentFilter) {
      case TaskFilter.all:
        return Icons.task_alt;
      case TaskFilter.today:
        return Icons.today;
      case TaskFilter.completed:
        return Icons.check_circle;
      case TaskFilter.pending:
        return Icons.pending;
      case TaskFilter.overdue:
        return Icons.warning;
    }
  }

  String _getEmptyStateMessage() {
    switch (_currentFilter) {
      case TaskFilter.all:
        return 'タスクがありません';
      case TaskFilter.today:
        return '今日のタスクがありません';
      case TaskFilter.completed:
        return '完了したタスクがありません';
      case TaskFilter.pending:
        return '保留中のタスクがありません';
      case TaskFilter.overdue:
        return '期限切れのタスクがありません';
    }
  }

  String _getEmptyStateSubMessage() {
    switch (_currentFilter) {
      case TaskFilter.all:
        return '新しいタスクを追加して\n生産性を向上させましょう';
      case TaskFilter.today:
        return '今日はタスクがありません\n明日の準備をしましょう';
      case TaskFilter.completed:
        return 'まだ完了したタスクがありません\nタスクを完了させて進捗を確認しましょう';
      case TaskFilter.pending:
        return '保留中のタスクがありません\nすべてのタスクが完了しています';
      case TaskFilter.overdue:
        return '期限切れのタスクがありません\n素晴らしい管理です！';
    }
  }

  List<Task> _filterTasks(List<Task> tasks) {
    switch (_currentFilter) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.today:
        return tasks.where((task) => task.isToday).toList();
      case TaskFilter.completed:
        return tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.pending:
        return tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.overdue:
        return tasks.where((task) => task.isOverdue).toList();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskFilter.values.map((filter) {
            return RadioListTile<TaskFilter>(
              title: Text(filter.label),
              value: filter,
              groupValue: _currentFilter,
              onChanged: (value) {
                setState(() {
                  _currentFilter = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }

  void _showTaskDetailDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(task: task),
    );
  }

  void _showEditTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(task: task),
    );
  }

  void _completeTask(Task task) {
    ref.read(taskProvider.notifier).completeTask(task.id);
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: Text('「${task.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(task.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
} 