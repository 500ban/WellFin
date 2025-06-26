import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';

/// タスク詳細ダイアログ
class TaskDetailDialog extends ConsumerWidget {
  final Task task;

  const TaskDetailDialog({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (!task.isCompleted)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 編集ダイアログを開く
              },
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 説明
            if (task.description.isNotEmpty) ...[
              Text(
                '説明',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            
            // ステータス
            _buildInfoRow(
              context,
              'ステータス',
              task.status.label,
              _getStatusIcon(task.status),
              _getStatusColor(task.status),
            ),
            
            // 優先度
            _buildInfoRow(
              context,
              '優先度',
              task.priority.label,
              _getPriorityIcon(task.priority),
              _getPriorityColor(task.priority),
            ),
            
            // 難易度
            _buildInfoRow(
              context,
              '難易度',
              task.difficulty.label,
              Icons.trending_up,
              _getDifficultyColor(task.difficulty),
            ),
            
            // 予定日
            _buildInfoRow(
              context,
              '予定日',
              _formatDate(task.scheduledDate),
              Icons.calendar_today,
              null,
            ),
            
            // 予定時間
            if (task.scheduledTimeStart != null) ...[
              _buildInfoRow(
                context,
                '予定時間',
                '${_formatTime(task.scheduledTimeStart!)} - ${_formatTime(task.scheduledTimeEnd ?? task.scheduledTimeStart!.add(Duration(minutes: task.estimatedDuration)))}',
                Icons.access_time,
                null,
              ),
            ],
            
            // 予想時間
            _buildInfoRow(
              context,
              '予想時間',
              '${task.estimatedDuration}分',
              Icons.timer,
              null,
            ),
            
            // 実際の時間
            if (task.actualDuration != null) ...[
              _buildInfoRow(
                context,
                '実際の時間',
                '${task.actualDuration}分',
                Icons.timer_outlined,
                null,
              ),
            ],
            
            // 作成日
            _buildInfoRow(
              context,
              '作成日',
              _formatDateTime(task.createdAt),
              Icons.create,
              null,
            ),
            
            // 完了日
            if (task.completedAt != null) ...[
              _buildInfoRow(
                context,
                '完了日',
                _formatDateTime(task.completedAt!),
                Icons.check_circle,
                Colors.green,
              ),
            ],
            
            // タグ
            if (task.tags.isNotEmpty) ...[
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
                children: task.tags.map((tag) {
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
            if (task.subTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'サブタスク',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...task.subTasks.map((subTask) {
                return ListTile(
                  leading: Icon(
                    subTask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: subTask.isCompleted ? Colors.green : Colors.grey,
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        if (!task.isCompleted) ...[
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).startTask(task.id);
              Navigator.of(context).pop();
            },
            child: const Text('開始'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(taskProvider.notifier).completeTask(task.id);
              Navigator.of(context).pop();
            },
            child: const Text('完了'),
          ),
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
} 