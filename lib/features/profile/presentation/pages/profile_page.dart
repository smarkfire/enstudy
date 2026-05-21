import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enstudy/core/theme/colors.dart';
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
                LevelProgress(level: profile.level, totalScore: profile.totalScore),
                const SizedBox(height: 20),
                _buildCheckinButton(context, ref, profile),
                const SizedBox(height: 20),
                _buildStatsGrid(context, statsAsync),
                const SizedBox(height: 20),
                _buildWeeklySection(context, weeklyAsync),
                const SizedBox(height: 20),
                _buildMenuSection(context),
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
        onPressed: isTodayChecked ? null : () => ref.read(profileProvider.notifier).checkIn(),
        icon: Icon(isTodayChecked ? Icons.check_circle_outline : Icons.wb_sunny_outlined, size: 20),
        label: Text(isTodayChecked ? '今日已签到' : '每日签到 +15积分'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isTodayChecked ? AppColors.textHint : AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textHint.withOpacity(0.5),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AsyncValue<ProfileStats?> statsAsync) {
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

  Widget _buildWeeklySection(BuildContext context, AsyncValue<List<int>> weeklyAsync) {
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

  Widget _buildMenuSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
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
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      onTap: onTap,
    );
  }
}
