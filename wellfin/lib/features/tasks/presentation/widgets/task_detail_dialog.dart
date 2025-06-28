import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';
import 'edit_task_dialog.dart';

/// タスク詳細ダイアログ
class TaskDetailDialog extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailDialog({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends ConsumerState<TaskDetailDialog> {
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    // 最新のタスク状態を取得
    final tasksAsync = ref.watch(taskProvider);
    
    return tasksAsync.when(
      data: (tasks) {
        // 最新のタスク状態を取得
        final updatedTask = tasks.firstWhere(
          (task) => task.id == _currentTask.id,
          orElse: () => _currentTask,
        );
        
        // タスクが更新された場合は状態を更新
        if (updatedTask != _currentTask) {
          _currentTask = updatedTask;
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentTask.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (!_currentTask.isCompleted)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => EditTaskDialog(task: _currentTask),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailContent(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('閉じる'),
                      ),
                      if (!_currentTask.isCompleted) ...[
                        TextButton(
                          onPressed: () {
                            ref.read(taskProvider.notifier).startTask(_currentTask.id);
                            Navigator.of(context).pop();
                          },
                          child: const Text('開始'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(taskProvider.notifier).completeTask(_currentTask.id);
                            Navigator.of(context).pop();
                          },
                          child: const Text('完了'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 説明
        if (_currentTask.description.isNotEmpty) ...[
          Text(
            '説明',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTask.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        
        // ステータス
        _buildInfoRow(
          context,
          'ステータス',
          _currentTask.status.label,
          _getStatusIcon(_currentTask.status),
          _getStatusColor(_currentTask.status),
        ),
        
        // 優先度
        _buildInfoRow(
          context,
          '優先度',
          _currentTask.priority.label,
          _getPriorityIcon(_currentTask.priority),
          _getPriorityColor(_currentTask.priority),
        ),
        
        // 難易度
        _buildInfoRow(
          context,
          '難易度',
          _currentTask.difficulty.label,
          Icons.trending_up,
          _getDifficultyColor(_currentTask.difficulty),
        ),
        
        // 予定日
        _buildInfoRow(
          context,
          '予定日',
          _formatDate(_currentTask.scheduledDate),
          Icons.calendar_today,
          null,
        ),
        
        // 予定時間
        if (_currentTask.scheduledTimeStart != null) ...[
          _buildInfoRow(
            context,
            '予定時間',
            '${_formatTime(_currentTask.scheduledTimeStart!)} - ${_formatTime(_currentTask.scheduledTimeEnd ?? _currentTask.scheduledTimeStart!.add(Duration(minutes: _currentTask.estimatedDuration)))}',
            Icons.access_time,
            null,
          ),
        ],
        
        // 予想時間
        _buildInfoRow(
          context,
          '予想時間',
          '${_currentTask.estimatedDuration}分',
          Icons.timer,
          null,
        ),
        
        // 実際の時間
        if (_currentTask.actualDuration != null) ...[
          _buildInfoRow(
            context,
            '実際の時間',
            '${_currentTask.actualDuration}分',
            Icons.timer_outlined,
            null,
          ),
        ],
        
        // 作成日
        _buildInfoRow(
          context,
          '作成日',
          _formatDateTime(_currentTask.createdAt),
          Icons.create,
          null,
        ),
        
        // 完了日
        if (_currentTask.completedAt != null) ...[
          _buildInfoRow(
            context,
            '完了日',
            _formatDateTime(_currentTask.completedAt!),
            Icons.check_circle,
            Colors.green,
          ),
        ],
        
        // タグ
        if (_currentTask.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'タグ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _currentTask.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.blue[100],
                labelStyle: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
        
        // サブタスク
        if (_currentTask.subTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'サブタスク',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._currentTask.subTasks.map((subTask) {
            return ListTile(
              leading: IconButton(
                icon: Icon(
                  subTask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: subTask.isCompleted ? Colors.green : Colors.grey,
                ),
                onPressed: () => _toggleSubTaskCompletion(_currentTask, subTask, ref),
              ),
              title: Text(
                subTask.title,
                style: TextStyle(
                  decoration: subTask.isCompleted 
                      ? TextDecoration.lineThrough 
                      : null,
                ),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color? color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_arrow;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.delayed:
        return Icons.warning;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.delayed:
        return Colors.red;
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
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

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.expert:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  void _toggleSubTaskCompletion(Task task, SubTask subTask, WidgetRef ref) {
    final updatedTask = task.toggleSubTaskCompletion(subTask.id);
    ref.read(taskProvider.notifier).updateTask(updatedTask);
  }
} 