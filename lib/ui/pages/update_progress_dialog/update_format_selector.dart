import 'package:book_track/data_model.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

class const UpdateFormatSelector({
  required final ProgressEventFormat currentlySelectedFormat,
  required final void Function(ProgressEventFormat) onSelected,
  required final LibraryBook book,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Progress format:'),
        SegmentedButton<ProgressEventFormat>(
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: ifSelected(
              EColors.accent,
              otw: EColors.border,
            ),
            foregroundColor: ifSelected(
              Colors.white,
              otw: EColors.textPrimary,
            ),
            visualDensity: VisualDensity.comfortable,
          ),
          selected: {currentlySelectedFormat},
          segments: segments(),
          // Because multi-selection is disabled by default for the
          // SegmentedButton, the `selection` argument will *only* contain
          // the newly selected segment (weird API, I know).
          onSelectionChanged: (selection) => onSelected(selection.first),
        ),
      ],
    );
  }

  static WidgetStateProperty<Color?> ifSelected(
    Color? selectedColor, {
    required Color? otw,
  }) => WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.selected) ? selectedColor : otw,
  );

  List<ButtonSegment<ProgressEventFormat>> segments() {
    final Map<ProgressEventFormat, String> formatLabels = {
      if (book.defaultProgressFormat == ProgressEventFormat.minutes)
        ProgressEventFormat.minutes: 'audio hh:mm'
      else if (book.defaultProgressFormat == ProgressEventFormat.pageNum)
        ProgressEventFormat.pageNum: 'pages',
      ProgressEventFormat.percent: '%',
    };
    return formatLabels.entries.mapL(
      (format) => ButtonSegment(
        value: format.key,
        label: Text(format.value, style: TextStyle(fontSize: 12)),
      ),
    );
  }
}
