import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_week_view.dart';
import '../widgets/calendar_event_list.dart';
import '../widgets/calendar_timeline_view.dart';
import '../widgets/add_event_dialog.dart';
import '../widgets/delete_event_dialog.dart';
import '../../domain/entities/calendar_event.dart';
import '../../../../shared/widgets/app_navigation_bar.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

enum CalendarViewMode { week, timeline }

class _CalendarPageState extends ConsumerState<CalendarPage> 
    with TickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  CalendarViewMode viewMode = CalendarViewMode.week;
  bool _isEventListExpanded = false;
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // アニメーションコントローラー初期化
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // アニメーションを初期化（イベント1つ分の高さで開始）
    _expansionAnimation = Tween<double>(
      begin: 120.0, // イベント1つが見える高さ
      end: 500.0, // 固定値（ほとんどの画面サイズに対応）
    ).animate(CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    ));
    
    // 初期化時にトークンチェックと今日のデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCalendar();
    });
  }



  @override
  void dispose() {
    _expansionController.dispose();
    super.dispose();
  }

  Future<void> _initializeCalendar() async {
    try {
      final calendarNotifier = ref.read(calendarProvider.notifier);
      
      // 少し遅延を入れて、ダッシュボードでの初期化と競合しないようにする
      await Future.delayed(const Duration(milliseconds: 500));
      
      // トークンの有効性をチェック
      final isTokenValid = await calendarNotifier.checkAndRefreshToken();
      if (!isTokenValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Calendarへの接続に失敗しました。再度ログインしてください。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 今週のイベントを読み込み
      await _loadWeeklyEvents();
    } catch (e) {
      print('Calendar initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カレンダーの初期化に失敗しました: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadWeeklyEvents() async {
    final startOfWeek = _getStartOfWeek(selectedDate);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    await ref.read(calendarProvider.notifier).loadEvents(startOfWeek, endOfWeek);
  }

  DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => _onDateSelected(DateTime.now()),
            tooltip: '今日',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCalendar,
            tooltip: '更新',
          ),
        ],
      ),
      body: calendarState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // エラー表示
                if (calendarState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade100,
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            calendarState.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(calendarProvider.notifier).clearError(),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  ),
                
                // 日付選択ヘッダー
                _buildDateHeader(),
                
                // メインビューエリア
                Expanded(
                  child: _buildMainView(calendarState),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(selectedDate),
        child: const Icon(Icons.add),
        tooltip: '新しいイベント',
      ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ビュー切り替えボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(
                      '週間',
                      Icons.view_week,
                      CalendarViewMode.week,
                    ),
                    _buildViewToggleButton(
                      'タイムライン',
                      Icons.schedule,
                      CalendarViewMode.timeline,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 日付ナビゲーション
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeDate(-1),
              ),
              Text(
                _getHeaderText(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeDate(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(String label, IconData icon, CalendarViewMode mode) {
    final isSelected = viewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => viewMode = mode);
        _loadEventsForCurrentView();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView(CalendarState calendarState) {
    switch (viewMode) {
      case CalendarViewMode.week:
        return Column(
          children: [
            // 週間カレンダービュー
            Expanded(
              child: CalendarWeekView(
                selectedDate: selectedDate,
                events: calendarState.events,
                onDateSelected: _onDateSelected,
                onEventTap: _showEventDetails,
                onSlotTap: _showAddEventDialog,
              ),
            ),
            // アニメーション付き選択日のイベントリスト
            AnimatedBuilder(
              animation: _expansionAnimation,
              builder: (context, child) {
                // 画面サイズに応じて最大高さを調整
                final screenHeight = MediaQuery.of(context).size.height;
                final maxHeight = screenHeight * 0.65;
                
                return Container(
                  height: 120.0 + (_expansionAnimation.value / 500.0) * (maxHeight - 120.0),
                  child: _buildExpandableEventList(calendarState),
                );
              },
            ),
          ],
        );
      case CalendarViewMode.timeline:
        return CalendarTimelineView(
          selectedDate: selectedDate,
          events: calendarState.events,
          onEventTap: _showEventDetails,
          onSlotTap: _showAddEventDialog,
          onEventDropped: _onEventDropped,
        );
    }
  }

  String _getHeaderText() {
    switch (viewMode) {
      case CalendarViewMode.week:
        return _getWeekHeaderText();
      case CalendarViewMode.timeline:
        return DateFormat('yyyy年M月d日 (E)').format(selectedDate);
    }
  }

  String _getWeekHeaderText() {
    final startOfWeek = _getStartOfWeek(selectedDate);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    if (startOfWeek.month == endOfWeek.month) {
      return '${DateFormat('yyyy年M月d日').format(startOfWeek)} - ${DateFormat('d日').format(endOfWeek)}';
    } else {
      return '${DateFormat('yyyy年M月d日').format(startOfWeek)} - ${DateFormat('M月d日').format(endOfWeek)}';
    }
  }

  void _changeDate(int direction) {
    DateTime newDate;
    switch (viewMode) {
      case CalendarViewMode.week:
        newDate = selectedDate.add(Duration(days: 7 * direction));
        break;
      case CalendarViewMode.timeline:
        newDate = selectedDate.add(Duration(days: direction));
        break;
    }
    _onDateSelected(newDate);
    _loadEventsForCurrentView();
  }

  Future<void> _loadEventsForCurrentView() async {
    switch (viewMode) {
      case CalendarViewMode.week:
        await _loadWeeklyEvents();
        break;
      case CalendarViewMode.timeline:
        // タイムライン表示では選択日の前後数日分も読み込んで、日付切り替え時にスムーズに
        final startDate = selectedDate.subtract(const Duration(days: 2));
        final endDate = selectedDate.add(const Duration(days: 3));
        await ref.read(calendarProvider.notifier).loadEvents(startDate, endDate);
        break;
    }
  }

  List<CalendarEvent> _getEventsForDate(DateTime date, List<CalendarEvent> allEvents) {
    return allEvents.where((event) {
      final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return eventDate == targetDate;
    }).toList();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    ref.read(calendarProvider.notifier).setSelectedDate(date);
  }

  /// イベントリストの展開/縮小を切り替え
  void _toggleEventListExpansion() {
    setState(() {
      _isEventListExpanded = !_isEventListExpanded;
    });
    
    if (_isEventListExpanded) {
      _expansionController.forward();
    } else {
      _expansionController.reverse();
    }
  }

  /// 展開可能なイベントリストを構築
  Widget _buildExpandableEventList(CalendarState calendarState) {
    final todayEvents = _getEventsForDate(selectedDate, calendarState.events);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          // 展開可能ヘッダー
          GestureDetector(
            onTap: _toggleEventListExpansion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isEventListExpanded 
                    ? Colors.blue.shade50 
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 20,
                    color: _isEventListExpanded ? Colors.blue : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('M月d日(E)', 'ja').format(selectedDate)}のイベント',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isEventListExpanded ? Colors.blue : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isEventListExpanded ? Colors.blue : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${todayEvents.length}件',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isEventListExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: _isEventListExpanded ? Colors.blue : Colors.grey.shade600,
                    ),
                  ),

                ],
              ),
            ),
          ),
          
          // イベントリスト本体
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0), // 上側に余白を追加
              child: CalendarEventList(
                selectedDate: selectedDate,
                events: todayEvents,
                onEventTap: _showEventDetails,
                showHeader: false, // 独自ヘッダーを使用するためfalse
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _refreshCalendar() async {
    await _initializeCalendar();
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.event,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日時情報
              _buildDetailRow(
                Icons.schedule,
                '開始',
                DateFormat('M月d日 HH:mm').format(event.startTime),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.schedule_outlined,
                '終了',
                DateFormat('M月d日 HH:mm').format(event.endTime),
              ),
              
              // 継続時間表示
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.timer,
                '継続時間',
                _formatDuration(event.duration),
              ),
              
              // 詳細情報
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.description,
                  '詳細',
                  event.description!,
                ),
              ],
              
              // 場所情報
              if (event.location != null && event.location!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.location_on,
                  '場所',
                  event.location!,
                ),
              ],
            ],
          ),
        ),
        actions: [
          // 削除ボタン
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // まず詳細ダイアログを閉じる
              _showDeleteConfirmation(event);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
          
          // 閉じるボタン
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '${hours}時間${minutes}分' : '${hours}時間';
    } else {
      return '${minutes}分';
    }
  }

  void _showDeleteConfirmation(CalendarEvent event) {
    showDeleteEventDialog(
      context,
      event: event,
      onEventDeleted: _deleteEvent,
    );
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    try {
      // イベントを削除
      final success = await ref.read(calendarProvider.notifier).deleteEvent(event.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('イベント「${event.title}」を削除しました'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // イベントリストを更新
        await _loadEventsForCurrentView();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('イベントの削除に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Delete event failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddEventDialog(DateTime? dateTime) {
    final targetDateTime = dateTime ?? selectedDate;
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        initialDateTime: targetDateTime,
        onEventCreated: (event) async {
          final success = await ref.read(calendarProvider.notifier).createEvent(
            title: event.title,
            startTime: event.startTime,
            endTime: event.endTime,
            description: event.description,
            colorId: event.colorId,
          );
          
          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('イベントを作成しました')),
              );
            }
            await _loadWeeklyEvents();
          }
        },
      ),
    );
  }

  Future<void> _onEventDropped(CalendarEvent event, DateTime newStartTime) async {
    try {
      // 即座にローカル状態を更新（スムーズなUX）
      ref.read(calendarProvider.notifier).moveEventLocally(event, newStartTime);
      
      // 新しい終了時間を計算
      final duration = event.endTime.difference(event.startTime);
      final newEndTime = newStartTime.add(duration);

      // Google Calendar APIでイベント更新を実行（バックグラウンド）
      final updateSuccess = await ref.read(calendarProvider.notifier).updateEvent(
        eventId: event.id,
        title: event.title,
        startTime: newStartTime,
        endTime: newEndTime,
        description: event.description,
        colorId: event.colorId,
      );

      if (updateSuccess) {
        // 成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'イベント「${event.title}」を${DateFormat('HH:mm').format(newStartTime)}に移動しました',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // API更新が失敗した場合、元に戻す
        await _loadEventsForCurrentView();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Calendarの更新に失敗しました。変更を取り消しました。'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
    } catch (e) {
      print('Event drop failed: $e');
      
      // エラーが発生した場合、イベントを元に戻す
      await _loadEventsForCurrentView();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 