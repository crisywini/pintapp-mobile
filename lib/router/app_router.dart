import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
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
        ],
      ),
    );
  }
}
