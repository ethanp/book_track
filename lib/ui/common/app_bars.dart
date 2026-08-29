import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';

/// Cupertino navigation bar with a light warm cream→amber gradient.
class AppNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const AppNavigationBar(
      {this.leading,
      this.middle,
      this.trailing,
      this.previousPageTitle,
      this.automaticallyImplyLeading = true});

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
