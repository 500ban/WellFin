import 'package:flutter/material.dart';

/// Android固有のウィジェットとコンポーネント
class AndroidWidgets {
  /// Android風のスナックバー
  static void showAndroidSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  /// Android風のダイアログ
  static Future<T?> showAndroidDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: Text(cancelText),
            ),
          if (confirmText != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              child: Text(confirmText),
            ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  /// Android風のボトムシート
  static Future<T?> showAndroidBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => child,
    );
  }

  /// Android風のプログレスインジケーター
  static Widget androidProgressIndicator({
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double strokeWidth = 4.0,
    double size = 40.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(
          valueColor ?? const Color(0xFF2196F3),
        ),
        strokeWidth: strokeWidth,
      ),
    );
  }

  /// Android風のスイッチ
  static Widget androidSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
    Color? inactiveColor,
    Color? activeTrackColor,
    Color? inactiveTrackColor,
    Color? activeThumbColor,
    Color? inactiveThumbColor,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? const Color(0xFF2196F3),
      inactiveThumbColor: inactiveThumbColor ?? Colors.grey.shade300,
      activeTrackColor: activeTrackColor ?? const Color(0xFF2196F3).withOpacity(0.5),
      inactiveTrackColor: inactiveTrackColor ?? Colors.grey.shade200,
    );
  }

  /// Android風のチェックボックス
  static Widget androidCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    Color? activeColor,
    Color? checkColor,
    bool tristate = false,
  }) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? const Color(0xFF2196F3),
      checkColor: checkColor ?? Colors.white,
      tristate: tristate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Android風のラジオボタン
  static Widget androidRadio<T>({
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    Color? activeColor,
  }) {
    return Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor ?? const Color(0xFF2196F3),
    );
  }

  /// Android風のスライダー
  static Widget androidSlider({
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
    Color? activeColor,
    Color? inactiveColor,
    Color? thumbColor,
  }) {
    return Slider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor ?? const Color(0xFF2196F3),
      inactiveColor: inactiveColor ?? Colors.grey.shade300,
      thumbColor: thumbColor ?? const Color(0xFF2196F3),
    );
  }

  /// Android風のチップ
  static Widget androidChip({
    required String label,
    VoidCallback? onDeleted,
    Widget? avatar,
    Color? backgroundColor,
    Color? labelColor,
    Color? deleteIconColor,
    double? elevation,
  }) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: labelColor ?? Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onDeleted: onDeleted,
      avatar: avatar,
      backgroundColor: backgroundColor ?? const Color(0xFF2196F3),
      deleteIconColor: deleteIconColor ?? Colors.white,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  /// Android風のカード
  static Widget androidCard({
    required Widget child,
    Color? color,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      color: color,
      elevation: elevation ?? 2,
      margin: margin ?? const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  /// Android風のリストタイル
  static Widget androidListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool enabled = true,
    bool selected = false,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: TextStyle(
          color: textColor?.withOpacity(0.7),
          fontSize: 14,
        ),
      ) : null,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      selected: selected,
      selectedColor: selectedColor,
      iconColor: iconColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Android風のボタン
  static Widget androidButton({
    required String text,
    required VoidCallback onPressed,
    bool isOutlined = false,
    Color? backgroundColor,
    Color? foregroundColor,
    Widget? icon,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? const Color(0xFF2196F3),
          side: BorderSide(color: foregroundColor ?? const Color(0xFF2196F3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: icon != null ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(text),
          ],
        ) : Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? const Color(0xFF2196F3),
        foregroundColor: foregroundColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: icon != null ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(text),
        ],
      ) : Text(text),
    );
  }

  /// Android風の入力フィールド
  static Widget androidTextField({
    required String label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines,
    int? maxLength,
    bool enabled = true,
    bool readOnly = false,
    Color? fillColor,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? errorBorderColor,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor ?? Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: focusedBorderColor ?? const Color(0xFF2196F3),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: errorBorderColor ?? const Color(0xFFB00020),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        floatingLabelStyle: TextStyle(color: focusedBorderColor ?? const Color(0xFF2196F3)),
      ),
    );
  }
} 