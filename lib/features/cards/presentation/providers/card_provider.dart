import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enstudy/core/database/app_database.dart';
import 'package:enstudy/core/database/daos/card_dao.dart';
import 'package:enstudy/features/cards/domain/entities/card.dart';
import 'package:enstudy/features/cards/domain/repositories/card_repository.dart';
import 'package:enstudy/features/cards/data/repositories/card_repository_impl.dart';
import 'package:enstudy/features/upload/presentation/providers/upload_provider.dart';

class CardFilter {
  final String? status;
  final String? type;
  final String? tag;
  final String? searchQuery;

  const CardFilter({
    this.status,
    this.type,
    this.tag,
    this.searchQuery,
  });

  CardFilter copyWith({
    String? status,
    String? type,
    String? tag,
    String? searchQuery,
    bool clearStatus = false,
    bool clearType = false,
    bool clearTag = false,
    bool clearSearchQuery = false,
  }) {
    return CardFilter(
      status: clearStatus ? null : (status ?? this.status),
      type: clearType ? null : (type ?? this.type),
      tag: clearTag ? null : (tag ?? this.tag),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepositoryImpl(CardDao(ref.watch(appDatabaseProvider)));
});

class CardNotifier extends AsyncNotifier<CardFilter> {
  @override
  Future<CardFilter> build() async {
    return const CardFilter();
  }

  CardRepository get _repository => ref.read(cardRepositoryProvider);

  void loadCards() {
    ref.invalidate(cardListProvider);
    ref.invalidate(cardCountProvider);
  }

  void filterByStatus(String? status) {
    final current = state.valueOrNull ?? const CardFilter();
    state = AsyncData(current.copyWith(
      status: status,
      clearStatus: status == null,
    ));
  }

  void filterByType(String? type) {
    final current = state.valueOrNull ?? const CardFilter();
    state = AsyncData(current.copyWith(
      type: type,
      clearType: type == null,
    ));
  }

  void searchCards(String query) {
    final current = state.valueOrNull ?? const CardFilter();
    state = AsyncData(current.copyWith(
      searchQuery: query.isEmpty ? null : query,
      clearSearchQuery: query.isEmpty,
    ));
  }

  Future<void> deleteCard(String id) async {
    await _repository.deleteCard(id);
    ref.invalidate(cardCountProvider);
  }

  Future<void> deleteCards(List<String> ids) async {
    for (final id in ids) {
      await _repository.deleteCard(id);
    }
    ref.invalidate(cardCountProvider);
  }

  Future<void> updateCard(Card card) async {
    await _repository.updateCard(card);
    ref.invalidate(cardCountProvider);
  }
}

final cardNotifierProvider = AsyncNotifierProvider<CardNotifier, CardFilter>(
  CardNotifier.new,
);

final cardListProvider = StreamProvider<List<Card>>((ref) {
  final filterAsync = ref.watch(cardNotifierProvider);
  final filter = filterAsync.valueOrNull ?? const CardFilter();
  final repository = ref.watch(cardRepositoryProvider);

  Stream<List<Card>> stream;

  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    stream = repository.searchCards(filter.searchQuery!);
  } else if (filter.status != null) {
    stream = repository.getCardsByStatus(filter.status!);
  } else {
    stream = repository.getCards();
  }

  return stream.map((cards) {
    var result = cards;
    if (filter.status != null &&
        filter.searchQuery != null &&
        filter.searchQuery!.isNotEmpty) {
      result = result.where((c) => c.status == filter.status).toList();
    }
    if (filter.type != null) {
      result = result.where((c) => c.type == filter.type).toList();
    }
    if (filter.tag != null) {
      result = result.where((c) => c.tags.contains(filter.tag)).toList();
    }
    return result;
  });
});

final cardCountProvider = FutureProvider<Map<String, int>>((ref) {
  final repository = ref.watch(cardRepositoryProvider);
  return repository.getCardCountByStatus();
});

final cardDetailProvider = FutureProvider.family<Card, String>((ref, id) async {
  final repository = ref.watch(cardRepositoryProvider);
  final card = await repository.getCardById(id);
  if (card == null) throw Exception('Card not found');
  return card;
});
