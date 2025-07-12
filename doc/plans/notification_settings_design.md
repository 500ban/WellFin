# 🔔 WellFin 通知設定機能 詳細設計

> **注意**: この設計書は `notification_implementation_plan.md` の補完文書です。  
> 通知機能実装完了時に一緒に削除されます。

---

## 🎯 ユーザー要望

**「通知設定として各通知の時間や頻度を変更できるととてもうれしい」**

この要望に応えるため、高度にカスタマイズ可能な通知設定システムを設計します。

---

## 📱 通知設定画面のUI設計

### 画面構成

```
📱 通知設定
├── 🔔 全体設定
│   ├── 通知の許可
│   ├── サイレント時間
│   └── 音・バイブレーション
│
├── 🔄 習慣リマインダー
│   ├── 全体ON/OFF
│   ├── デフォルト時間設定
│   └── 個別習慣設定
│
├── 📝 タスク・締切アラート
│   ├── 締切前通知
│   ├── 完了祝い通知
│   └── 優先度別設定
│
├── 🤖 AI分析・レポート
│   ├── 週次レポート
│   ├── 即座の洞察
│   └── 改善提案
│
└── 📅 カレンダー連携
    ├── イベント前通知
    ├── 同期完了通知
    └── 競合検出アラート
```

### 各設定項目の詳細

#### 🔄 習慣リマインダー設定

```dart
class HabitNotificationSettings {
  bool enabled;                    // 習慣通知の有効/無効
  String defaultTime;              // デフォルト時間 "07:00"
  List<int> defaultDays;           // デフォルト曜日 [1,2,3,4,5]
  bool allowCustomPerHabit;        // 習慣ごとの個別設定許可
  
  // 個別習慣設定
  Map<String, HabitCustomSettings> customSettings;
}

class HabitCustomSettings {
  bool enabled;                    // この習慣の通知ON/OFF
  String? customTime;              // カスタム時間（nullならデフォルト）
  List<int>? customDays;           // カスタム曜日（nullならデフォルト）
  int reminderCount;               // 1日の通知回数 1-3
  List<String> reminderTimes;      // 複数回の場合の時間リスト
  String notificationStyle;        // "gentle", "standard", "urgent"
}
```

#### 📝 タスク・締切アラート設定

```dart
class TaskNotificationSettings {
  bool deadlineAlertsEnabled;      // 締切アラート有効/無効
  List<int> alertHours;            // 何時間前 [24, 1] 
  bool completionCelebration;      // 完了祝い
  bool priorityBasedAlerts;        // 優先度別の通知強度
  
  // 優先度別設定
  Map<String, PriorityAlertSettings> prioritySettings;
  
  // 作業時間中の通知
  bool workingHoursOnly;           // 作業時間中のみ通知
  String workingStart;             // "09:00"
  String workingEnd;               // "18:00"
}

class PriorityAlertSettings {
  bool enabled;                    // この優先度の通知ON/OFF
  List<int> alertHours;            // カスタム通知タイミング
  String notificationStyle;        // 通知スタイル
  bool soundEnabled;               // 音の有効/無効
  bool vibrationEnabled;           // バイブレーションの有効/無効
}
```

#### 🤖 AI分析・レポート設定

```dart
class AINotificationSettings {
  bool weeklyReportEnabled;        // 週次レポート
  String weeklyReportDay;          // "sunday"
  String weeklyReportTime;         // "19:00"
  
  bool instantInsightsEnabled;     // 即座の洞察
  int insightsThreshold;           // 洞察の重要度閾値
  
  bool improvementSuggestionsEnabled; // 改善提案
  String suggestionFrequency;      // "weekly", "bi-weekly", "monthly"
  
  bool performanceAlertsEnabled;   // パフォーマンス低下アラート
  double performanceThreshold;     // アラート閾値（0.0-1.0）
}
```

---

## 🎨 UI/UX デザイン仕様

### 通知設定画面のレイアウト

#### メイン設定画面
```dart
class NotificationSettingsPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔔 通知設定'),
        actions: [
          // リセットボタン
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: () => _resetToDefaults(),
          ),
        ],
      ),
      body: ListView(
        children: [
          // 全体設定セクション
          _buildOverallSection(),
          
          // 習慣通知セクション
          _buildHabitsSection(),
          
          // タスク通知セクション  
          _buildTasksSection(),
          
          // AI通知セクション
          _buildAISection(),
          
          // カレンダー通知セクション
          _buildCalendarSection(),
          
          // 詳細設定セクション
          _buildAdvancedSection(),
        ],
      ),
    );
  }
}
```

#### 習慣リマインダー詳細設定
```dart
Widget _buildHabitsSection() {
  return ExpansionTile(
    leading: Icon(Icons.loop, color: Colors.blue),
    title: Text('🔄 習慣リマインダー'),
    subtitle: Text('${_enabledHabitsCount}件の習慣が設定済み'),
    children: [
      // 全体ON/OFF
      SwitchListTile(
        title: Text('習慣リマインダーを有効にする'),
        value: _habitSettings.enabled,
        onChanged: (value) => _updateHabitSettings(enabled: value),
      ),
      
      // デフォルト時間設定
      ListTile(
        title: Text('デフォルト通知時間'),
        subtitle: Text(_habitSettings.defaultTime),
        trailing: Icon(Icons.access_time),
        onTap: () => _showTimePicker(
          current: _habitSettings.defaultTime,
          onChanged: (time) => _updateHabitSettings(defaultTime: time),
        ),
      ),
      
      // デフォルト曜日設定
      ListTile(
        title: Text('デフォルト通知曜日'),
        subtitle: Text(_formatDays(_habitSettings.defaultDays)),
        trailing: Icon(Icons.date_range),
        onTap: () => _showDaysPicker(),
      ),
      
      // 個別習慣設定
      ListTile(
        title: Text('習慣ごとの個別設定'),
        subtitle: Text('各習慣の時間を個別に設定'),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitCustomSettingsPage(),
          ),
        ),
      ),
    ],
  );
}
```

#### 時間選択ピッカー
```dart
Future<void> _showTimePicker({
  required String current,
  required Function(String) onChanged,
}) async {
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(
      DateTime.parse('2023-01-01 $current:00'),
    ),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          // カスタムテーマ
        ),
        child: child!,
      );
    },
  );
  
  if (time != null) {
    final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    onChanged(formattedTime);
  }
}
```

#### 曜日選択ダイアログ
```dart
Widget _buildDaysPickerDialog() {
  return AlertDialog(
    title: Text('通知する曜日を選択'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          title: Text('月曜日'),
          value: _selectedDays.contains(1),
          onChanged: (value) => _toggleDay(1),
        ),
        CheckboxListTile(
          title: Text('火曜日'),
          value: _selectedDays.contains(2),
          onChanged: (value) => _toggleDay(2),
        ),
        // ... 他の曜日
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('キャンセル'),
      ),
      ElevatedButton(
        onPressed: () {
          _updateSelectedDays();
          Navigator.pop(context);
        },
        child: Text('保存'),
      ),
    ],
  );
}
```

---

## 💾 データ永続化の設計

### SharedPreferences による設定保存

```dart
class NotificationSettingsService {
  static const String _keyPrefix = 'notification_settings_';
  
  // 習慣設定の保存
  Future<void> saveHabitSettings(HabitNotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(settings.toJson());
    await prefs.setString('${_keyPrefix}habits', json);
  }
  
  // 習慣設定の読み込み
  Future<HabitNotificationSettings> loadHabitSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('${_keyPrefix}habits');
    
    if (json != null) {
      return HabitNotificationSettings.fromJson(jsonDecode(json));
    }
    
    // デフォルト設定を返す
    return HabitNotificationSettings.defaultSettings();
  }
  
  // 設定のリセット
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
```

### 設定の即座反映

```dart
class NotificationSettingsProvider extends StateNotifier<NotificationSettingsState> {
  final NotificationSettingsService _service;
  final LocalNotificationService _localNotificationService;
  
  NotificationSettingsProvider(this._service, this._localNotificationService)
      : super(NotificationSettingsState.loading()) {
    _loadSettings();
  }
  
  // 設定変更時の処理
  Future<void> updateHabitSettings(HabitNotificationSettings settings) async {
    // 設定を保存
    await _service.saveHabitSettings(settings);
    
    // 既存の通知をキャンセル
    await _localNotificationService.cancelHabitNotifications();
    
    // 新しい設定で通知をスケジュール
    await _localNotificationService.scheduleHabitNotifications(settings);
    
    // 状態更新
    state = state.copyWith(habitSettings: settings);
  }
}
```

---

## 🔧 実装時の考慮事項

### ユーザビリティ
1. **設定の複雑さ軽減**
   - デフォルト設定で十分な体験
   - 段階的な設定公開
   - プリセット設定の提供

2. **設定変更の即座反映**
   - 設定変更と同時に通知スケジュール更新
   - 変更内容のプレビュー機能

3. **設定の可視性**
   - 現在の設定状況を分かりやすく表示
   - 通知が来ない場合の原因説明

### パフォーマンス
1. **設定読み込みの最適化**
   - 必要な設定のみを読み込み
   - キャッシュ機能の実装

2. **通知スケジューリングの効率化**
   - バッチ処理での通知登録
   - 不要な通知の自動削除

### セキュリティ・プライバシー
1. **設定データの保護**
   - ローカル暗号化（必要に応じて）
   - 設定の不正変更防止

2. **通知内容の配慮**
   - 機密情報の通知文面除外
   - プライバシー設定の尊重

---

## 📋 実装タスクの追加

### Stage 1への追加タスク

通知設定機能の実装を Stage 1 に追加：

1. **NotificationSettingsService実装**（2-3日）
2. **NotificationSettingsProvider実装**（2-3日）
3. **通知設定画面UI実装**（3-4日）
4. **設定の即座反映機能**（2-3日）
5. **設定データの永続化**（1-2日）

### Stage 1更新後の期間
- **従来**: 1-2週間
- **更新後**: 2-3週間（柔軟な設定機能追加のため）

---

## 🎯 ユーザーメリット

この柔軟な通知設定により：

1. **個人最適化**: 各ユーザーのライフスタイルに合わせた通知
2. **通知疲れ防止**: 不要な通知の細かな制御
3. **習慣継続支援**: 最適なタイミングでのリマインダー
4. **作業効率向上**: 集中時間を妨げない通知設計

---

**作成日**: 2025年7月6日  
**削除予定**: 通知機能実装完了時 