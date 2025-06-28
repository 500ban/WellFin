import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_provider.dart';

class AddGoalDialog extends ConsumerStatefulWidget {
  final Goal? goal;
  const AddGoalDialog({super.key, this.goal});

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _targetValueController;
  late TextEditingController _unitController;
  GoalCategory _category = GoalCategory.personal;
  GoalPriority _priority = GoalPriority.medium;
  GoalType _type = GoalType.general;
  DateTime? _targetDate;
  double _progress = 0.0;
  double _targetValue = 0.0;
  String _unit = '';
  List<Milestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _descriptionController = TextEditingController(text: goal?.description ?? '');
    _notesController = TextEditingController(text: goal?.notes ?? '');
    _targetValueController = TextEditingController(text: (goal?.targetValue ?? 0).toString());
    _unitController = TextEditingController(text: goal?.unit ?? '');
    _category = goal?.category ?? GoalCategory.personal;
    _priority = goal?.priority ?? GoalPriority.medium;
    _type = goal?.type ?? GoalType.general;
    _targetDate = goal?.targetDate;
    _progress = goal?.progress ?? 0.0;
    _targetValue = goal?.targetValue ?? 0.0;
    _unit = goal?.unit ?? '';
    _milestones = goal?.milestones ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                  Icon(
                    widget.goal == null ? Icons.add_circle : Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.goal == null ? '目標を追加' : '目標を編集',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            // スクロール可能なコンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'タイトル *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'タイトルは必須です' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '説明',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<GoalCategory>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'カテゴリ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: GoalCategory.values.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        )).toList(),
                        onChanged: (c) {
                          if (c != null) setState(() => _category = c);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<GoalPriority>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: '優先度',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.priority_high),
                        ),
                        items: GoalPriority.values.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.label),
                        )).toList(),
                        onChanged: (p) {
                          if (p != null) setState(() => _priority = p);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<GoalType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: '目標タイプ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.type_specimen),
                        ),
                        items: GoalType.values.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        )).toList(),
                        onChanged: (t) {
                          if (t != null) setState(() => _type = t);
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('目標日'),
                        subtitle: Text(_targetDate != null ? _formatDate(_targetDate!) : '未設定'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_targetDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _targetDate = null),
                              ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                );
                                if (picked != null) {
                                  setState(() => _targetDate = picked);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('進捗', style: TextStyle(fontWeight: FontWeight.w500)),
                          Expanded(
                            child: Slider(
                              value: _progress,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              label: '${(_progress * 100).toInt()}%',
                              onChanged: (value) {
                                setState(() => _progress = value);
                                
                                // 進捗が100%になった場合、完了通知を表示
                                if (value >= 1.0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🎉 進捗が100%になりました！保存すると目標が完了状態になります。'),
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
                      const SizedBox(height: 16),
                      if (_type == GoalType.numeric) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _targetValueController,
                                decoration: const InputDecoration(
                                  labelText: '目標値',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.track_changes),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _targetValue = double.tryParse(value) ?? 0.0;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _unitController,
                                decoration: const InputDecoration(
                                  labelText: '単位',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.straighten),
                                ),
                                onChanged: (value) => _unit = value,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      ExpansionTile(
                        title: const Text('マイルストーン'),
                        leading: const Icon(Icons.flag),
                        children: [
                          ..._milestones.map((milestone) => ListTile(
                            title: Text(milestone.title),
                            subtitle: Text('${_formatDate(milestone.targetDate)} - ${milestone.isCompleted ? '完了' : '未完了'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _milestones.remove(milestone);
                                });
                              },
                            ),
                          )),
                          ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('マイルストーンを追加'),
                            onTap: _showAddMilestoneDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'メモ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: const Text('詳細設定'),
                        leading: const Icon(Icons.settings),
                        children: [
                          SwitchListTile(
                            title: const Text('アクティブ'),
                            subtitle: const Text('目標をアクティブにする'),
                            value: widget.goal?.isActive ?? true,
                            onChanged: (value) {
                              // この値はGoalエンティティで管理
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _onSubmit,
                    icon: Icon(widget.goal == null ? Icons.add : Icons.save),
                    label: Text(widget.goal == null ? '追加' : '更新'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              subtitle: Text(selectedDate != null ? _formatDate(selectedDate!) : '未設定'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
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
              if (titleController.text.trim().isNotEmpty && selectedDate != null) {
                setState(() {
                  _milestones.add(Milestone(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    targetDate: selectedDate!,
                    isCompleted: false,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final notifier = ref.read(goalNotifierProvider.notifier);
    final now = DateTime.now();
    
    // 数値目標の場合のバリデーション
    if (_type == GoalType.numeric) {
      final targetValue = double.tryParse(_targetValueController.text);
      if (targetValue == null || targetValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('有効な目標値を入力してください')),
        );
        return;
      }
      _targetValue = targetValue;
    }
    
    final goal = Goal(
      id: widget.goal?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: widget.goal?.createdAt ?? now,
      startDate: widget.goal?.startDate ?? now,
      targetDate: _targetDate,
      category: _category,
      priority: _priority,
      status: widget.goal?.status ?? GoalStatus.active,
      progress: _progress,
      milestones: _milestones,
      tags: widget.goal?.tags ?? [],
      color: widget.goal?.color ?? '#2196F3',
      isActive: widget.goal?.isActive ?? true,
      iconName: widget.goal?.iconName,
      notes: _notesController.text.trim(),
      type: _type,
      targetValue: _targetValue,
      unit: _unit,
      progressHistory: widget.goal?.progressHistory ?? [],
    );
    
    try {
      if (widget.goal == null) {
        await notifier.createGoal(goal);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('目標を追加しました')),
          );
        }
      } else {
        await notifier.updateGoal(goal);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('目標を更新しました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
} 