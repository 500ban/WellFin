import 'package:flutter/material.dart';

/// ⏰ 時間選択ウィジェット
/// 美しいUIで時間を選択するためのダイアログ
class TimePickerWidget extends StatefulWidget {
  final String title;
  final String currentTime;
  final Function(String) onTimeSelected;
  final bool use24HourFormat;

  const TimePickerWidget({
    Key? key,
    required this.title,
    required this.currentTime,
    required this.onTimeSelected,
    this.use24HourFormat = true,
  }) : super(key: key);

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late TimeOfDay selectedTime;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _parseCurrentTime();
    _controller = TextEditingController(text: widget.currentTime);
  }

  void _parseCurrentTime() {
    final parts = widget.currentTime.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      selectedTime = TimeOfDay(hour: hour, minute: minute);
    } else {
      selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.blue),
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
          // 現在選択されている時間の表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  _formatTime(selectedTime),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 時間選択ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showTimePicker,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('時間を選択'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 手動入力フィールド
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: '時間を入力 (HH:MM)',
              hintText: '例: 07:30',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.keyboard),
            ),
            onChanged: (value) {
              if (_isValidTimeFormat(value)) {
                final parts = value.split(':');
                final hour = int.parse(parts[0]);
                final minute = int.parse(parts[1]);
                setState(() {
                  selectedTime = TimeOfDay(hour: hour, minute: minute);
                });
              }
            },
          ),
          
          const SizedBox(height: 8),
          
          // クイック選択ボタン
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _getQuickTimeOptions().map((time) {
              return ActionChip(
                label: Text(time),
                onPressed: () => _selectQuickTime(time),
                backgroundColor: time == _formatTime(selectedTime)
                    ? Colors.blue.withOpacity(0.2)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _saveTime,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: widget.use24HourFormat,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        _controller.text = _formatTime(picked);
      });
    }
  }

  void _selectQuickTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    setState(() {
      selectedTime = TimeOfDay(hour: hour, minute: minute);
      _controller.text = timeString;
    });
  }

  void _saveTime() {
    final timeString = _formatTime(selectedTime);
    widget.onTimeSelected(timeString);
    Navigator.of(context).pop();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  List<String> _getQuickTimeOptions() {
    return [
      '06:00', '06:30', '07:00', '07:30', '08:00', '08:30',
      '09:00', '12:00', '18:00', '19:00', '20:00', '21:00',
      '22:00', '23:00',
    ];
  }
}

/// ⏰ 時間範囲選択ウィジェット
/// 開始時間と終了時間を選択するためのダイアログ
class TimeRangePickerWidget extends StatefulWidget {
  final String title;
  final String startTime;
  final String endTime;
  final Function(String, String) onTimeRangeSelected;

  const TimeRangePickerWidget({
    Key? key,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.onTimeRangeSelected,
  }) : super(key: key);

  @override
  State<TimeRangePickerWidget> createState() => _TimeRangePickerWidgetState();
}

class _TimeRangePickerWidgetState extends State<TimeRangePickerWidget> {
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late TextEditingController _startController;
  late TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _parseCurrentTimes();
    _startController = TextEditingController(text: widget.startTime);
    _endController = TextEditingController(text: widget.endTime);
  }

  void _parseCurrentTimes() {
    final startParts = widget.startTime.split(':');
    final endParts = widget.endTime.split(':');
    
    if (startParts.length == 2) {
      final hour = int.tryParse(startParts[0]) ?? 0;
      final minute = int.tryParse(startParts[1]) ?? 0;
      startTime = TimeOfDay(hour: hour, minute: minute);
    } else {
      startTime = const TimeOfDay(hour: 9, minute: 0);
    }
    
    if (endParts.length == 2) {
      final hour = int.tryParse(endParts[0]) ?? 0;
      final minute = int.tryParse(endParts[1]) ?? 0;
      endTime = TimeOfDay(hour: hour, minute: minute);
    } else {
      endTime = const TimeOfDay(hour: 18, minute: 0);
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.blue),
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
          // 時間範囲の表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 開始時間設定
          Row(
            children: [
              const Icon(Icons.play_arrow, color: Colors.green),
              const SizedBox(width: 8),
              const Text('開始時間:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => _showTimePickerFor(true),
                child: Text(
                  _formatTime(startTime),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 終了時間設定
          Row(
            children: [
              const Icon(Icons.stop, color: Colors.red),
              const SizedBox(width: 8),
              const Text('終了時間:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => _showTimePickerFor(false),
                child: Text(
                  _formatTime(endTime),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // プリセット選択
          const Text('プリセット:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _getPresetOptions().map((preset) {
              return ActionChip(
                label: Text(preset['label']!),
                onPressed: () => _selectPreset(preset),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _saveTimeRange,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _showTimePickerFor(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
          _startController.text = _formatTime(picked);
        } else {
          endTime = picked;
          _endController.text = _formatTime(picked);
        }
      });
    }
  }

  void _selectPreset(Map<String, String> preset) {
    final startParts = preset['start']!.split(':');
    final endParts = preset['end']!.split(':');
    
    setState(() {
      startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
      _startController.text = preset['start']!;
      _endController.text = preset['end']!;
    });
  }

  void _saveTimeRange() {
    final startString = _formatTime(startTime);
    final endString = _formatTime(endTime);
    widget.onTimeRangeSelected(startString, endString);
    Navigator.of(context).pop();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, String>> _getPresetOptions() {
    return [
      {'label': '標準勤務', 'start': '09:00', 'end': '18:00'},
      {'label': '早朝勤務', 'start': '07:00', 'end': '16:00'},
      {'label': '夜勤務', 'start': '22:00', 'end': '06:00'},
      {'label': 'フレックス', 'start': '10:00', 'end': '19:00'},
    ];
  }
} 