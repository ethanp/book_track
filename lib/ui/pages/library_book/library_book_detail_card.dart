import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

/// Shared book-page card surface. Rows inside stay visually separate.
class const LibraryBookDetailSurface({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: EColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}

/// Icon, value, and trailing actions on [LibraryBookDetailSurface].
class const LibraryBookDetailCard({
  required final IconData icon,
  required final Color iconColor,
  required final String title,
  required final Widget subtitle,
  final Widget? trailing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LibraryBookDetailSurface(
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle,
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
