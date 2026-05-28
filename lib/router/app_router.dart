import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/fragrances/screens/add_fragrance_screen.dart';
import '../features/fragrances/screens/fragrances_screen.dart';
import '../features/outfits/screens/create_outfit_screen.dart';
import '../features/outfits/screens/outfit_detail_screen.dart';
import '../features/outfits/screens/outfits_screen.dart';
import '../features/wardrobe/screens/add_item_screen.dart';
import '../features/wardrobe/screens/item_detail_screen.dart';
import '../features/wardrobe/screens/wardrobe_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/wardrobe',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _AppShell(shell: shell),
      branches: [
        // ── Wardrobe tab ─────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wardrobe',
              builder: (context, state) => const WardrobeScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddItemScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      ItemDetailScreen(itemId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) =>
                          AddItemScreen(editItemId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ── Outfits tab ───────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/outfits',
              builder: (context, state) => const OutfitsScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const CreateOutfitScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      OutfitDetailScreen(outfitId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => CreateOutfitScreen(
                        editOutfitId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ── Fragrances tab ────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/fragrances',
              builder: (context, state) => const FragrancesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const AddFragranceScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) => AddFragranceScreen(
                    editFragranceId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

// ── App shell with bottom navigation bar ─────────────────────────────────────

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _AppShell({required this.shell});

  static const int _branchCount = 3;

  void _handleSwipe(DragEndDetails details) {
    const threshold = 350.0; // px/s — fast enough to feel intentional
    final v = details.primaryVelocity ?? 0;
    if (v < -threshold) {
      // Swipe left → next tab
      final next = shell.currentIndex + 1;
      if (next < _branchCount) shell.goBranch(next);
    } else if (v > threshold) {
      // Swipe right → previous tab
      final prev = shell.currentIndex - 1;
      if (prev >= 0) shell.goBranch(prev);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: _handleSwipe,
        // deferToChild lets inner widgets (PageView carousels, etc.) win
        // the gesture arena first, so only unclaimed swipes reach us.
        behavior: HitTestBehavior.translucent,
        child: shell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Outfits',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Fragancias',
          ),
        ],
      ),
    );
  }
}
