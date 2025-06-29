import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit.dart';
import '../providers/habit_provider.dart';

/// 習慣追加ダイアログ
class AddHabitDialog extends ConsumerStatefulWidget {
  const AddHabitDialog({super.key});

  @override
  ConsumerState<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends ConsumerState<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  HabitCategory _selectedCategory = HabitCategory.personal;
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  List<HabitDay> _selectedDays = [];

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
                      Icons.add_circle,
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
                          '新しい習慣を作成',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          '継続できる習慣を作りましょう',
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
                    onPressed: _createHabit,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('作成'),
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
            hintText: '例: 毎日運動する',
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
            hintText: '習慣の詳細を入力',
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
            labelText: 'カテゴリ',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.category),
          ),
          items: HabitCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category.label),
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
            labelText: '頻度',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.repeat),
          ),
          items: HabitFrequency.values.map((frequency) {
            return DropdownMenuItem(
              value: frequency,
              child: Text(
                '${frequency.label} - ${frequency.description}',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
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
        
        // 週次の場合の曜日選択
        if (_selectedFrequency == HabitFrequency.weekly) ...[
          const SizedBox(height: 16),
          const Text(
            '対象曜日',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
        ],
      ],
    );
  }

  void _createHabit() {
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
    
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      frequency: _selectedFrequency,
      targetDays: _selectedDays,
      status: HabitStatus.active,
      createdAt: DateTime.now(),
      startDate: DateTime.now(),
      currentStreak: 0,
      longestStreak: 0,
      totalCompletions: 0,
      completions: const [],
    );
    
    ref.read(habitProvider.notifier).createHabit(habit);
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('習慣を作成しました'),
        backgroundColor: Colors.blue,
      ),
    );
  }
} 