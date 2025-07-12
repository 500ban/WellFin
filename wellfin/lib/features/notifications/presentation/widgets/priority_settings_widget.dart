import 'package:flutter/material.dart';
import '../../../../shared/models/notification_settings.dart';

/// 📋 優先度設定ウィジェット
/// タスクの優先度別通知設定をカスタマイズするためのダイアログ
class PrioritySettingsWidget extends StatefulWidget {
  final Map<String, PriorityAlertSettings> currentSettings;
  final Function(Map<String, PriorityAlertSettings>) onSettingsChanged;

  const PrioritySettingsWidget({
    Key? key,
    required this.currentSettings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<PrioritySettingsWidget> createState() => _PrioritySettingsWidgetState();
}

class _PrioritySettingsWidgetState extends State<PrioritySettingsWidget>
    with TickerProviderStateMixin {
  late Map<String, PriorityAlertSettings> settings;
  late TabController _tabController;

  final priorities = [
    {'key': 'high', 'name': '高', 'color': Colors.red, 'icon': Icons.priority_high},
    {'key': 'medium', 'name': '中', 'color': Colors.orange, 'icon': Icons.remove},
    {'key': 'low', 'name': '低', 'color': Colors.green, 'icon': Icons.low_priority},
  ];

  @override
  void initState() {
    super.initState();
    settings = Map<String, PriorityAlertSettings>.from(widget.currentSettings);
    _tabController = TabController(length: priorities.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune, color: Colors.blue),
          SizedBox(width: 12),
          Text(
            '優先度別設定',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // タブバー
            TabBar(
              controller: _tabController,
              tabs: priorities.map((priority) {
                final color = priority['color'] as Color;
                final icon = priority['icon'] as IconData;
                final name = priority['name'] as String;
                
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        name,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
            ),
            
            const SizedBox(height: 16),
            
            // タブビュー
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: priorities.map((priority) {
                  final key = priority['key'] as String;
                  final color = priority['color'] as Color;
                  
                  return _buildPrioritySettings(key, color);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildPrioritySettings(String priorityKey, Color priorityColor) {
    final setting = settings[priorityKey] ?? PriorityAlertSettings.defaultSettings(priorityKey);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 有効/無効スイッチ
          Card(
            child: SwitchListTile(
              title: const Text('この優先度の通知を有効にする'),
              subtitle: const Text('オフにすると、この優先度のタスクは通知されません'),
              value: setting.enabled,
              onChanged: (value) {
                _updatePrioritySetting(priorityKey, setting.copyWith(enabled: value));
              },
              activeColor: priorityColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (setting.enabled) ...[
            // アラート時間設定
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'アラート時間',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '何時間前に通知しますか？',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [1, 2, 4, 8, 24, 48, 72, 168].map((hours) {
                        final isSelected = setting.alertHours.contains(hours);
                        return FilterChip(
                          label: Text(_formatHours(hours)),
                          selected: isSelected,
                          onSelected: (selected) {
                            _updateAlertHours(priorityKey, hours, selected);
                          },
                          selectedColor: priorityColor.withOpacity(0.2),
                          checkmarkColor: priorityColor,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 通知スタイル設定
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '通知スタイル',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationStyleSelector(priorityKey, setting, priorityColor),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 音・バイブレーション設定
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '音・バイブレーション',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('音を鳴らす'),
                      subtitle: const Text('通知音を再生します'),
                      value: setting.soundEnabled,
                      onChanged: (value) {
                        _updatePrioritySetting(
                          priorityKey,
                          setting.copyWith(soundEnabled: value),
                        );
                      },
                      activeColor: priorityColor,
                      dense: true,
                    ),
                    SwitchListTile(
                      title: const Text('バイブレーション'),
                      subtitle: const Text('端末を振動させます'),
                      value: setting.vibrationEnabled,
                      onChanged: (value) {
                        _updatePrioritySetting(
                          priorityKey,
                          setting.copyWith(vibrationEnabled: value),
                        );
                      },
                      activeColor: priorityColor,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationStyleSelector(
    String priorityKey,
    PriorityAlertSettings setting,
    Color priorityColor,
  ) {
    final styles = [
      {'key': 'gentle', 'name': '控えめ', 'description': '静かで目立たない通知'},
      {'key': 'standard', 'name': '標準', 'description': '通常の通知'},
      {'key': 'urgent', 'name': '緊急', 'description': '目立つ通知'},
    ];

    return Column(
      children: styles.map((style) {
        return RadioListTile<String>(
          title: Text(style['name']!),
          subtitle: Text(style['description']!),
          value: style['key']!,
          groupValue: setting.notificationStyle,
          onChanged: (value) {
            if (value != null) {
              _updatePrioritySetting(
                priorityKey,
                setting.copyWith(notificationStyle: value),
              );
            }
          },
          activeColor: priorityColor,
          dense: true,
        );
      }).toList(),
    );
  }

  void _updatePrioritySetting(String key, PriorityAlertSettings newSetting) {
    setState(() {
      settings[key] = newSetting;
    });
  }

  void _updateAlertHours(String priorityKey, int hours, bool selected) {
    final setting = settings[priorityKey]!;
    List<int> newHours = [...setting.alertHours];
    
    if (selected) {
      if (!newHours.contains(hours)) {
        newHours.add(hours);
      }
    } else {
      newHours.remove(hours);
    }
    
    newHours.sort();
    _updatePrioritySetting(priorityKey, setting.copyWith(alertHours: newHours));
  }

  void _saveSettings() {
    widget.onSettingsChanged(settings);
    Navigator.of(context).pop();
  }

  String _formatHours(int hours) {
    if (hours < 24) {
      return '${hours}時間前';
    } else if (hours == 24) {
      return '1日前';
    } else if (hours < 168) {
      return '${(hours / 24).round()}日前';
    } else {
      return '1週間前';
    }
  }
}

/// 📋 優先度表示ウィジェット
/// 現在の優先度設定を要約表示するウィジェット
class PriorityDisplayWidget extends StatelessWidget {
  final Map<String, PriorityAlertSettings> settings;
  final VoidCallback? onTap;

  const PriorityDisplayWidget({
    Key? key,
    required this.settings,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorities = [
      {'key': 'high', 'name': '高', 'color': Colors.red},
      {'key': 'medium', 'name': '中', 'color': Colors.orange},
      {'key': 'low', 'name': '低', 'color': Colors.green},
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  '優先度別設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: priorities.map((priority) {
                final key = priority['key'] as String;
                final name = priority['name'] as String;
                final color = priority['color'] as Color;
                final setting = settings[key];
                final enabled = setting?.enabled ?? false;
                
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: enabled ? color.withOpacity(0.1) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: enabled ? color : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          enabled ? Icons.notifications_active : Icons.notifications_off,
                          color: enabled ? color : Colors.grey[400],
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: enabled ? color : Colors.grey[400],
                        ),
                      ),
                      if (enabled && setting != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${setting.alertHours.length}個',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📋 優先度ごとの設定サマリーウィジェット
/// 各優先度の詳細設定を一覧表示するウィジェット
class PrioritySummaryWidget extends StatelessWidget {
  final Map<String, PriorityAlertSettings> settings;

  const PrioritySummaryWidget({
    Key? key,
    required this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorities = [
      {'key': 'high', 'name': '高優先度', 'color': Colors.red, 'icon': Icons.priority_high},
      {'key': 'medium', 'name': '中優先度', 'color': Colors.orange, 'icon': Icons.remove},
      {'key': 'low', 'name': '低優先度', 'color': Colors.green, 'icon': Icons.low_priority},
    ];

    return Column(
      children: priorities.map((priority) {
        final key = priority['key'] as String;
        final name = priority['name'] as String;
        final color = priority['color'] as Color;
        final icon = priority['icon'] as IconData;
        final setting = settings[key];

        if (setting == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            leading: Icon(icon, color: color),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            subtitle: Text(
              setting.enabled ? '有効' : '無効',
              style: TextStyle(
                color: setting.enabled ? color : Colors.grey,
              ),
            ),
            children: [
              if (setting.enabled) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(
                        'アラート時間',
                        setting.alertHours.isEmpty
                            ? 'なし'
                            : setting.alertHours
                                .map((h) => _formatHours(h))
                                .join(', '),
                        Icons.access_time,
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        '通知スタイル',
                        _formatNotificationStyle(setting.notificationStyle),
                        Icons.style,
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        '音・バイブ',
                        '${setting.soundEnabled ? '音あり' : '音なし'} / ${setting.vibrationEnabled ? 'バイブあり' : 'バイブなし'}',
                        Icons.volume_up,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'この優先度の通知は無効になっています',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  String _formatHours(int hours) {
    if (hours < 24) {
      return '${hours}h';
    } else if (hours == 24) {
      return '1日';
    } else if (hours < 168) {
      return '${(hours / 24).round()}日';
    } else {
      return '1週間';
    }
  }

  String _formatNotificationStyle(String style) {
    switch (style) {
      case 'gentle':
        return '控えめ';
      case 'standard':
        return '標準';
      case 'urgent':
        return '緊急';
      default:
        return style;
    }
  }
} 