import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BookDetailButton extends StatelessWidget {
  const BookDetailButton({
    required this.text,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
  });
  final String text;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle(),
        child: buttonBody(),
      ),
    );
  }

  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      shape: FlutterHelpers.roundedRect(radius: 10),
      fixedSize: Size(300, 75),
      side: BorderSide(width: .1),
      backgroundColor: backgroundColor,
      elevation: 4,
    );
  }

  Widget buttonBody() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: TextStyles().h3),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: CupertinoColors.black.withOpacity(.72),
                fontSize: 14.5,
              ),
            ),
          ],
        ),
        Icon(icon, size: 46, color: CupertinoColors.black.withOpacity(.5)),
      ],
    );
  }
}
