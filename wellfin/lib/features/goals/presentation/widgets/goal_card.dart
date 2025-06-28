import 'package:flutter/material.dart';
import '../../domain/entities/goal.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<double>? onProgressUpdate;
  final ValueChanged<GoalStatus>? onStatusChange;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onProgressUpdate,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: _getCategoryColor(goal.category)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(goal.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                goal.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCategoryChip(goal.category),
                  const SizedBox(width: 8),
                  _buildPriorityChip(goal.priority),
                  const SizedBox(width: 8),
                  if (goal.targetDate != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(_formatDate(goal.targetDate!), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 進捗バー
              GestureDetector(
                onTap: () {
                  _showProgressUpdateDialog(context);
                },
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(goal.progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: '編集',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: '削除',
                    onPressed: onDelete,
                  ),
                  PopupMenuButton<GoalStatus>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (status) {
                      if (onStatusChange != null) {
                        onStatusChange!(status);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: GoalStatus.completed,
                        child: const Text('完了にする'),
                        enabled: goal.status != GoalStatus.completed,
                      ),
                      PopupMenuItem(
                        value: GoalStatus.paused,
                        child: const Text('一時停止'),
                        enabled: goal.status != GoalStatus.paused,
                      ),
                      PopupMenuItem(
                        value: GoalStatus.active,
                        child: const Text('再開'),
                        enabled: goal.status != GoalStatus.active,
                      ),
                      PopupMenuItem(
                        value: GoalStatus.cancelled,
                        child: const Text('キャンセル'),
                        enabled: goal.status != GoalStatus.cancelled,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(GoalCategory category) {
    switch (category) {
      case GoalCategory.personal:
        return Colors.indigo;
      case GoalCategory.health:
        return Colors.green;
      case GoalCategory.work:
        return Colors.blueGrey;
      case GoalCategory.learning:
        return Colors.orange;
      case GoalCategory.fitness:
        return Colors.redAccent;
      case GoalCategory.financial:
        return Colors.teal;
      case GoalCategory.creative:
        return Colors.purple;
      case GoalCategory.social:
        return Colors.pink;
      case GoalCategory.travel:
        return Colors.cyan;
      case GoalCategory.other:
        return Colors.grey;
    }
  }

  Widget _buildCategoryChip(GoalCategory category) {
    return Chip(
      label: Text(category.label, style: const TextStyle(fontSize: 12)),
      backgroundColor: _getCategoryColor(category).withOpacity(0.15),
      labelStyle: TextStyle(color: _getCategoryColor(category)),
    );
  }

  Widget _buildPriorityChip(GoalPriority priority) {
    Color color;
    switch (priority) {
      case GoalPriority.low:
        color = Colors.green;
        break;
      case GoalPriority.medium:
        color = Colors.blue;
        break;
      case GoalPriority.high:
        color = Colors.orange;
        break;
      case GoalPriority.critical:
        color = Colors.red;
        break;
    }
    return Chip(
      label: Text(priority.label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _buildStatusChip(GoalStatus status) {
    Color color;
    String label;
    switch (status) {
      case GoalStatus.active:
        color = Colors.blue;
        label = 'アクティブ';
        break;
      case GoalStatus.paused:
        color = Colors.orange;
        label = '一時停止';
        break;
      case GoalStatus.completed:
        color = Colors.green;
        label = '完了';
        break;
      case GoalStatus.cancelled:
        color = Colors.grey;
        label = 'キャンセル';
        break;
    }
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _showProgressUpdateDialog(BuildContext context) {
    double currentProgress = goal.progress;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('進捗を更新'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('現在の進捗: ${(currentProgress * 100).toInt()}%'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Slider(
                      value: currentProgress,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: '${(currentProgress * 100).toInt()}%',
                      onChanged: (value) {
                        setState(() {
                          currentProgress = value;
                        });
                      },
                    ),
                    Text('${(currentProgress * 100).toInt()}%'),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // 進捗を更新
              if (onProgressUpdate != null) {
                onProgressUpdate!(currentProgress);
              }
              
              // 進捗が100%になった場合、完了通知を表示
              if (currentProgress >= 1.0 && goal.status != GoalStatus.completed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 目標が完了しました！'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }
} 