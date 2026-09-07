import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const ArchivedBooksSection({required final VoidCallback onActivated})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onActivated,
      child: Text(
        'See archived books...',
        style: AppTextStyles.h4.copyWith(color: EColors.accent),
      ),
    );
  }
}
