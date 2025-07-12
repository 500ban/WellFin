import 'package:flutter/material.dart';

/// 📱 通知設定カードウィジェット
/// 設定項目をグループ化して表示するためのカードコンテナ
class NotificationSettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final IconData? icon;
  final Color? iconColor;
  final bool isExpanded;
  final VoidCallback? onExpansionChanged;

  const NotificationSettingsCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.icon,
    this.iconColor,
    this.isExpanded = true,
    this.onExpansionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // カードヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: iconColor ?? Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // カード内容
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 📱 展開可能な通知設定カードウィジェット
class ExpandableNotificationSettingsCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final IconData? icon;
  final Color? iconColor;
  final bool initiallyExpanded;

  const ExpandableNotificationSettingsCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.icon,
    this.iconColor,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<ExpandableNotificationSettingsCard> createState() => _ExpandableNotificationSettingsCardState();
}

class _ExpandableNotificationSettingsCardState extends State<ExpandableNotificationSettingsCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.symmetric(vertical: 8),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        leading: widget.icon != null
            ? Icon(
                widget.icon,
                color: widget.iconColor ?? Colors.blue,
                size: 24,
              )
            : null,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        children: widget.children,
      ),
    );
  }
}

/// 📱 設定項目ウィジェット
class SettingsItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;

  const SettingsItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              color: iconColor ?? Colors.grey[600],
              size: 20,
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}

/// 📱 設定スイッチウィジェット
class SettingsSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final Color? iconColor;
  final Color? activeColor;

  const SettingsSwitch({
    Key? key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.iconColor,
    this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: icon != null
          ? Icon(
              icon,
              color: iconColor ?? Colors.grey[600],
              size: 20,
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? Colors.blue,
      dense: true,
    );
  }
}

/// 📱 設定範囲スライダーウィジェット
class SettingsSlider extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? labelFormatter;
  final IconData? icon;
  final Color? iconColor;

  const SettingsSlider({
    Key? key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.labelFormatter,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                labelFormatter?.call(value) ?? value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}

/// 📱 設定チップ選択ウィジェット
class SettingsChips extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> options;
  final List<String> selectedOptions;
  final ValueChanged<List<String>> onSelectionChanged;
  final bool multiSelect;
  final IconData? icon;
  final Color? iconColor;

  const SettingsChips({
    Key? key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.multiSelect = true,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  List<String> newSelection = [...selectedOptions];
                  if (multiSelect) {
                    if (selected) {
                      newSelection.add(option);
                    } else {
                      newSelection.remove(option);
                    }
                  } else {
                    newSelection = selected ? [option] : [];
                  }
                  onSelectionChanged(newSelection);
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 