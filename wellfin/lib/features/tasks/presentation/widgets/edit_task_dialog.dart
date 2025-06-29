import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';

/// タスク編集ダイアログ
class EditTaskDialog extends ConsumerStatefulWidget {
  final Task task;

  const EditTaskDialog({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<EditTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _estimatedDuration;
  late TaskPriority _selectedPriority;
  late TaskDifficulty _selectedDifficulty;
  late List<String> _tags;
  bool _hasTime = false;
  
  // サブタスク関連
  late List<SubTask> _subTasks;
  final _subTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.scheduledDate;
    _selectedTime = widget.task.scheduledTimeStart != null
        ? TimeOfDay.fromDateTime(widget.task.scheduledTimeStart!)
        : TimeOfDay.now();
    _estimatedDuration = widget.task.estimatedDuration;
    _selectedPriority = widget.task.priority;
    _selectedDifficulty = widget.task.difficulty;
    _tags = List.from(widget.task.tags);
    _hasTime = widget.task.scheduledTimeStart != null;
    _subTasks = List.from(widget.task.subTasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            // 固定ヘッダー
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'タスクを編集',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // タスクステータスバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.task.isCompleted ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
            children: [
                        Icon(
                          widget.task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: widget.task.isCompleted ? Colors.green[600] : Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.task.isCompleted ? '完了' : '未完了',
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.task.isCompleted ? Colors.green[700] : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // スクロール可能なコンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                child: _buildFormFields(),
              ),
              ),
            ),
            
            // 固定フッター（ボタン）
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _updateTask,
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text('更新'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // タイトル
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'タイトル',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // 説明
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '説明',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        // 日付
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('予定日'),
          subtitle: Text('${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}'),
          onTap: () => _selectDate(context),
        ),
        
        // 時間設定
        CheckboxListTile(
          title: const Text('時間を設定'),
          value: _hasTime,
          onChanged: (value) {
            setState(() {
              _hasTime = value ?? false;
            });
          },
        ),
        if (_hasTime) ...[
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('時間'),
            subtitle: Text(_selectedTime.format(context)),
            onTap: () => _selectTime(context),
          ),
          const SizedBox(height: 8),
        ],
        
        // 予想時間
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('予想時間'),
          subtitle: Text('$_estimatedDuration分'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_estimatedDuration > 15) {
                    setState(() {
                      _estimatedDuration -= 15;
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _estimatedDuration += 15;
                  });
                },
              ),
            ],
          ),
        ),
        
        // 優先度
        ListTile(
          leading: const Icon(Icons.priority_high),
          title: const Text('優先度'),
          trailing: DropdownButton<TaskPriority>(
            value: _selectedPriority,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPriority = value;
                });
              }
            },
            items: TaskPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(priority.label),
              );
            }).toList(),
          ),
        ),
        
        // 難易度
        ListTile(
          leading: const Icon(Icons.trending_up),
          title: const Text('難易度'),
          trailing: DropdownButton<TaskDifficulty>(
            value: _selectedDifficulty,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDifficulty = value;
                });
              }
            },
            items: TaskDifficulty.values.map((difficulty) {
              return DropdownMenuItem(
                value: difficulty,
                child: Text(difficulty.label),
              );
            }).toList(),
          ),
        ),
        
        // タグ
        ListTile(
          leading: const Icon(Icons.tag),
          title: const Text('タグ'),
          subtitle: _tags.isNotEmpty
              ? Wrap(
                  spacing: 4,
                  children: _tags.map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  )).toList(),
                )
              : const Text('タグなし'),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addTag(context),
          ),
        ),
        
        // サブタスク
        const SizedBox(height: 16),
        _buildSubTasksSection(),
      ],
    );
  }

  Widget _buildSubTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist, size: 20),
            const SizedBox(width: 8),
            const Text(
              'サブタスク',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addSubTask,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('追加'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_subTasks.isNotEmpty) ...[
          ..._subTasks.asMap().entries.map((entry) {
            final index = entry.key;
            final subTask = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: IconButton(
                  icon: Icon(
                    subTask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: subTask.isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _toggleSubTaskCompletion(index),
                ),
                title: Text(
                  subTask.title,
                  style: TextStyle(
                    decoration: subTask.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeSubTask(index),
                ),
                dense: true,
              ),
            );
          }).toList(),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'サブタスクがありません',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }

  void _addSubTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サブタスクを追加'),
        content: TextField(
          controller: _subTaskController,
          decoration: const InputDecoration(
            labelText: 'サブタスク名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _subTaskController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = _subTaskController.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  _subTasks.add(SubTask(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                  ));
                });
                _subTaskController.clear();
              }
              Navigator.of(context).pop();
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }

  void _toggleSubTaskCompletion(int index) {
    setState(() {
      final subTask = _subTasks[index];
      _subTasks[index] = subTask.isCompleted 
          ? subTask.markAsIncomplete()
          : subTask.markAsCompleted();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addTag(BuildContext context) {
    final TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タグを追加'),
        content: TextField(
          controller: tagController,
          decoration: const InputDecoration(
            labelText: 'タグ名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final tag = tagController.text.trim();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() {
                  _tags.add(tag);
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _updateTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      scheduledDate: _selectedDate,
      scheduledTimeStart: _hasTime
          ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            )
          : null,
      estimatedDuration: _estimatedDuration,
      priority: _selectedPriority,
      difficulty: _selectedDifficulty,
      tags: _tags,
      subTasks: _subTasks,
    );

    ref.read(taskProvider.notifier).updateTask(updatedTask);
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('タスクを更新しました')),
    );
  }
} 