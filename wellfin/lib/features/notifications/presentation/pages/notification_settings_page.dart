import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/notification_settings_provider.dart';
import '../../../../shared/models/notification_settings.dart';
import '../widgets/notification_settings_card.dart';
import '../widgets/time_picker_widget.dart';
import '../widgets/days_picker_widget.dart';

/// 🔔 通知設定画面
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(notificationSettingsProvider);
    final provider = ref.watch(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🔔 通知設定',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
          tooltip: 'ダッシュボードに戻る',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.grey),
            onPressed: () => _showResetConfirmDialog(context, provider),
            tooltip: 'デフォルトに戻す',
          ),
        ],
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : settingsState.error != null
              ? _buildErrorWidget(settingsState.error!, provider)
              : _buildSettingsContent(context, settingsState, provider),
    );
  }

  Widget _buildErrorWidget(String error, NotificationSettingsProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('再読み込み'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 全体設定セクション
          _buildOverallSection(context, state, provider),
          const SizedBox(height: 16),
          
          // 習慣リマインダーセクション
          _buildHabitsSection(context, state, provider),
          const SizedBox(height: 16),
          
          // タスク・締切アラートセクション
          _buildTasksSection(context, state, provider),
          const SizedBox(height: 16),
          
          // AI分析・レポートセクション
          _buildAISection(context, state, provider),
          const SizedBox(height: 16),
          
          // 詳細設定セクション
                      _buildAdvancedSection(context, state, provider),
            const SizedBox(height: 32),
        ],
      ),
    );
  }

  // === 全体設定セクション ===
  Widget _buildOverallSection(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    return NotificationSettingsCard(
      title: '🔔 全体設定',
      subtitle: '通知の基本設定',
      children: [
        // 通知の有効/無効
        SwitchListTile(
          title: const Text('通知を有効にする'),
          subtitle: const Text('すべての通知のマスタースイッチ'),
          value: state.overallSettings.notificationsEnabled,
          onChanged: (value) => provider.toggleNotifications(value),
          activeColor: Colors.blue,
        ),
        
        const Divider(),
        
        // サイレント時間設定
        ListTile(
          title: const Text('サイレント時間'),
          subtitle: Text(
            '${state.overallSettings.silentStartTime} - ${state.overallSettings.silentEndTime}',
          ),
          trailing: const Icon(Icons.bedtime),
          onTap: () => _showSilentTimeDialog(context, state, provider),
        ),
        
        const Divider(),
        
        // 週末通知設定
        SwitchListTile(
          title: const Text('週末通知'),
          subtitle: const Text('土日も通知を受け取る'),
          value: state.overallSettings.weekendNotificationsEnabled,
          onChanged: (value) => provider.toggleWeekendNotifications(value),
          activeColor: Colors.blue,
        ),
        
        const Divider(),
        
        // 音・バイブレーション設定
        SwitchListTile(
          title: const Text('音を有効にする'),
          subtitle: const Text('通知音の再生'),
          value: state.overallSettings.soundEnabled,
          onChanged: (value) {
            final settings = state.overallSettings.copyWith(soundEnabled: value);
            provider.updateOverallSettings(settings);
          },
          activeColor: Colors.blue,
        ),
        
        SwitchListTile(
          title: const Text('バイブレーション'),
          subtitle: const Text('通知時の振動'),
          value: state.overallSettings.vibrationEnabled,
          onChanged: (value) {
            final settings = state.overallSettings.copyWith(vibrationEnabled: value);
            provider.updateOverallSettings(settings);
          },
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  // === 習慣リマインダーセクション ===
  Widget _buildHabitsSection(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    final customCount = state.habitSettings.customSettings.length;
    
    return NotificationSettingsCard(
      title: '🔄 習慣リマインダー',
      subtitle: '${customCount}件の習慣が個別設定済み',
      children: [
        // 習慣通知の有効/無効
        SwitchListTile(
          title: const Text('習慣リマインダーを有効にする'),
          subtitle: const Text('習慣の継続をサポート'),
          value: state.habitSettings.enabled,
          onChanged: (value) => provider.toggleHabitNotifications(value),
          activeColor: Colors.green,
        ),
        
        if (state.habitSettings.enabled) ...[
          const Divider(),
          
          // デフォルト通知時間
          ListTile(
            title: const Text('デフォルト通知時間'),
            subtitle: Text(state.habitSettings.defaultTime),
            trailing: const Icon(Icons.access_time),
            onTap: () => _showTimePickerDialog(
              context,
              'デフォルト通知時間',
              state.habitSettings.defaultTime,
              (time) => provider.updateDefaultHabitTime(time),
            ),
          ),
          
          const Divider(),
          
          // デフォルト通知曜日
          ListTile(
            title: const Text('デフォルト通知曜日'),
            subtitle: Text(_formatDays(state.habitSettings.defaultDays)),
            trailing: const Icon(Icons.date_range),
            onTap: () => _showDaysPickerDialog(
              context,
              'デフォルト通知曜日',
              state.habitSettings.defaultDays,
              (days) => provider.updateDefaultHabitDays(days),
            ),
          ),
          
          const Divider(),
          
          // 個別習慣設定
          ListTile(
            title: const Text('習慣ごとの個別設定'),
            subtitle: const Text('各習慣の時間を個別に設定'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _navigateToHabitCustomSettings(context),
          ),
        ],
      ],
    );
  }

  // === タスク・締切アラートセクション ===
  Widget _buildTasksSection(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    return NotificationSettingsCard(
      title: '📝 タスク・締切アラート',
      subtitle: 'タスクと締切の通知設定',
      children: [
        // 締切アラートの有効/無効
        SwitchListTile(
          title: const Text('締切アラートを有効にする'),
          subtitle: const Text('締切前の通知'),
          value: state.taskSettings.deadlineAlertsEnabled,
          onChanged: (value) => provider.toggleDeadlineAlerts(value),
          activeColor: Colors.orange,
        ),
        
        if (state.taskSettings.deadlineAlertsEnabled) ...[
          const Divider(),
          
          // アラート時間設定
          ListTile(
            title: const Text('アラート時間'),
            subtitle: Text('${state.taskSettings.alertHours.join(", ")}時間前'),
            trailing: const Icon(Icons.schedule),
            onTap: () => _showAlertHoursDialog(
              context,
              state.taskSettings.alertHours,
              provider,
            ),
          ),
          
          const Divider(),
          
          // 作業時間限定通知
          SwitchListTile(
            title: const Text('作業時間中のみ通知'),
            subtitle: Text(
              '${state.taskSettings.workingStart} - ${state.taskSettings.workingEnd}',
            ),
            value: state.taskSettings.workingHoursOnly,
            onChanged: (value) => provider.toggleWorkingHoursOnly(value),
            activeColor: Colors.orange,
          ),
          
          if (state.taskSettings.workingHoursOnly) ...[
            const Divider(),
            
            // 作業時間設定
            ListTile(
              title: const Text('作業時間'),
              subtitle: Text(
                '${state.taskSettings.workingStart} - ${state.taskSettings.workingEnd}',
              ),
              trailing: const Icon(Icons.work),
              onTap: () => _showWorkingHoursDialog(context, state, provider),
            ),
          ],
        ],
        
        const Divider(),
        
        // 完了祝い通知
        SwitchListTile(
          title: const Text('完了祝い通知'),
          subtitle: const Text('タスク完了時の祝福メッセージ'),
          value: state.taskSettings.completionCelebration,
          onChanged: (value) => provider.toggleCompletionCelebration(value),
          activeColor: Colors.orange,
        ),
        
        const Divider(),
        
        // 優先度別設定
        ListTile(
          title: const Text('優先度別設定'),
          subtitle: const Text('重要度に応じた通知カスタマイズ'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _navigateToPrioritySettings(context),
        ),
      ],
    );
  }

  // === AI分析・レポートセクション ===
  Widget _buildAISection(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    return NotificationSettingsCard(
      title: '🤖 AI分析・レポート',
      subtitle: 'AIによる洞察と改善提案',
      children: [
        // 週次レポート
        SwitchListTile(
          title: const Text('週次レポート'),
          subtitle: Text(
            '${_formatDayJapanese(state.aiSettings.weeklyReportDay)}曜日 ${state.aiSettings.weeklyReportTime}',
          ),
          value: state.aiSettings.weeklyReportEnabled,
          onChanged: (value) => provider.toggleWeeklyReport(value),
          activeColor: Colors.purple,
        ),
        
        if (state.aiSettings.weeklyReportEnabled) ...[
          const Divider(),
          
          // 週次レポート時間設定
          ListTile(
            title: const Text('レポート配信時間'),
            subtitle: Text(
              '${_formatDayJapanese(state.aiSettings.weeklyReportDay)}曜日 ${state.aiSettings.weeklyReportTime}',
            ),
            trailing: const Icon(Icons.schedule_send),
            onTap: () => _showWeeklyReportTimeDialog(context, state, provider),
          ),
        ],
        
        const Divider(),
        
        // 即座の洞察
        SwitchListTile(
          title: const Text('即座の洞察'),
          subtitle: const Text('リアルタイムでの分析結果'),
          value: state.aiSettings.instantInsightsEnabled,
          onChanged: (value) => provider.toggleInstantInsights(value),
          activeColor: Colors.purple,
        ),
        
        const Divider(),
        
        // 改善提案
        SwitchListTile(
          title: const Text('改善提案'),
          subtitle: Text('${_formatFrequency(state.aiSettings.suggestionFrequency)}'),
          value: state.aiSettings.improvementSuggestionsEnabled,
          onChanged: (value) => provider.toggleImprovementSuggestions(value),
          activeColor: Colors.purple,
        ),
        
        if (state.aiSettings.improvementSuggestionsEnabled) ...[
          const Divider(),
          
          // 改善提案頻度設定
          ListTile(
            title: const Text('提案頻度'),
            subtitle: Text(_formatFrequency(state.aiSettings.suggestionFrequency)),
            trailing: const Icon(Icons.tune),
            onTap: () => _showSuggestionFrequencyDialog(context, state, provider),
          ),
        ],
      ],
    );
  }

  // === 詳細設定セクション ===
  Widget _buildAdvancedSection(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    return NotificationSettingsCard(
      title: '⚙️ 詳細設定',
      subtitle: '高度な設定オプション',
      children: [
        // 通知権限テスト
        ListTile(
          title: const Text('通知権限テスト'),
          subtitle: const Text('権限状況を確認・再要求'),
          trailing: const Icon(Icons.notification_important, color: Colors.orange),
          onTap: () => _showPermissionTestDialog(context, provider),
        ),
        
        const Divider(),
        
        // 設定統計
        ListTile(
          title: const Text('設定統計'),
          subtitle: const Text('現在の設定状況を確認'),
          trailing: const Icon(Icons.analytics),
          onTap: () => _showSettingsStats(context, provider),
        ),
        
        const Divider(),
        
        // 設定のエクスポート/インポート
        ListTile(
          title: const Text('設定のバックアップ'),
          subtitle: const Text('設定をエクスポート/インポート'),
          trailing: const Icon(Icons.cloud_download),
          onTap: () => _showBackupDialog(context, provider),
        ),
        
        const Divider(),
        
        // 設定のリセット
        ListTile(
          title: const Text('設定をリセット'),
          subtitle: const Text('すべての設定をデフォルトに戻す'),
          trailing: const Icon(Icons.restore, color: Colors.red),
          onTap: () => _showResetConfirmDialog(context, provider),
        ),
      ],
    );
  }



  // === ダイアログ表示メソッド ===
  
  void _showSilentTimeDialog(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サイレント時間設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('開始時間'),
              subtitle: Text(state.overallSettings.silentStartTime),
              trailing: const Icon(Icons.bedtime),
              onTap: () async {
                final time = await _showTimePickerOnly(
                  context,
                  state.overallSettings.silentStartTime,
                );
                if (time != null) {
                  provider.updateSilentHours(
                    time,
                    state.overallSettings.silentEndTime,
                  );
                }
              },
            ),
            ListTile(
              title: const Text('終了時間'),
              subtitle: Text(state.overallSettings.silentEndTime),
              trailing: const Icon(Icons.wb_sunny),
              onTap: () async {
                final time = await _showTimePickerOnly(
                  context,
                  state.overallSettings.silentEndTime,
                );
                if (time != null) {
                  provider.updateSilentHours(
                    state.overallSettings.silentStartTime,
                    time,
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showTimePickerDialog(
    BuildContext context,
    String title,
    String currentTime,
    Function(String) onTimeSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => TimePickerWidget(
        title: title,
        currentTime: currentTime,
        onTimeSelected: onTimeSelected,
      ),
    );
  }

  void _showDaysPickerDialog(
    BuildContext context,
    String title,
    List<int> currentDays,
    Function(List<int>) onDaysSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => DaysPickerWidget(
        title: title,
        currentDays: currentDays,
        onDaysSelected: onDaysSelected,
      ),
    );
  }

  Future<String?> _showTimePickerOnly(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (time != null) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  void _showAlertHoursDialog(
    BuildContext context,
    List<int> currentHours,
    NotificationSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アラート時間設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('何時間前に通知しますか？'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [1, 2, 4, 8, 24, 48, 72, 168].map((hours) {
                final isSelected = currentHours.contains(hours);
                return FilterChip(
                  label: Text('${hours}時間前'),
                  selected: isSelected,
                  onSelected: (selected) {
                    List<int> newHours = [...currentHours];
                    if (selected) {
                      newHours.add(hours);
                    } else {
                      newHours.remove(hours);
                    }
                    newHours.sort();
                    provider.updateAlertHours(newHours);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showWorkingHoursDialog(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('作業時間設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('開始時間'),
              subtitle: Text(state.taskSettings.workingStart),
              trailing: const Icon(Icons.work),
              onTap: () async {
                final time = await _showTimePickerOnly(
                  context,
                  state.taskSettings.workingStart,
                );
                if (time != null) {
                  provider.updateWorkingHours(
                    time,
                    state.taskSettings.workingEnd,
                  );
                }
              },
            ),
            ListTile(
              title: const Text('終了時間'),
              subtitle: Text(state.taskSettings.workingEnd),
              trailing: const Icon(Icons.work_off),
              onTap: () async {
                final time = await _showTimePickerOnly(
                  context,
                  state.taskSettings.workingEnd,
                );
                if (time != null) {
                  provider.updateWorkingHours(
                    state.taskSettings.workingStart,
                    time,
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showWeeklyReportTimeDialog(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('週次レポート時間設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('曜日'),
              subtitle: Text(_formatDayJapanese(state.aiSettings.weeklyReportDay)),
              trailing: const Icon(Icons.date_range),
              onTap: () => _showWeeklyReportDayDialog(context, state, provider),
            ),
            ListTile(
              title: const Text('時間'),
              subtitle: Text(state.aiSettings.weeklyReportTime),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await _showTimePickerOnly(
                  context,
                  state.aiSettings.weeklyReportTime,
                );
                if (time != null) {
                  provider.updateWeeklyReportTime(
                    state.aiSettings.weeklyReportDay,
                    time,
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showWeeklyReportDayDialog(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レポート配信曜日'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: days.map((day) {
            return RadioListTile<String>(
              title: Text(_formatDayJapanese(day)),
              value: day,
              groupValue: state.aiSettings.weeklyReportDay,
              onChanged: (value) {
                if (value != null) {
                  provider.updateWeeklyReportTime(
                    value,
                    state.aiSettings.weeklyReportTime,
                  );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _showSuggestionFrequencyDialog(
    BuildContext context,
    NotificationSettingsState state,
    NotificationSettingsProvider provider,
  ) {
    final frequencies = ['weekly', 'bi-weekly', 'monthly'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('改善提案頻度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: frequencies.map((frequency) {
            return RadioListTile<String>(
              title: Text(_formatFrequency(frequency)),
              value: frequency,
              groupValue: state.aiSettings.suggestionFrequency,
              onChanged: (value) {
                if (value != null) {
                  provider.updateSuggestionFrequency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _showSettingsStats(
    BuildContext context,
    NotificationSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定統計'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: provider.getSettingsStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('統計の取得に失敗しました');
            }
            
            final stats = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('全体設定: ${stats['overall']['enabled'] ? '有効' : '無効'}'),
                Text('サイレント時間: ${stats['overall']['silent_hours']}'),
                Text('習慣通知: ${stats['habits']['enabled'] ? '有効' : '無効'}'),
                Text('個別設定: ${stats['habits']['custom_settings_count']}件'),
                Text('タスク通知: ${stats['tasks']['deadline_alerts'] ? '有効' : '無効'}'),
                Text('AI週次レポート: ${stats['ai']['weekly_report'] ? '有効' : '無効'}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(
    BuildContext context,
    NotificationSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定のバックアップ'),
        content: const Text('この機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(
    BuildContext context,
    NotificationSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('すべての通知設定をデフォルトに戻しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetAllSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定をリセットしました')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  void _showPermissionTestDialog(
    BuildContext context,
    NotificationSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 通知権限テスト'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '現在の通知権限状況を確認し、必要に応じて権限を再要求できます。',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // 権限状況表示
              FutureBuilder<Map<String, dynamic>>(
                future: provider.getPermissionStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('権限状況を確認中...'),
                      ],
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('権限状況の確認に失敗しました');
                  }
                  
                  final status = snapshot.data!;
                  final hasPermission = status['hasPermission'] as bool;
                  final overallStatus = status['overallStatus'] as String;
                  final description = status['statusDescription'] as String;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasPermission ? Icons.check_circle : Icons.error,
                            color: hasPermission ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasPermission ? '通知権限: 許可済み' : '通知権限: 未許可',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: hasPermission ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('状態: $overallStatus'),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // テスト通知ボタン
              const Text(
                'テスト通知を送信:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 24,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _sendTestNotification(context, provider, 'habit'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.favorite, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 6),
                        const Text('習慣', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _sendTestNotification(context, provider, 'task'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.task, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 6),
                        const Text('タスク', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _sendTestNotification(context, provider, 'ai'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.smart_toy, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 6),
                        const Text('AI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton.icon(
            onPressed: () => _requestPermissionAgain(context, provider),
            icon: const Icon(Icons.security, size: 16),
            label: const Text('権限再要求'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification(
    BuildContext context,
    NotificationSettingsProvider provider,
    String type,
  ) async {
    try {
      bool success = false;
      
      switch (type) {
        case 'habit':
          success = await provider.sendTestHabitNotification();
          break;
        case 'task':
          success = await provider.sendTestTaskNotification();
          break;
        case 'ai':
          success = await provider.sendTestAINotification();
          break;
      }
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type}テスト通知を送信しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type}テスト通知の送信に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestPermissionAgain(
    BuildContext context,
    NotificationSettingsProvider provider,
  ) async {
    try {
      final hasPermission = await provider.requestNotificationPermission();
      
      if (hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('通知権限が許可されました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('通知権限が拒否されました。設定から手動で有効にしてください。'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // 設定アプリを開く
        // TODO: openAppSettingsの実装
      }
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('権限要求エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // === ナビゲーション ===
  
  void _navigateToHabitCustomSettings(BuildContext context) {
    // TODO: 習慣カスタム設定画面への遷移
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('習慣個別設定画面は実装予定です')),
    );
  }

  void _navigateToPrioritySettings(BuildContext context) {
    // TODO: 優先度設定画面への遷移
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('優先度設定画面は実装予定です')),
    );
  }

  // === ユーティリティメソッド ===
  
  String _formatDays(List<int> days) {
    if (days.isEmpty) return '設定なし';
    
    final dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    return days.map((day) => dayNames[day - 1]).join(', ');
  }

  String _formatDayJapanese(String day) {
    const dayMap = {
      'monday': '月',
      'tuesday': '火',
      'wednesday': '水',
      'thursday': '木',
      'friday': '金',
      'saturday': '土',
      'sunday': '日',
    };
    return dayMap[day] ?? day;
  }

  String _formatFrequency(String frequency) {
    const frequencyMap = {
      'weekly': '週次',
      'bi-weekly': '隔週',
      'monthly': '月次',
    };
    return frequencyMap[frequency] ?? frequency;
  }
} 