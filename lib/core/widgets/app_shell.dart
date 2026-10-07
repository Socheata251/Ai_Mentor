import 'package:flutter/material.dart';

import '../../data/repositories/chat_conversation_history.dart';
import '../../data/repositories/user_session.dart';
import '../../features/home/widgets/app_drawer.dart';
import '../router/app_nav.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_header.dart';

/// ONE wrapper used by every main screen. It holds the menu:
///   phone / tablet  -> slide-in drawer, opened by the [AppMenuButton] (☰)
///   desktop         -> permanent left sidebar (no ☰ needed)
///
/// Use it like this (the screen keeps its own Scaffold):
///   return AppShell(selectedIndex: 2, child: Scaffold(...));
/// and put `AppMenuButton()` at the left of the screen's header.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.child,
    this.userName,
  });

  /// Which menu item is highlighted (0 Home ... 7 Settings).
  final int selectedIndex;
  final Widget child;
  /// Defaults to the signed-in student.
  final String? userName;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ValueNotifier<int> _selected = ValueNotifier<int>(
    widget.selectedIndex,
  );

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected.value = widget.selectedIndex;
  }

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();
  void _closeMenu() => _scaffoldKey.currentState?.closeDrawer();

  void _onSelect(int i) {
    _closeMenu();
    if (i == widget.selectedIndex) return;
    AppNav.goTo(context, i, userName: widget.userName);
  }

  void _onNewChat() {
    _closeMenu();
    AppNav.newChat(context, userName: widget.userName);
  }

  void _onOpenChat(ChatConversation chat) {
    _closeMenu();
    AppNav.openChat(context, chat, userName: widget.userName);
  }

  @override
  Widget build(BuildContext context) {
    final hasSidebar = context.screenSize.isExpanded;

    return _AppShellScope(
      hasSidebar: hasSidebar,
      openMenu: _openMenu,
      // Refresh the menu header ("Hi, name") when the profile changes.
      child: ListenableBuilder(
        listenable: UserSession.instance,
        builder: (context, _) {
          final name = widget.userName ?? UserSession.instance.name;
          return Scaffold(
            key: _scaffoldKey,
            // The screen inside has its own Scaffold and handles the keyboard.
            resizeToAvoidBottomInset: false,
            drawer: hasSidebar
                ? null
                : AppDrawer(
                    userName: name,
                    selected: _selected,
                    onSelect: _onSelect,
                    onNewChat: _onNewChat,
                    onOpenChat: _onOpenChat,
                  ),
            body: hasSidebar
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeSideBar(
                        userName: name,
                        selected: _selected,
                        onSelect: _onSelect,
                        onNewChat: _onNewChat,
                        onOpenChat: _onOpenChat,
                      ),
                      Expanded(child: widget.child),
                    ],
                  )
                : widget.child,
          );
        },
      ),
    );
  }
}

class _AppShellScope extends InheritedWidget {
  const _AppShellScope({
    required this.hasSidebar,
    required this.openMenu,
    required super.child,
  });

  final bool hasSidebar;
  final VoidCallback openMenu;

  static _AppShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppShellScope>();

  @override
  bool updateShouldNotify(_AppShellScope old) => hasSidebar != old.hasSidebar;
}

/// The ☰ button. Same look on every screen. It hides itself when the
/// permanent sidebar is visible.
///
/// [keepSpace] keeps a 40px gap on desktop, for headers whose title is
/// centred between two buttons.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key, this.keepSpace = false});

  final bool keepSpace;

  /// Same rule AppShell uses, so it also works from a screen's own build()
  /// (which sits ABOVE the AppShell).
  static bool hasSidebarOf(BuildContext context) =>
      context.screenSize.isExpanded;

  /// For `AppHeader(leading: ...)` and `AppBar(leading: ...)`:
  /// null on desktop, so no empty gap is left.
  static Widget? leadingOf(BuildContext context) =>
      hasSidebarOf(context) ? null : const AppMenuButton();

  Widget _bar(double w, Color color) => Container(
    width: w,
    height: 2,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scope = _AppShellScope.maybeOf(context);
    if (scope == null || hasSidebarOf(context)) {
      return keepSpace
          ? const SizedBox(width: 40, height: 40)
          : const SizedBox.shrink();
    }
    final colors = context.colors;
    return Semantics(
      key: const ValueKey('navigation-menu'),
      button: true,
      label: 'Open navigation menu',
      child: HeaderButton(
        tooltip: 'Menu',
        onTap: scope.openMenu,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(16, colors.textStrong),
            const SizedBox(height: 4),
            _bar(10, colors.textStrong),
          ],
        ),
      ),
    );
  }
}