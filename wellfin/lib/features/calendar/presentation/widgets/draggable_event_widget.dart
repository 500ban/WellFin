import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/calendar_event.dart';

/// ドラッグ可能なカレンダーイベントウィジェット
class DraggableEventWidget extends StatelessWidget {
  final CalendarEvent event;
  final Function(CalendarEvent) onEventTap;
  final Function(CalendarEvent, DateTime) onEventDropped;
  final double width;
  final double height;
  final bool isDraggable;

  const DraggableEventWidget({
    super.key,
    required this.event,
    required this.onEventTap,
    required this.onEventDropped,
    this.width = double.infinity,
    this.height = 60.0,
    this.isDraggable = true,
  });

  @override
  Widget build(BuildContext context) {
    final eventWidget = _buildEventContainer(context);

    if (!isDraggable) {
      return GestureDetector(
        onTap: () => onEventTap(event),
        child: eventWidget,
      );
    }

    return Draggable<CalendarEvent>(
      data: event,
      feedback: _buildDragFeedback(context),
      childWhenDragging: _buildChildWhenDragging(context),
      onDragStarted: () {
        // ドラッグ開始時のハプティックフィードバック
        _triggerHapticFeedback();
      },
      onDragEnd: (details) {
        // ドラッグ終了時の処理（必要に応じて）
      },
      child: GestureDetector(
        onTap: () => onEventTap(event),
        child: eventWidget,
      ),
    );
  }

  Widget _buildEventContainer(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            event.color.withOpacity(0.8),
            event.color.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.color.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: event.color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: height < 35 
        // 小さいカード用の簡略レイアウト
        ? Center(
            child: Text(
              event.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          )
        // 通常サイズのカード用レイアウト
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // イベントタイトル
              Flexible(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: height > 60 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              if (height > 50) ...[
                const SizedBox(height: 2),
                // 時間表示
                Text(
                  '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
              
              // ドラッグインジケーター（スペースがある場合のみ）
              if (isDraggable && height > 65) ...[
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.drag_handle,
                      size: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ],
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildDragFeedback(BuildContext context) {
    // ドラッグフィードバック用の固定サイズを計算
    final feedbackWidth = (width.isFinite && width > 50) ? width.clamp(180.0, 300.0) : 220.0;
    final feedbackHeight = (height + 4).clamp(50.0, 100.0); // 適切な高さ範囲に制限
    
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: feedbackWidth,
        height: feedbackHeight,
        constraints: const BoxConstraints(
          minWidth: 180,
          maxWidth: 300,
          minHeight: 50,
          maxHeight: 100,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              event.color.withOpacity(0.9),
              event.color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: event.color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: event.color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: feedbackHeight > 70 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (feedbackHeight > 50) ...[
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildWhenDragging(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.color.withOpacity(0.4),
          width: 2,
          style: BorderStyle.solid,
        ),
        color: event.color.withOpacity(0.1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: event.color.withOpacity(0.5),
              size: height > 40 ? 20 : 16,
            ),
            if (height > 50) ...[
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  '移動中...',
                  style: TextStyle(
                    fontSize: 10,
                    color: event.color.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  void _triggerHapticFeedback() {
    // iOS/Androidでのハプティックフィードバック
    try {
      // HapticFeedback.lightImpact(); // 必要に応じて追加
    } catch (e) {
      // プラットフォームでサポートされていない場合は無視
    }
  }
}

/// ドラッグ可能イベントのプレビュー用ウィジェット
class EventDragPreview extends StatelessWidget {
  final CalendarEvent event;
  final double width;
  final double height;

  const EventDragPreview({
    super.key,
    required this.event,
    this.width = 180,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.blue,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
} 