import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';

/// Cupertino navigation bar with a light warm cream→amber gradient.
class AppNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const AppNavigationBar({
    this.leading,
    this.middle,
    this.trailing,
    this.previousPageTitle,
    this.automaticallyImplyLeading = true,
    super.key,
  });

  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;
  final String? previousPageTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppGradients.topBar,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: CupertinoNavigationBar(
        // Fully transparent + no blur/auto-opaque so the gradient shows through.
        backgroundColor: const Color(0x00000000),
        border: null,
        automaticBackgroundVisibility: false,
        enableBackgroundFilterBlur: false,
        leading: leading,
        middle: middle,
        trailing: trailing,
        previousPageTitle: previousPageTitle,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
    );
  }
}

/// Cupertino tab bar with a light warm amber→cream gradient.
///
/// Rebuilds the bar without Cupertino's BackdropFilter, which would hide the
/// gradient behind a frosted solid wash.
class GradientCupertinoTabBar extends CupertinoTabBar {
  const GradientCupertinoTabBar({
    required super.items,
    super.onTap,
    super.currentIndex = 0,
    super.activeColor,
    super.inactiveColor,
    super.iconSize,
    super.height,
    super.key,
  }) : super(backgroundColor: const Color(0x00000000));

  @override
  bool opaque(BuildContext context) => true;

  @override
  CupertinoTabBar copyWith({
    Key? key,
    List<BottomNavigationBarItem>? items,
    Color? backgroundColor,
    Color? activeColor,
    Color? inactiveColor,
    double? iconSize,
    double? height,
    Border? border,
    int? currentIndex,
    ValueChanged<int>? onTap,
  }) {
    return GradientCupertinoTabBar(
      key: key ?? this.key,
      items: items ?? this.items,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      iconSize: iconSize ?? this.iconSize,
      height: height ?? this.height,
      currentIndex: currentIndex ?? this.currentIndex,
      onTap: onTap ?? this.onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final double bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final Color resolvedInactive = CupertinoDynamicColor.resolve(
      inactiveColor,
      context,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppGradients.bottomBar,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SizedBox(
        height: height + bottomPadding,
        child: IconTheme.merge(
          data: IconThemeData(color: resolvedInactive, size: iconSize),
          child: DefaultTextStyle(
            style: CupertinoTheme.of(context)
                .textTheme
                .tabLabelTextStyle
                .copyWith(color: resolvedInactive),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Semantics(
                explicitChildNodes: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int index = 0; index < items.length; index++)
                      _tabItem(context, index),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabItem(BuildContext context, int index) {
    final bool active = index == currentIndex;
    final BottomNavigationBarItem item = items[index];
    final Color resolvedActive = CupertinoDynamicColor.resolve(
      activeColor ?? CupertinoTheme.of(context).primaryColor,
      context,
    );

    Widget tab = Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(index),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(child: Center(child: active ? item.activeIcon : item.icon)),
              if (item.label != null) Text(item.label!),
            ],
          ),
        ),
      ),
    );

    if (active) {
      tab = IconTheme.merge(
        data: IconThemeData(color: resolvedActive),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: resolvedActive),
          child: tab,
        ),
      );
    }

    return tab;
  }
}
