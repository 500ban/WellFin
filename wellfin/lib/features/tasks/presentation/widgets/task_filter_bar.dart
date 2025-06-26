import 'package:flutter/material.dart';

/// タスクフィルターバーウィジェット
class TaskFilterBar extends StatelessWidget {
  final TaskFilter currentFilter;
  final ValueChanged<TaskFilter> onFilterChanged;

  const TaskFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: TaskFilter.values.length,
        itemBuilder: (context, index) {
          final filter = TaskFilter.values[index];
          final isSelected = filter == currentFilter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// タスクフィルター
enum TaskFilter {
  all('すべて'),
  today('今日'),
  completed('完了'),
  pending('保留中'),
  overdue('期限切れ');

  const TaskFilter(this.label);
  final String label;
} 