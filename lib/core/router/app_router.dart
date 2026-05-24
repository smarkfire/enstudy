import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:enstudy/features/upload/presentation/pages/upload_page.dart';
import 'package:enstudy/features/upload/presentation/pages/card_preview_page.dart';
import 'package:enstudy/features/cards/presentation/pages/card_library_page.dart';
import 'package:enstudy/features/cards/presentation/pages/card_detail_page.dart';
import 'package:enstudy/features/cards/presentation/pages/review_page.dart';
import 'package:enstudy/features/games/domain/entities/game_type.dart';
import 'package:enstudy/features/games/presentation/pages/game_lobby_page.dart';
import 'package:enstudy/features/games/presentation/pages/game_play_page.dart';
import 'package:enstudy/features/games/presentation/pages/game_result_page.dart';
import 'package:enstudy/features/profile/presentation/pages/profile_page.dart';
import 'package:enstudy/features/profile/presentation/pages/settings_page.dart';
import 'package:enstudy/features/profile/presentation/pages/data_management_page.dart';
import 'package:enstudy/features/profile/presentation/pages/purchase_page.dart';
import 'package:enstudy/features/profile/presentation/pages/admin_user_list_page.dart';
import 'package:enstudy/shared/widgets/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/upload',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/upload',
          name: 'upload',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: UploadPage(),
          ),
          routes: [
            GoRoute(
              path: 'preview',
              name: 'cardPreview',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CardPreviewPage(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/cards',
          name: 'cards',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CardLibraryPage(),
          ),
          routes: [
            GoRoute(
              path: 'detail/:id',
              name: 'cardDetail',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return NoTransitionPage(
                  child: CardDetailPage(cardId: id),
                );
              },
            ),
            GoRoute(
              path: 'review',
              name: 'review',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ReviewPage(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/games',
          name: 'games',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GameLobbyPage(),
          ),
          routes: [
            GoRoute(
              path: 'play',
              name: 'gamePlay',
              pageBuilder: (context, state) {
                final gameType = state.extra as GameType;
                return NoTransitionPage(
                  child: GamePlayPage(gameType: gameType),
                );
              },
            ),
            GoRoute(
              path: 'result',
              name: 'gameResult',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: GameResultPage(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
          routes: [
            GoRoute(
              path: 'settings',
              name: 'profileSettings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
            GoRoute(
              path: 'data-management',
              name: 'dataManagement',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DataManagementPage(),
              ),
            ),
            GoRoute(
              path: 'purchase',
              name: 'purchase',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PurchasePage(),
              ),
            ),
            GoRoute(
              path: 'admin/users',
              name: 'adminUsers',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AdminUserListPage(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
