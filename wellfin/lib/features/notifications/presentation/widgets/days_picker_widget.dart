import 'package:flutter/material.dart';

/// 📅 曜日選択ウィジェット
/// 美しいUIで曜日を複数選択するためのダイアログ
class DaysPickerWidget extends StatefulWidget {
  final String title;
  final List<int> currentDays;
  final Function(List<int>) onDaysSelected;
  final bool allowEmpty;

  const DaysPickerWidget({
    Key? key,
    required this.title,
    required this.currentDays,
    required this.onDaysSelected,
    this.allowEmpty = false,
  }) : super(key: key);

  @override
  State<DaysPickerWidget> createState() => _DaysPickerWidgetState();
}

class _DaysPickerWidgetState extends State<DaysPickerWidget> {
  late Set<int> selectedDays;

  @override
  void initState() {
    super.initState();
    selectedDays = Set<int>.from(widget.currentDays);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.date_range, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 選択された曜日の表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_available, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatSelectedDays(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 曜日選択グリッド
          _buildDaysGrid(),
          
          const SizedBox(height: 16),
          
          // クイック選択ボタン
          const Text(
            'クイック選択:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildQuickSelectChip('平日', [1, 2, 3, 4, 5]),
              _buildQuickSelectChip('週末', [6, 7]),
              _buildQuickSelectChip('毎日', [1, 2, 3, 4, 5, 6, 7]),
              _buildQuickSelectChip('なし', []),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _canSave() ? _saveDays : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildDaysGrid() {
    final days = [
      {'id': 1, 'short': '月', 'full': '月曜日', 'color': Colors.red},
      {'id': 2, 'short': '火', 'full': '火曜日', 'color': Colors.orange},
      {'id': 3, 'short': '水', 'full': '水曜日', 'color': Colors.amber},
      {'id': 4, 'short': '木', 'full': '木曜日', 'color': Colors.green},
      {'id': 5, 'short': '金', 'full': '金曜日', 'color': Colors.blue},
      {'id': 6, 'short': '土', 'full': '土曜日', 'color': Colors.indigo},
      {'id': 7, 'short': '日', 'full': '日曜日', 'color': Colors.purple},
    ];

    return Column(
      children: [
        // 曜日ヘッダー
        Row(
          children: days.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day['short'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 8),
        
        // 曜日選択ボタン
        Row(
          children: days.map((day) {
            final dayId = day['id'] as int;
            final isSelected = selectedDays.contains(dayId);
            final color = day['color'] as Color;
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => _toggleDay(dayId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? Colors.white : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day['short'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 8),
        
        // 選択状況の説明
        Text(
          '${selectedDays.length}個の曜日が選択されています',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip(String label, List<int> days) {
    final isCurrentSelection = _isCurrentSelection(days);
    
    return ActionChip(
      label: Text(label),
      onPressed: () => _setSelectedDays(days),
      backgroundColor: isCurrentSelection 
          ? Colors.blue.withOpacity(0.2) 
          : null,
      side: isCurrentSelection 
          ? const BorderSide(color: Colors.blue, width: 2)
          : null,
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  void _setSelectedDays(List<int> days) {
    setState(() {
      selectedDays = Set<int>.from(days);
    });
  }

  bool _isCurrentSelection(List<int> days) {
    return selectedDays.length == days.length &&
           selectedDays.every((day) => days.contains(day));
  }

  bool _canSave() {
    return widget.allowEmpty || selectedDays.isNotEmpty;
  }

  void _saveDays() {
    final sortedDays = selectedDays.toList()..sort();
    widget.onDaysSelected(sortedDays);
    Navigator.of(context).pop();
  }

  String _formatSelectedDays() {
    if (selectedDays.isEmpty) {
      return 'なし';
    }

    if (selectedDays.length == 7) {
      return '毎日';
    }

    if (_isCurrentSelection([1, 2, 3, 4, 5])) {
      return '平日のみ';
    }

    if (_isCurrentSelection([6, 7])) {
      return '週末のみ';
    }

    final dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    final sortedDays = selectedDays.toList()..sort();
    return sortedDays.map((day) => dayNames[day - 1]).join(', ');
  }
}

/// 📅 週間曜日選択ウィジェット
/// よりコンパクトな曜日選択用のウィジェット
class CompactDaysPickerWidget extends StatefulWidget {
  final List<int> currentDays;
  final Function(List<int>) onDaysChanged;
  final bool enabled;

  const CompactDaysPickerWidget({
    Key? key,
    required this.currentDays,
    required this.onDaysChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CompactDaysPickerWidget> createState() => _CompactDaysPickerWidgetState();
}

class _CompactDaysPickerWidgetState extends State<CompactDaysPickerWidget> {
  late Set<int> selectedDays;

  @override
  void initState() {
    super.initState();
    selectedDays = Set<int>.from(widget.currentDays);
  }

  @override
  void didUpdateWidget(CompactDaysPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDays != widget.currentDays) {
      selectedDays = Set<int>.from(widget.currentDays);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      {'id': 1, 'short': '月'},
      {'id': 2, 'short': '火'},
      {'id': 3, 'short': '水'},
      {'id': 4, 'short': '木'},
      {'id': 5, 'short': '金'},
      {'id': 6, 'short': '土'},
      {'id': 7, 'short': '日'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((day) {
        final dayId = day['id'] as int;
        final isSelected = selectedDays.contains(dayId);
        final isWeekend = dayId == 6 || dayId == 7;
        
        return GestureDetector(
          onTap: widget.enabled ? () => _toggleDay(dayId) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isWeekend ? Colors.red : Colors.blue)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? (isWeekend ? Colors.red : Colors.blue)
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                day['short'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                      ? Colors.white 
                      : (widget.enabled ? Colors.grey[700] : Colors.grey[400]),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
      
      final sortedDays = selectedDays.toList()..sort();
      widget.onDaysChanged(sortedDays);
    });
  }
}

/// 📅 曜日表示ウィジェット
/// 選択された曜日を読み取り専用で表示するウィジェット
class DaysDisplayWidget extends StatelessWidget {
  final List<int> days;
  final bool showFullNames;
  final Color? activeColor;

  const DaysDisplayWidget({
    Key? key,
    required this.days,
    this.showFullNames = false,
    this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Text(
        'なし',
        style: TextStyle(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (days.length == 7) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (activeColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '毎日',
          style: TextStyle(
            color: activeColor ?? Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final dayNames = showFullNames 
        ? ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日']
        : ['月', '火', '水', '木', '金', '土', '日'];

    if (_isWeekdays(days)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (activeColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '平日のみ',
          style: TextStyle(
            color: activeColor ?? Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_isWeekends(days)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '週末のみ',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      children: days.map((day) {
        final isWeekend = day == 6 || day == 7;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isWeekend 
                ? Colors.red.withOpacity(0.1)
                : (activeColor ?? Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            dayNames[day - 1],
            style: TextStyle(
              fontSize: 12,
              color: isWeekend 
                  ? Colors.red 
                  : (activeColor ?? Colors.blue),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isWeekdays(List<int> days) {
    return days.length == 5 && 
           days.every((day) => day >= 1 && day <= 5);
  }

  bool _isWeekends(List<int> days) {
    return days.length == 2 && 
           days.contains(6) && 
           days.contains(7);
  }
} 