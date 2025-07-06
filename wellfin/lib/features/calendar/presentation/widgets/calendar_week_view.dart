import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/calendar_event.dart';

class CalendarWeekView extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Function(DateTime) onDateSelected;
  final Function(CalendarEvent) onEventTap;
  final Function(DateTime?) onSlotTap;

  const CalendarWeekView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onDateSelected,
    required this.onEventTap,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final startOfWeek = _getStartOfWeek(selectedDate);
    final hours = List.generate(14, (index) => index + 6); // 6:00 - 19:00

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // 曜日ヘッダー
          _buildDaysHeader(startOfWeek),
          
          // 時間スロットとイベント
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                children: [
                  // 時間ラベル
                  _buildTimeLabels(hours),
                  
                  // 日付列
                  Expanded(
                    child: Row(
                      children: List.generate(7, (dayIndex) {
                        final date = startOfWeek.add(Duration(days: dayIndex));
                        return Expanded(
                          child: _buildDayColumn(date, hours),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  Widget _buildDaysHeader(DateTime startOfWeek) {
    const dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50), // 時間ラベル分のスペース
          
          ...List.generate(7, (index) {
            final date = startOfWeek.add(Duration(days: index));
            final isSelected = _isSameDay(date, selectedDate);
            final isToday = _isSameDay(date, DateTime.now());
            
            return Expanded(
              child: GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade100 : null,
                    border: Border(
                      left: index > 0 ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNames[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isToday ? Colors.blue : (isSelected ? Colors.blue.shade200 : null),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : (isSelected ? Colors.blue.shade800 : Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeLabels(List<int> hours) {
    return Container(
      width: 50,
      child: Column(
        children: hours.map((hour) {
          return Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayColumn(DateTime date, List<int> hours) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Stack(
        children: [
          // 時間グリッド
          Column(
            children: hours.map((hour) {
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              );
            }).toList(),
          ),
          
          // イベント
          ..._buildEventWidgets(date),
        ],
      ),
    );
  }



  List<Widget> _buildEventWidgets(DateTime date) {
    final dayEvents = events.where((event) => _isSameDay(event.startTime, date)).toList();
    
    return dayEvents.map((event) {
      final startHour = event.startTime.hour;
      final startMinute = event.startTime.minute;
      final durationMinutes = event.duration.inMinutes;
      
      final top = (startHour - 6) * 60.0 + (startMinute / 60.0) * 60.0;
      final height = (durationMinutes / 60.0) * 60.0;
      
      return Positioned(
        top: top,
        left: 2,
        right: 2,
        height: height.clamp(20.0, 300.0), // 最小20px、最大300px
        child: GestureDetector(
          onTap: () => onEventTap(event),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (height > 30) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
} 