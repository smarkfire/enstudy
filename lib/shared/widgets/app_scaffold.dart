import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(path: '/upload', icon: Icons.cloud_upload_outlined, activeIcon: Icons.cloud_upload, label: '上传'),
    _NavItem(path: '/cards', icon: Icons.style_outlined, activeIcon: Icons.style, label: '卡片'),
    _NavItem(path: '/games', icon: Icons.sports_esports_outlined, activeIcon: Icons.sports_esports, label: '游戏'),
    _NavItem(path: '/profile', icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (index) => context.go(_navItems[index].path),
        items: _navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
