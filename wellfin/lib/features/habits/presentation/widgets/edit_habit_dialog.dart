import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit.dart';
import '../providers/habit_provider.dart';

/// 習慣編集ダイアログ
class EditHabitDialog extends ConsumerStatefulWidget {
  final Habit habit;
  
  const EditHabitDialog({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends ConsumerState<EditHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  late HabitCategory _selectedCategory;
  late HabitFrequency _selectedFrequency;
  late List<HabitDay> _selectedDays;
  late HabitPriority _selectedPriority;
  late HabitStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit.title);
    _descriptionController = TextEditingController(text: widget.habit.description);
    _selectedCategory = widget.habit.category;
    _selectedFrequency = widget.habit.frequency;
    _selectedDays = List.from(widget.habit.targetDays);
    _selectedPriority = widget.habit.priority;
    _selectedStatus = widget.habit.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
                      Icons.edit,
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
                          '習慣を編集',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          'より良い習慣に改善しましょう',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
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
                  key: _formKey,
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
                    onPressed: _updateHabit,
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
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: '習慣名 *',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '習慣名を入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // 説明
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: '説明',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        // カテゴリ選択
        DropdownButtonFormField<HabitCategory>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'カテゴリ *',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.category),
          ),
          items: HabitCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(category.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // 頻度選択
        DropdownButtonFormField<HabitFrequency>(
          value: _selectedFrequency,
          decoration: InputDecoration(
            labelText: '頻度 *',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.repeat),
          ),
          items: HabitFrequency.values.map((frequency) {
            return DropdownMenuItem(
              value: frequency,
              child: Text('${frequency.label} - ${frequency.description}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFrequency = value;
                if (value != HabitFrequency.weekly) {
                  _selectedDays.clear();
                }
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // 週次の場合の曜日選択
        if (_selectedFrequency == HabitFrequency.weekly) ...[
          Text(
            '対象曜日 *',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: HabitDay.values.map((day) {
              final isSelected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(day.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[600],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // 優先度選択
        DropdownButtonFormField<HabitPriority>(
          value: _selectedPriority,
          decoration: InputDecoration(
            labelText: '優先度 *',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.priority_high),
          ),
          items: HabitPriority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: _getPriorityColor(priority),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(priority.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPriority = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        
        // ステータス選択
        DropdownButtonFormField<HabitStatus>(
          value: _selectedStatus,
          decoration: InputDecoration(
            labelText: 'ステータス *',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.play_arrow),
          ),
          items: HabitStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(status.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStatus = value;
              });
            }
          },
        ),
      ],
    );
  }

  void _updateHabit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedFrequency == HabitFrequency.weekly && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('対象曜日を選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final updatedHabit = widget.habit.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      frequency: _selectedFrequency,
      targetDays: _selectedDays,
      priority: _selectedPriority,
      status: _selectedStatus,
    );
    
    ref.read(habitProvider.notifier).updateHabit(updatedHabit);
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('習慣を更新しました'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  // Helper methods for icons and colors
  IconData _getCategoryIcon(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Icons.health_and_safety;
      case HabitCategory.fitness:
        return Icons.fitness_center;
      case HabitCategory.learning:
        return Icons.school;
      case HabitCategory.work:
        return Icons.work;
      case HabitCategory.personal:
        return Icons.person;
      case HabitCategory.social:
        return Icons.people;
      case HabitCategory.financial:
        return Icons.account_balance_wallet;
      case HabitCategory.creative:
        return Icons.palette;
      case HabitCategory.mindfulness:
        return Icons.self_improvement;
      case HabitCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Colors.green;
      case HabitCategory.fitness:
        return Colors.orange;
      case HabitCategory.learning:
        return Colors.blue;
      case HabitCategory.work:
        return Colors.purple;
      case HabitCategory.personal:
        return Colors.indigo;
      case HabitCategory.social:
        return Colors.pink;
      case HabitCategory.financial:
        return Colors.amber;
      case HabitCategory.creative:
        return Colors.deepPurple;
      case HabitCategory.mindfulness:
        return Colors.teal;
      case HabitCategory.other:
        return Colors.grey;
    }
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
        return Icons.check_circle;
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
}
