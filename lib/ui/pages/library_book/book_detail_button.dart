import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';

class const BookDetailButton({
  required final String title,
  required final String subtitle,
  required final IconData icon,
  required final VoidCallback onActivated,
  required final Color backgroundColor,
  required final bool dense,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: Padding(
        padding: EdgeInsets.only(top: dense ? 0 : 14),
        child: FilledButton(
          onPressed: onActivated,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: AppColors.textPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 10 : 20,
              vertical: dense ? 0 : 10,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          child: SizedBox(width: double.infinity, child: _buttonBody()),
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
