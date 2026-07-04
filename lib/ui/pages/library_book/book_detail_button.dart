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
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: _buttonBody(),
        ),
      ),
    );
  }

  Widget _buttonBody() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: dense
                  ? AppTextStyles.h4.copyWith(fontSize: 13)
                  : AppTextStyles.h4,
            ),
            SizedBox(height: dense ? 0 : 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.65),
                fontSize: dense ? 9 : 14,
              ),
            ),
          ],
        ),
        Icon(
          icon,
          color: AppColors.textPrimary.withValues(alpha: 0.45),
          size: dense ? 25 : 42,
        ),
      ],
    );
  }
}
