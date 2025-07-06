import 'package:flutter/material.dart';
import '../../domain/entities/calendar_event.dart';
import 'draggable_event_widget.dart';

class CalendarTimelineView extends StatefulWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Function(CalendarEvent) onEventTap;
  final Function(DateTime) onSlotTap;
  final Function(CalendarEvent, DateTime)? onEventDropped;

  const CalendarTimelineView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onEventTap,
    required this.onSlotTap,
    this.onEventDropped,
  });

  @override
  State<CalendarTimelineView> createState() => _CalendarTimelineViewState();
}

class _CalendarTimelineViewState extends State<CalendarTimelineView> {
  late ScrollController _timeAxisController;
  late ScrollController _timelineController;
  bool _isScrollingSyncing = false;

  @override
  void initState() {
    super.initState();
    _timeAxisController = ScrollController();
    _timelineController = ScrollController();
    
    // スクロール同期の設定
    _setupScrollSync();
    
    // 現在時刻にスクロール位置を設定（今日の場合）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _timeAxisController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  void _setupScrollSync() {
    _timeAxisController.addListener(() {
      if (!_isScrollingSyncing && _timelineController.hasClients) {
        _isScrollingSyncing = true;
        _timelineController.jumpTo(_timeAxisController.offset);
        _isScrollingSyncing = false;
      }
    });

    _timelineController.addListener(() {
      if (!_isScrollingSyncing && _timeAxisController.hasClients) {
        _isScrollingSyncing = true;
        _timeAxisController.jumpTo(_timelineController.offset);
        _isScrollingSyncing = false;
      }
    });
  }

  void _scrollToCurrentTime() {
    if (!_isToday(widget.selectedDate)) return;
    
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // 6:00-22:00の範囲内の場合のみスクロール
    if (currentHour >= 6 && currentHour < 22) {
      // 現在時刻の少し前にスクロール（見やすさのため）
      final targetHour = (currentHour - 6).clamp(0, 16);
      final targetOffset = (targetHour * 60.0) - 120; // 2時間前を表示
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_timelineController.hasClients) {
          final maxExtent = _timelineController.position.maxScrollExtent;
                     final clampedOffset = targetOffset.clamp(0, maxExtent).toDouble();
           
           _timelineController.animateTo(
             clampedOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _getEventsForDate(widget.selectedDate, widget.events);
    
    return Container(
      color: Colors.grey.shade50,
      child: Row(
        children: [
          // 時間軸（スクロール位置に応じて表示を調整）
          _buildTimeAxis(),
          
          // タイムライン本体
          Expanded(
            child: _buildTimeline(context, dayEvents),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAxis() {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        controller: _timeAxisController,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: 17 * 60 + 20, // メインタイムラインと同じ高さ
          child: Column(
            children: [
              const SizedBox(height: 20),
              ...List.generate(17, (index) {
                final hour = 6 + index;
                return Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<CalendarEvent> dayEvents) {
    return Container(
      child: SingleChildScrollView(
        controller: _timelineController,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: 17 * 60 + 20, // 17時間 × 60px + 上部マージン
          child: Stack(
            children: [
              // グリッド背景
              _buildGridBackground(),
              
              // ドロップターゲット領域（ドラッグ&ドロップが有効な場合）
              if (widget.onEventDropped != null) _buildDropTargets(context),
              
              // 現在時刻線
              if (_isToday(widget.selectedDate)) _buildCurrentTimeLine(),
              
              // イベント表示
              ..._buildEventWidgets(context, dayEvents),
              
              // タップ可能エリア（ドラッグ&ドロップが無効な場合）
              if (widget.onEventDropped == null) _buildTappableAreas(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridBackground() {
    return Column(
      children: [
        const SizedBox(height: 20),
        ...List.generate(17, (index) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCurrentTimeLine() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // 6:00-22:00の範囲外は表示しない
    if (currentHour < 6 || currentHour >= 22) {
      return const SizedBox.shrink();
    }
    
    final topPosition = 20 + ((currentHour - 6) * 60) + (currentMinute * 60 / 60);
    
    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: Colors.red,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventWidgets(BuildContext context, List<CalendarEvent> dayEvents) {
    return dayEvents.map((event) {
      final startHour = event.startTime.hour;
      final startMinute = event.startTime.minute;
      final endHour = event.endTime.hour;
      final endMinute = event.endTime.minute;
      
      // 6:00-22:00の範囲外のイベントは調整
      final adjustedStartHour = startHour < 6 ? 6 : (startHour >= 22 ? 22 : startHour);
      final adjustedEndHour = endHour < 6 ? 6 : (endHour >= 22 ? 22 : endHour);
      
      final topPosition = (20 + ((adjustedStartHour - 6) * 60) + (startMinute * 60 / 60)).toDouble();
      final height = (((adjustedEndHour - adjustedStartHour) * 60) + ((endMinute - startMinute) * 60 / 60)).toDouble();
      
      return Positioned(
        top: topPosition,
        left: 8,
        right: 8,
        child: DraggableEventWidget(
          event: event,
          onEventTap: widget.onEventTap,
          onEventDropped: widget.onEventDropped ?? (event, time) {},
          height: height.clamp(30, double.infinity),
          isDraggable: widget.onEventDropped != null,
        ),
      );
    }).toList();
  }

  Widget _buildDropTargets(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20), // グリッド背景と同じオフセット
        ...List.generate(17, (index) {
          final hour = 6 + index;
          return Container(
            height: 60,
            child: DragTarget<CalendarEvent>(
              onWillAccept: (data) => true,
              onAccept: (CalendarEvent event) {
                final dropTime = DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  widget.selectedDate.day,
                  hour,
                  0,
                );
                widget.onEventDropped!(event, dropTime);
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
                    widget.onSlotTap(tappedTime);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.blue.withOpacity(0.6),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${hour.toString().padLeft(2, '0')}:00に移動',
                                  style: TextStyle(
                                    color: Colors.blue.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTappableAreas(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTapDown: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          
          // タップされた時間を計算
          final tappedHour = 6 + ((localPosition.dy - 20) / 60).floor();
          final tappedMinute = (((localPosition.dy - 20) % 60) / 60 * 60).round();
          
          if (tappedHour >= 6 && tappedHour < 22) {
            final tappedTime = DateTime(
              widget.selectedDate.year,
              widget.selectedDate.month,
              widget.selectedDate.day,
              tappedHour,
              tappedMinute,
            );
            
            widget.onSlotTap(tappedTime);
          }
        },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  List<CalendarEvent> _getEventsForDate(DateTime date, List<CalendarEvent> allEvents) {
    return allEvents.where((event) {
      final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return eventDate == targetDate;
    }).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
} 