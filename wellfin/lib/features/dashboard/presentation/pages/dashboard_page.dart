import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../widgets/dashboard_widgets.dart';
import '../../../../shared/widgets/app_navigation_bar.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    
    // アニメーションコントローラーの初期化
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // スクロール監視の設定（ヘッダーが隠れるタイミングで表示）
    _scrollController.addListener(() {
      final showButton = _scrollController.offset > 80;
      if (showButton != _showScrollToTop) {
        setState(() {
          _showScrollToTop = showButton;
        });
      }
    });

    // データ読み込みとアニメーション開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
      ref.read(taskProvider.notifier).loadTasks();
      ref.read(habitProvider.notifier).loadTodayHabits();
      ref.read(goalNotifierProvider.notifier).loadGoals();
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      ref.read(calendarProvider.notifier).loadEvents(startOfDay, endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(currentUserDataProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 768;
    final isDesktop = screenSize.width > 1200;

    return userData.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
      data: (user) {
        if (user == null) {
          // データがnullでもローディング画面を表示
          return _buildLoadingState();
        }
        // データが揃ったときだけ本体UIを描画
        return Scaffold(
          backgroundColor: const Color(0xFFE3F2FD),
          body: _buildMainContent(context, user, isTablet, isDesktop),
          bottomNavigationBar: isDesktop ? null : const AppNavigationBar(currentIndex: 0),
          floatingActionButton: _showScrollToTop ? ScrollToTopFab(scrollController: _scrollController, showSettingsButton: true) : null,
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, UserModel user, bool isTablet, bool isDesktop) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildModernAppBar(user),
            if (isDesktop)
              _buildDesktopLayout(user)
            else if (isTablet)
              _buildTabletLayout(user)
            else
              _buildMobileLayout(user),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
                    colors: [
                const Color(0xFF2196F3),
                const Color(0xFF1976D2),
                    ],
                  ),
                ),
          child: SafeArea(
      child: Padding(
              padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                      Hero(
                        tag: 'user-avatar',
        child: Container(
                          width: 50,
                          height: 50,
          decoration: BoxDecoration(
                            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
              ),
            ],
          ),
                          child: CircleAvatar(
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'おかえりなさい',
              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                        AutoSizeText(
                          '${user.displayName}さん',
                          maxLines: 1,
                          minFontSize: 12,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                                  ],
            ),
                      ),
                      _buildProfileActions(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileActions() {
    return Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () {
              // 通知設定画面を表示
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
              },
            ),
        ),
                        const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () {
              // 設定BottomSheetを表示
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AppSettingsBottomSheet(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(UserModel user) {
    return SliverPadding(
      padding: const EdgeInsets.all(24.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildListDelegate([
          const DashboardStatsCard(),
          const DashboardQuickActionsCard(),
          const DashboardAIRecommendationsCard(),
          const DashboardCalendarCard(),
          const DashboardTasksCard(),
          const DashboardHabitsCard(),
          const DashboardGoalsCard(),
        ]),
      ),
    );
  }

  Widget _buildTabletLayout(UserModel user) {
    return SliverPadding(
      padding: const EdgeInsets.all(20.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildListDelegate([
          const DashboardStatsCard(),
          const DashboardQuickActionsCard(),
          const DashboardAIRecommendationsCard(),
          const DashboardTasksCard(),
          const DashboardCalendarCard(),
          const DashboardHabitsCard(),
          const DashboardGoalsCard(),
        ]),
      ),
    );
  }

  Widget _buildMobileLayout(UserModel user) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const DashboardStatsCard(),
          const SizedBox(height: 16),
          const DashboardQuickActionsCard(),
          const SizedBox(height: 16),
          const DashboardAIRecommendationsCard(),
          const SizedBox(height: 16),
          const DashboardTasksCard(),
          const SizedBox(height: 16),
          const DashboardCalendarCard(),
          const SizedBox(height: 16),
          const DashboardHabitsCard(),
          const SizedBox(height: 16),
          const DashboardGoalsCard(),
          const SizedBox(height: 80), // ボトムナビゲーション用スペース
        ]),
      ),
    );
  }



  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 本番と同じ背景グラデーション
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2196F3),
                  Color(0xFF1976D2),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('ダッシュボードを読み込み中...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(error) {
    return Scaffold(
      body: Center(
                    child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                      children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
            Text('エラーが発生しました: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
                  onPressed: () {
                _loadInitialData();
              },
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }




} 