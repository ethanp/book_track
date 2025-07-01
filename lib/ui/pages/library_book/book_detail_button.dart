import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';

class BookDetailButton extends StatelessWidget {
  const BookDetailButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.dense,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: Padding(
        padding: EdgeInsets.only(top: dense ? 0 : 14),
        child: CupertinoButton(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 20,
            vertical: dense ? 0 : 10,
          ),
          onPressed: onPressed,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          child: buttonBody(),
        ),
      ),
    );
  }

  Widget buttonBody() {
    final titleText = Text(
      title,
      style: dense ? TextStyles.h4.copyWith(fontSize: 13) : TextStyles.h3,
    );
    final subtitleText = Text(
      subtitle,
      style: TextStyle(
        color: CupertinoColors.black.withAlpha((0.72 * 255).toInt()),
        fontSize: dense ? 9 : 14.5,
      ),
    );
    final textColumn = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText,
        SizedBox(height: dense ? 0 : 2),
        subtitleText,
      ],
    );
    final iconWidget = Icon(
      icon,
      color: CupertinoColors.black.withAlpha((0.5 * 255).toInt()),
      size: dense ? 25 : 46,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [textColumn, iconWidget],
    );
  }
}
