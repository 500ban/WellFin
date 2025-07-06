import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/calendar_event.dart';

class CalendarEventList extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Function(CalendarEvent) onEventTap;
  final bool showHeader;

  const CalendarEventList({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onEventTap,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー（showHeaderがtrueの場合のみ表示）
          if (showHeader)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('M月d日(E)', 'ja').format(selectedDate)}のイベント',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${events.length}件',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          
          // イベントリスト
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventItem(context, event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'この日にはイベントがありません',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+ ボタンでイベントを追加できます',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, CalendarEvent event) {
    final isOngoing = event.isOngoing;
    final isUpcoming = event.startTime.isAfter(DateTime.now());
    final isPast = event.endTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onEventTap(event),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getEventBackgroundColor(isOngoing, isUpcoming, isPast),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getEventBorderColor(isOngoing, isUpcoming, isPast),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 時間インジケーター
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getEventIndicatorColor(isOngoing, isUpcoming, isPast),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // イベント詳細
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトルと状態
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getEventTextColor(isOngoing, isUpcoming, isPast),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOngoing)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '進行中',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // 時間
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.isAllDay
                                ? '終日'
                                : '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(event.duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      
                      // 説明（あれば）
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // 場所（あれば）
                      if (event.location != null && event.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 矢印アイコン
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getEventBackgroundColor(bool isOngoing, bool isUpcoming, bool isPast) {
    if (isOngoing) return Colors.green.shade50;
    if (isPast) return Colors.grey.shade50;
    return Colors.blue.shade50;
  }

  Color _getEventBorderColor(bool isOngoing, bool isUpcoming, bool isPast) {
    if (isOngoing) return Colors.green.shade200;
    if (isPast) return Colors.grey.shade300;
    return Colors.blue.shade200;
  }

  Color _getEventIndicatorColor(bool isOngoing, bool isUpcoming, bool isPast) {
    if (isOngoing) return Colors.green;
    if (isPast) return Colors.grey.shade400;
    return Colors.blue;
  }

  Color _getEventTextColor(bool isOngoing, bool isUpcoming, bool isPast) {
    if (isPast) return Colors.grey.shade600;
    return Colors.black87;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}日${duration.inHours.remainder(24)}時間';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間${duration.inMinutes.remainder(60)}分';
    } else {
      return '${duration.inMinutes}分';
    }
  }
} 