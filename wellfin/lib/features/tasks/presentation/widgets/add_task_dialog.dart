import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';

/// タスク追加ダイアログ
class AddTaskDialog extends ConsumerStatefulWidget {
  const AddTaskDialog({super.key});

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.medium;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _hasTime = false;
  int _estimatedDuration = 60;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新しいタスク'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 説明
              TextFormField(
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
                title: const Text('日付'),
                subtitle: Text(
                  '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                ),
                onTap: () => _selectDate(context),
              ),
              
              // 時間
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: const Text('作成'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _hasTime ? _selectedTime.hour : 0,
        _hasTime ? _selectedTime.minute : 0,
      );

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        createdAt: DateTime.now(),
        scheduledDate: scheduledDateTime,
        scheduledTimeStart: _hasTime ? scheduledDateTime : null,
        scheduledTimeEnd: _hasTime 
            ? scheduledDateTime.add(Duration(minutes: _estimatedDuration))
            : null,
        estimatedDuration: _estimatedDuration,
        priority: _selectedPriority,
        difficulty: _selectedDifficulty,
      );

      ref.read(taskProvider.notifier).createTask(task);
      Navigator.of(context).pop();
    }
  }
} 