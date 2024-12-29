import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return Padding(
      padding: EdgeInsets.only(top: dense ? 0 : 14),
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle(),
        child: buttonBody(),
      ),
    );
  }

  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 20,
        vertical: dense ? 0 : 10,
      ),
      shape: FlutterHelpers.roundedRect(radius: 10),
      fixedSize: dense ? Size(174, 44) : Size(300, 75),
      side: BorderSide(width: dense ? .2 : .1),
      backgroundColor: backgroundColor,
      elevation: dense ? 0 : 4,
    );
  }

  Widget buttonBody() {
    final titleText = Text(
      title,
      style: dense ? TextStyles().h4.copyWith(fontSize: 13) : TextStyles().h3,
    );
    final subtitleText = Text(
      subtitle,
      style: TextStyle(
        color: CupertinoColors.black.withValues(alpha: .72),
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
      color: CupertinoColors.black.withValues(alpha: .5),
      size: dense ? 25 : 46,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [textColumn, iconWidget],
    );
  }
}
