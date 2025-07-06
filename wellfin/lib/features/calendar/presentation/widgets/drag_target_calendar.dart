import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/calendar_event.dart';

/// ドロップターゲット機能を持つカレンダーウィジェット
class DragTargetCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Function(CalendarEvent, DateTime) onEventDropped;
  final Function(DateTime) onTimeSlotTapped;
  final double hourHeight;

  const DragTargetCalendar({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onEventDropped,
    required this.onTimeSlotTapped,
    this.hourHeight = 60.0,
  });

  @override
  State<DragTargetCalendar> createState() => _DragTargetCalendarState();
}

class _DragTargetCalendarState extends State<DragTargetCalendar> {
  DateTime? _dragOverTime;
  CalendarEvent? _draggingEvent;
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _isDragOver ? Colors.blue.withOpacity(0.5) : Colors.grey.shade300,
          width: _isDragOver ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _isDragOver ? Colors.blue.withOpacity(0.05) : null,
      ),
      child: Stack(
        children: [
          // 時間グリッド背景
          _buildTimeGrid(),
          
          // ドロップターゲット領域
          _buildDropTargets(),
          
          // 既存イベント表示
          ..._buildEventWidgets(),
          
          // ドラッグオーバー時のプレビュー
          if (_dragOverTime != null && _draggingEvent != null)
            _buildDragOverPreview(),
        ],
      ),
    );
  }

  Widget _buildTimeGrid() {
    final hours = List.generate(16, (index) => index + 6); // 6:00 - 21:00
    
    return Column(
      children: hours.map((hour) {
        return Container(
          height: widget.hourHeight,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 時間ラベル
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              // メイン領域
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropTargets() {
    final hours = List.generate(16, (index) => index + 6);
    
    return Column(
      children: hours.map((hour) {
        return _buildHourDropTarget(hour);
      }).toList(),
    );
  }

  Widget _buildHourDropTarget(int hour) {
    return Container(
      height: widget.hourHeight,
      child: Row(
        children: [
          const SizedBox(width: 50), // 時間ラベル分のスペース
          Expanded(
            child: DragTarget<CalendarEvent>(
              onWillAccept: (data) {
                setState(() {
                  _draggingEvent = data;
                  _dragOverTime = DateTime(
                    widget.selectedDate.year,
                    widget.selectedDate.month,
                    widget.selectedDate.day,
                    hour,
                    0,
                  );
                  _isDragOver = true;
                });
                return true;
              },
              onLeave: (data) {
                setState(() {
                  _dragOverTime = null;
                  _draggingEvent = null;
                  _isDragOver = false;
                });
              },
              onAccept: (CalendarEvent event) {
                final dropTime = DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  widget.selectedDate.day,
                  hour,
                  0,
                );
                
                widget.onEventDropped(event, dropTime);
                
                setState(() {
                  _dragOverTime = null;
                  _draggingEvent = null;
                  _isDragOver = false;
                });
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                
                return GestureDetector(
                  onTap: () {
                    final tappedTime = DateTime(
                      widget.selectedDate.year,
                      widget.selectedDate.month,
                      widget.selectedDate.day,
                      hour,
                      0,
                    );
                    widget.onTimeSlotTapped(tappedTime);
                  },
                  child: Container(
                    width: double.infinity,
                    height: widget.hourHeight,
                    decoration: BoxDecoration(
                      color: isHovering 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.transparent,
                      border: isHovering 
                          ? Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: isHovering
                        ? Center(
                            child: Icon(
                              Icons.add_circle_outline,
                              color: Colors.blue.withOpacity(0.6),
                              size: 24,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventWidgets() {
    final dayEvents = widget.events.where((event) {
      final eventDate = DateTime(
        event.startTime.year, 
        event.startTime.month, 
        event.startTime.day
      );
      final targetDate = DateTime(
        widget.selectedDate.year, 
        widget.selectedDate.month, 
        widget.selectedDate.day
      );
      return eventDate == targetDate;
    }).toList();

    return dayEvents.map((event) {
      final startHour = event.startTime.hour;
      final startMinute = event.startTime.minute;
      final durationMinutes = event.duration.inMinutes;
      
      // 6:00-21:00の範囲外のイベントは調整
      final adjustedStartHour = startHour < 6 ? 6 : (startHour >= 22 ? 21 : startHour);
      
      final topPosition = ((adjustedStartHour - 6) * widget.hourHeight) + 
                         (startMinute / 60.0 * widget.hourHeight);
      final height = (durationMinutes / 60.0 * widget.hourHeight).clamp(20.0, 300.0);
      
      return Positioned(
        top: topPosition,
        left: 54, // 時間ラベル分のオフセット
        right: 8,
        child: Container(
          height: height,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.8),
                Colors.blue.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.blue.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (height > 35) ...[
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDragOverPreview() {
    if (_dragOverTime == null || _draggingEvent == null) {
      return const SizedBox.shrink();
    }

    final hour = _dragOverTime!.hour;
    final adjustedHour = hour < 6 ? 6 : (hour >= 22 ? 21 : hour);
    final topPosition = (adjustedHour - 6) * widget.hourHeight;
    final eventDuration = _draggingEvent!.duration.inMinutes;
    final height = (eventDuration / 60.0 * widget.hourHeight).clamp(30.0, 120.0);

    return Positioned(
      top: topPosition,
      left: 54,
      right: 8,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.green.withOpacity(0.6),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('HH:mm').format(_dragOverTime!)}に移動',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _draggingEvent!.title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 時間スロット選択用のDragTargetウィジェット
class TimeSlotDragTarget extends StatefulWidget {
  final DateTime targetTime;
  final Function(CalendarEvent, DateTime) onEventDropped;
  final Widget child;

  const TimeSlotDragTarget({
    super.key,
    required this.targetTime,
    required this.onEventDropped,
    required this.child,
  });

  @override
  State<TimeSlotDragTarget> createState() => _TimeSlotDragTargetState();
}

class _TimeSlotDragTargetState extends State<TimeSlotDragTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<CalendarEvent>(
      onWillAccept: (data) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (data) {
        setState(() => _isHovering = false);
      },
      onAccept: (CalendarEvent event) {
        widget.onEventDropped(event, widget.targetTime);
        setState(() => _isHovering = false);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: _isHovering 
                ? Colors.blue.withOpacity(0.1)
                : Colors.transparent,
            border: _isHovering 
                ? Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.child,
        );
      },
    );
  }
} 