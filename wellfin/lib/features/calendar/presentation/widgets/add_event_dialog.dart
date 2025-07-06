import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/calendar_event.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime initialDateTime;
  final Function(CalendarEvent) onEventCreated;

  const AddEventDialog({
    super.key,
    required this.initialDateTime,
    required this.onEventCreated,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  bool _isAllDay = false;
  bool _isLoading = false;
  String? _selectedColorId = '7'; // デフォルトはピーコック（青色）

  @override
  void initState() {
    super.initState();
    _startDateTime = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
      widget.initialDateTime.hour,
      (widget.initialDateTime.minute ~/ 15) * 15, // 15分単位に丸める
    );
    _endDateTime = _startDateTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新しいイベント'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // タイトル入力
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'イベント名 *',
                    hintText: '会議、タスクなど',
                    prefixIcon: Icon(Icons.event),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'イベント名を入力してください';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                
                const SizedBox(height: 16),
                
                // 終日チェックボックス
                CheckboxListTile(
                  title: const Text('終日'),
                  value: _isAllDay,
                  onChanged: (value) {
                    setState(() {
                      _isAllDay = value ?? false;
                      if (_isAllDay) {
                        _startDateTime = DateTime(
                          _startDateTime.year,
                          _startDateTime.month,
                          _startDateTime.day,
                        );
                        _endDateTime = _startDateTime.add(const Duration(days: 1));
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 16),
                
                if (!_isAllDay) ...[
                  // 開始時間
                  _buildDateTimeField(
                    label: '開始時間',
                    dateTime: _startDateTime,
                    onChanged: (newDateTime) {
                      setState(() {
                        _startDateTime = newDateTime;
                        // 終了時間が開始時間より前の場合、1時間後に設定
                        if (_endDateTime.isBefore(_startDateTime)) {
                          _endDateTime = _startDateTime.add(const Duration(hours: 1));
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 終了時間
                  _buildDateTimeField(
                    label: '終了時間',
                    dateTime: _endDateTime,
                    onChanged: (newDateTime) {
                      setState(() {
                        _endDateTime = newDateTime;
                      });
                    },
                    validator: (value) {
                      if (_endDateTime.isBefore(_startDateTime)) {
                        return '終了時間は開始時間より後にしてください';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  // 日付選択（終日の場合）
                  _buildDateField(
                    label: '日付',
                    date: _startDateTime,
                    onChanged: (newDate) {
                      setState(() {
                        _startDateTime = newDate;
                        _endDateTime = newDate.add(const Duration(days: 1));
                      });
                    },
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // 説明入力
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明（任意）',
                    hintText: 'イベントの詳細や備考',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                
                const SizedBox(height: 16),
                
                // 色選択
                _buildColorPicker(),
                
                const SizedBox(height: 8),
                
                // クイック設定ボタン
                if (!_isAllDay) _buildQuickTimeButtons(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _createEvent,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('作成'),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime dateTime,
    required Function(DateTime) onChanged,
    String? Function(String?)? validator,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => _selectDate(dateTime, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat('M/d(E)', 'ja').format(dateTime)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectTime(dateTime, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat('HH:mm').format(dateTime)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required Function(DateTime) onChanged,
  }) {
    return GestureDetector(
      onTap: () => _selectDate(date, onChanged),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Text(DateFormat('yyyy年M月d日(E)', 'ja').format(date)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTimeButtons() {
    final quickTimes = [
      {'label': '15分', 'duration': const Duration(minutes: 15)},
      {'label': '30分', 'duration': const Duration(minutes: 30)},
      {'label': '1時間', 'duration': const Duration(hours: 1)},
      {'label': '2時間', 'duration': const Duration(hours: 2)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイック設定',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: quickTimes.map((time) {
            return OutlinedButton(
              onPressed: () {
                setState(() {
                  _endDateTime = _startDateTime.add(time['duration'] as Duration);
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                time['label'] as String,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectDate(DateTime currentDateTime, Function(DateTime) onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        currentDateTime.hour,
        currentDateTime.minute,
      );
      onChanged(newDateTime);
    }
  }

  Future<void> _selectTime(DateTime currentDateTime, Function(DateTime) onChanged) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDateTime),
    );

    if (time != null) {
      final newDateTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        time.hour,
        time.minute,
      );
      onChanged(newDateTime);
    }
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'イベントの色',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CalendarColors.allColors.map((colorEntry) {
              final colorId = colorEntry.key;
              final colorData = colorEntry.value;
              final color = colorData['color'] as Color;
              final name = colorData['name'] as String;
              final isSelected = _selectedColorId == colorId;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorId = colorId;
                  });
                },
                child: Tooltip(
                  message: name,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.grey.shade300,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '選択中: ${CalendarColors.getName(_selectedColorId)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final event = CalendarEvent(
        id: '', // Google Calendarで自動生成される
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startTime: _startDateTime,
        endTime: _endDateTime,
        isAllDay: _isAllDay,
        colorId: _selectedColorId,
      );

      widget.onEventCreated(event);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 