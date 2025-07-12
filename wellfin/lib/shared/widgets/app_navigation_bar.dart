import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tasks/presentation/pages/task_list_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/goals/presentation/pages/goal_list_page.dart';
import '../../features/habits/presentation/pages/habit_list_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../providers/auth_provider.dart';

// ナビゲーションの状態を管理するプロバイダー
final navigationStateProvider = StateProvider<int>((ref) => 0);

// ナビゲーションアイテム
enum NavigationItem {
  dashboard(
    icon: Icons.dashboard,
    filledIcon: Icons.dashboard,
    label: 'ダッシュボード',
  ),
  tasks(
    icon: Icons.task_alt_outlined,
    filledIcon: Icons.task_alt,
    label: 'タスク',
  ),
  calendar(
    icon: Icons.calendar_today_outlined,
    filledIcon: Icons.calendar_today,
    label: 'カレンダー',
  ),
  analytics(
    icon: Icons.analytics_outlined,
    filledIcon: Icons.analytics,
    label: '分析',
  );

  const NavigationItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
  });

  final IconData icon;
  final IconData filledIcon;
  final String label;
}

class AppNavigationBar extends ConsumerWidget {
  const AppNavigationBar({
    super.key,
    this.currentIndex = 0,
    this.onNavigate,
  });

  final int currentIndex;
  final Function(int index)? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: NavigationItem.values.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == currentIndex;
                
                return _buildNavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    if (onNavigate != null) {
                      onNavigate!(index);
                    } else {
                      _defaultNavigate(context, ref, index);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NavigationItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? item.filledIcon : item.icon,
          size: 28,
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
        ),
      ),
    );
  }

  void _defaultNavigate(BuildContext context, WidgetRef ref, int index) {
    ref.read(navigationStateProvider.notifier).state = index;
    
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TaskListPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnalyticsPage()),
        );
        break;
    }
  }
}

// 設定BottomSheetもモジュール化
class AppSettingsBottomSheet extends ConsumerWidget {
  const AppSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // タイトル
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 28, color: Color(0xFF2196F3)),
                const SizedBox(width: 16),
                const Text(
                  '設定',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // ログアウトボタン
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextButton.icon(
                    onPressed: () => _handleLogout(context, ref),
                    icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
                    label: const Text(
                      'ログアウト',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 機能設定セクション
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '機能設定',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.task_alt,
                  title: 'タスク管理',
                  subtitle: 'タスクの作成・編集・管理',
                  iconColor: Colors.orange,
                  backgroundColor: Colors.orange.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TaskListPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.repeat,
                  title: '習慣トラッキング',
                  subtitle: '習慣の記録・継続管理',
                  iconColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitListPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.calendar_month,
                  title: 'カレンダー管理',
                  subtitle: 'スケジュール・予定の管理',
                  iconColor: Colors.blue,
                  backgroundColor: Colors.blue.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CalendarPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.flag,
                  title: '目標管理',
                  subtitle: '目標の作成・編集・管理',
                  iconColor: Colors.purple,
                  backgroundColor: Colors.purple.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalListPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.analytics,
                  title: '分析レポート',
                  subtitle: '時間使用状況の詳細分析',
                  iconColor: Colors.green,
                  backgroundColor: Colors.green.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // アプリ設定セクション
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'アプリ設定',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications,
                  title: '通知設定',
                  subtitle: 'プッシュ通知の管理',
                  iconColor: Colors.orange,
                  backgroundColor: Colors.orange.withValues(alpha: 0.05),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.info,
                  title: 'アプリについて',
                  subtitle: 'バージョン情報・ヘルプ',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF2196F3)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFF2196F3), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // 設定BottomSheetを閉じる
    
    try {
      final authActions = ref.read(authActionsProvider);
      await authActions.signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログアウトに失敗しました: $e')),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WellFin について'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WellFin - 個人管理アプリ'),
            SizedBox(height: 8),
            Text('バージョン: 1.0.0'),
            SizedBox(height: 8),
            Text('タスク管理、カレンダー、習慣トラッキング、目標設定を統合した生産性向上アプリです。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// スクロールトップ用のFloatingActionButton
class ScrollToTopFab extends StatelessWidget {
  const ScrollToTopFab({
    super.key,
    required this.scrollController,
    required this.showSettingsButton,
    this.onSettingsPressed,
  });

  final ScrollController scrollController;
  final bool showSettingsButton;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSettingsButton) ...[
          // 設定ボタン
          FloatingActionButton(
            heroTag: "settings",
            onPressed: onSettingsPressed ?? () => _showSettingsBottomSheet(context),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2196F3),
            elevation: 8,
            child: const Icon(Icons.settings),
          ),
          const SizedBox(height: 8),
        ],
        // TOPに戻るボタン
        FloatingActionButton(
          heroTag: "scrollToTop",
          onPressed: () {
            scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 8,
          child: const Icon(Icons.keyboard_arrow_up),
        ),
      ],
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AppSettingsBottomSheet(),
    );
  }
} 