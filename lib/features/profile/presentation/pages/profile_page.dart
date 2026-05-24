import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/auth/presentation/providers/auth_provider.dart';
import 'package:enstudy/features/profile/presentation/providers/profile_provider.dart';
import 'package:enstudy/features/profile/presentation/widgets/level_progress.dart';
import 'package:enstudy/features/profile/presentation/widgets/stat_card.dart';
import 'package:enstudy/features/profile/presentation/widgets/weekly_chart.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final weeklyAsync = ref.watch(weeklyStatsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(profileStatsProvider);
            ref.invalidate(weeklyStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserCard(context, ref, authState),
                const SizedBox(height: 16),
                _buildAiQuotaCard(context, ref, authState),
                const SizedBox(height: 20),
                LevelProgress(
                    level: profile.level, totalScore: profile.totalScore),
                const SizedBox(height: 20),
                _buildCheckinButton(context, ref, profile),
                const SizedBox(height: 20),
                _buildStatsGrid(context, statsAsync),
                const SizedBox(height: 20),
                _buildWeeklySection(context, weeklyAsync),
                const SizedBox(height: 20),
                _buildMenuSection(context, ref),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinButton(BuildContext context, WidgetRef ref, profile) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckin = profile.lastCheckin;
    final isTodayChecked = lastCheckin != null &&
        DateTime(lastCheckin.year, lastCheckin.month, lastCheckin.day) == today;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: isTodayChecked
            ? null
            : () => ref.read(profileProvider.notifier).checkIn(),
        icon: Icon(
            isTodayChecked
                ? Icons.check_circle_outline
                : Icons.wb_sunny_outlined,
            size: 20),
        label: Text(isTodayChecked ? '今日已签到' : '每日签到 +15积分'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isTodayChecked ? AppColors.textHint : AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, AsyncValue<ProfileStats?> statsAsync) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                '学习统计',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                StatCard(
                  icon: Icons.style_outlined,
                  value: '${stats.totalCards}',
                  label: '总卡片',
                  color: AppColors.primary,
                ),
                StatCard(
                  icon: Icons.replay_outlined,
                  value: '${stats.reviewCount}',
                  label: '复习次数',
                  color: AppColors.secondary,
                ),
                StatCard(
                  icon: Icons.trending_up_outlined,
                  value: '${(stats.correctRate * 100).toStringAsFixed(0)}%',
                  label: '正确率',
                  color: AppColors.success,
                ),
                StatCard(
                  icon: Icons.local_fire_department_outlined,
                  value: '${stats.streakDays}天',
                  label: '连续天数',
                  color: AppColors.accent,
                ),
                StatCard(
                  icon: Icons.event_outlined,
                  value: '${stats.todayDueCount}',
                  label: '今日待复习',
                  color: AppColors.warning,
                ),
                StatCard(
                  icon: Icons.verified_outlined,
                  value: '${stats.masteredCount}',
                  label: '已掌握',
                  color: AppColors.info,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeeklySection(
      BuildContext context, AsyncValue<List<int>> weeklyAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '本周学习趋势',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: weeklyAsync.when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox(
                height: 160,
                child: Center(child: Text('加载失败')),
              ),
              data: (data) => WeeklyChart(data: data),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Card(
      child: Column(
        children: [
          if (authState.isAdmin) ...[
            _buildMenuItem(
              context,
              Icons.admin_panel_settings_outlined,
              '用户管理',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('管理员', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              onTap: () => context.push('/profile/admin/users'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],
          _buildMenuItem(
            context,
            Icons.access_time_outlined,
            '复习提醒时间',
            onTap: () => context.push('/profile/settings'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context,
            Icons.add_card_outlined,
            '每日新卡数量',
            onTap: () => context.push('/profile/settings'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context,
            Icons.sports_esports_outlined,
            '游戏难度',
            onTap: () => context.push('/profile/settings'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context,
            Icons.backup_outlined,
            '数据管理',
            onTap: () => context.push('/profile/data-management'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            context,
            Icons.help_outline_outlined,
            '使用帮助',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, AuthState authState) {
    if (!authState.isLoggedIn) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_outline, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('未登录', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('登录后可使用AI智能解析功能', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showLoginDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('登录'),
              ),
            ],
          ),
        ),
      );
    }

    final user = authState.user!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              child: user.avatarUrl.isEmpty
                  ? Text(user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user.nickname, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (user.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('管理员', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('微信号: ${user.wechatId}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined, color: AppColors.textHint, size: 20),
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiQuotaCard(BuildContext context, WidgetRef ref, AuthState authState) {
    if (!authState.isLoggedIn) return const SizedBox.shrink();

    final quota = authState.aiQuota;
    final quotaColor = quota > 20 ? AppColors.success : (quota > 5 ? AppColors.warning : AppColors.error);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: quotaColor, size: 20),
                    const SizedBox(width: 8),
                    Text('AI智能解析次数', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: quotaColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '剩余 $quota 次',
                    style: TextStyle(fontSize: 14, color: quotaColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (quota / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(quotaColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/profile/purchase'),
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: Text(
                  quota <= 5 ? '次数不足，立即购买' : '购买更多次数',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: quota <= 5 ? AppColors.error : null,
                  foregroundColor: quota <= 5 ? Colors.white : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('微信登录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入微信号进行登录（模拟微信登录）', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '微信号',
                hintText: '请输入微信号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final wechatId = controller.text.trim();
              if (wechatId.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                ref.read(authProvider.notifier).loginWithWechatId(wechatId);
              }
            },
            child: const Text('登录'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('退出', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
