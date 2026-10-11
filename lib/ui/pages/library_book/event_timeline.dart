import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

import 'progress_day_card.dart';

class const EventTimeline(final LibraryBook libraryBook)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: libraryBook.progressEventDays.reversed.mapL(
          (day) => ProgressDayCard(libraryBook, day),
        ),
      ),
    );
  }
}
