import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_provider.dart';
import 'add_goal_dialog.dart';

/// 目標詳細ダイアログ
class GoalDetailDialog extends ConsumerStatefulWidget {
  final Goal goal;
  
  const GoalDetailDialog({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailDialog> createState() => _GoalDetailDialogState();
}

class _GoalDetailDialogState extends ConsumerState<GoalDetailDialog> {
  late double _progress;
  List<Milestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    _progress = widget.goal.progress;
    _milestones = List.from(widget.goal.milestones);
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    
    return Dialog(
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 固定ヘッダー
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      // 編集ダイアログを表示
                      showDialog(
                        context: context,
                        builder: (context) => AddGoalDialog(goal: goal),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // スクロール可能なコンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.description),
                    const SizedBox(height: 16),
                    _buildDetailRow('カテゴリ', goal.category.label),
                    _buildDetailRow('優先度', goal.priority.label),
                    _buildDetailRow('ステータス', goal.status.label),
                    _buildDetailRow('進捗', '${(_progress * 100).toInt()}%'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('進捗更新', style: TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(
                          child: Slider(
                            value: _progress,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: '${(_progress * 100).toInt()}%',
                            onChanged: (value) {
                              setState(() {
                                _progress = value;
                              });
                              ref.read(goalNotifierProvider.notifier)
                                  .updateGoalProgress(goal.id, value);
                              
                              // 進捗が100%になった場合、完了通知を表示
                              if (value >= 1.0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 目標が完了しました！'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        Text('${(_progress * 100).toInt()}%'),
                      ],
                    ),
                    if (goal.targetDate != null)
                      _buildDetailRow('目標日', _formatDate(goal.targetDate!)),
                    if (goal.remainingDays != null)
                      _buildDetailRow('残り日数', '${goal.remainingDays}日'),
                    const SizedBox(height: 16),
                    if (_milestones.isNotEmpty) ...[
                      const Text(
                        'マイルストーン',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._milestones.map((milestone) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            // マイルストーンの完了状態を同期的に切り替え
                            final updatedMilestone = Milestone(
                              id: milestone.id,
                              title: milestone.title,
                              description: milestone.description,
                              targetDate: milestone.targetDate,
                              isCompleted: !milestone.isCompleted,
                            );
                            
                            // UIを即座に更新
                            setState(() {
                              // ローカルのgoalオブジェクトを更新
                              final updatedMilestones = _milestones.map((m) => 
                                m.id == milestone.id ? updatedMilestone : m
                              ).toList();

                              // widget.goalを更新するために、親ウィジェットに通知
                              // この場合、goalはfinalなので、代わりにローカル状態で管理
                              _milestones = updatedMilestones;
                            });
                            
                            // バックグラウンドでFirestoreを更新
                            ref.read(goalNotifierProvider.notifier)
                                .updateMilestone(goal.id, milestone.id, updatedMilestone);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Icon(
                                  milestone.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: milestone.isCompleted ? Colors.green : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        milestone.title,
                                        style: TextStyle(
                                          decoration: milestone.isCompleted 
                                              ? TextDecoration.lineThrough 
                                              : null,
                                          color: milestone.isCompleted 
                                              ? Colors.grey 
                                              : null,
                                        ),
                                      ),
                                      if (milestone.description.isNotEmpty)
                                        Text(
                                          milestone.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            decoration: milestone.isCompleted 
                                                ? TextDecoration.lineThrough 
                                                : null,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDate(milestone.targetDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: milestone.isCompleted ? Colors.grey : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            
            // 固定フッター（ボタン）
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // マイルストーン追加ダイアログを表示
                    _showMilestoneDialog(goal);
                  },
                  child: const Text('マイルストーン追加'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 詳細行を構築
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _showMilestoneDialog(Goal goal) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('マイルストーンを追加'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('目標日'),
                  subtitle: Text(_formatDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
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
                  if (titleController.text.trim().isNotEmpty) {
                    final milestone = Milestone(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      targetDate: selectedDate,
                    );
                    Navigator.pop(context);
                    
                    // ローカル状態を同期的に更新
                    setState(() {
                      _milestones.add(milestone);
                    });
                    
                    // バックグラウンドでFirestoreを更新
                    ref.read(goalNotifierProvider.notifier)
                        .addMilestone(goal.id, milestone);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('マイルストーンを追加しました')),
                    );
                  }
                },
                child: const Text('追加'),
              ),
            ],
          );
        },
      ),
    );
  }
} 