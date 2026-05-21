import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:enstudy/core/theme/colors.dart';
import 'package:enstudy/features/cards/presentation/providers/card_provider.dart';
import 'package:enstudy/features/cards/presentation/widgets/card_filter_bar.dart';
import 'package:enstudy/features/cards/presentation/widgets/card_list_item.dart';
import 'package:enstudy/shared/widgets/empty_state.dart';

class CardLibraryPage extends ConsumerStatefulWidget {
  const CardLibraryPage({super.key});

  @override
  ConsumerState<CardLibraryPage> createState() => _CardLibraryPageState();
}

class _CardLibraryPageState extends ConsumerState<CardLibraryPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardListProvider);
    final filterAsync = ref.watch(cardNotifierProvider);
    final countsAsync = ref.watch(cardCountProvider);
    final filter = filterAsync.valueOrNull ?? const CardFilter();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '搜索卡片...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  ref.read(cardNotifierProvider.notifier).searchCards(query);
                },
              )
            : const Text('卡片库'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(cardNotifierProvider.notifier).searchCards('');
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          CardFilterBar(
            selectedStatus: filter.status,
            statusCounts: countsAsync.valueOrNull ?? {},
            onStatusSelected: (status) {
              ref.read(cardNotifierProvider.notifier).filterByStatus(status);
            },
          ),
          const SizedBox(height: 8),
          _buildDueReviewBanner(cardsAsync),
          Expanded(
            child: cardsAsync.when(
              data: (cards) {
                if (cards.isEmpty) {
                  return const EmptyState(
                    icon: Icons.style_outlined,
                    title: '暂无卡片',
                    subtitle: '上传图片后自动生成学习卡片',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return CardListItem(
                      card: card,
                      onTap: () {
                        context.push('/cards/detail/${card.id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('加载失败: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/cards/review');
        },
        icon: const Icon(Icons.school),
        label: const Text('开始复习'),
      ),
    );
  }

  Widget _buildDueReviewBanner(AsyncValue cardsAsync) {
    final now = DateTime.now();
    final dueCount = cardsAsync.valueOrNull
            ?.where((c) => !c.nextReview.isAfter(now))
            .length ??
        0;

    if (dueCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.warning, Color(0xFFFF8A65)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '今日有 $dueCount 张卡片待复习',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.push('/cards/review');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '去复习',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
