import 'package:flutter/material.dart';
import '../../domain/entities/goal.dart';

class GoalFilterBar extends StatelessWidget {
  final GoalCategory? selectedCategory;
  final GoalPriority? selectedPriority;
  final ValueChanged<GoalCategory?> onCategoryChanged;
  final ValueChanged<GoalPriority?> onPriorityChanged;

  const GoalFilterBar({
    super.key,
    required this.selectedCategory,
    required this.selectedPriority,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // カテゴリフィルター＋ラベル
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('カテゴリ', style: TextStyle(fontSize: 12, color: Colors.grey)),
              DropdownButton<GoalCategory?>(
                value: selectedCategory,
                hint: const Text('カテゴリ'),
                items: [
                  const DropdownMenuItem<GoalCategory?>(
                    value: null,
                    child: Text('すべて'),
                  ),
                  ...GoalCategory.values.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  )),
                ],
                onChanged: onCategoryChanged,
              ),
            ],
          ),
          const SizedBox(width: 24),
          // 優先度フィルター＋ラベル
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('優先度', style: TextStyle(fontSize: 12, color: Colors.grey)),
              DropdownButton<GoalPriority?>(
                value: selectedPriority,
                hint: const Text('優先度'),
                items: [
                  const DropdownMenuItem<GoalPriority?>(
                    value: null,
                    child: Text('すべて'),
                  ),
                  ...GoalPriority.values.map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority.label),
                  )),
                ],
                onChanged: onPriorityChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
} 