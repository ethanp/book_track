import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:flutter/material.dart';

class UpdateFormatSelector extends StatelessWidget {
  const UpdateFormatSelector({
    required this.currentlySelectedFormat,
    required this.onSelected,
  });

  final ProgressEventFormat currentlySelectedFormat;
  final void Function(ProgressEventFormat) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Progress update format:'),
        SegmentedButton<ProgressEventFormat>(
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.blue
                  : Colors.grey[200],
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.black,
            ),
            visualDensity: VisualDensity.comfortable,
          ),
          selected: {currentlySelectedFormat},
          segments: {
            ProgressEventFormat.percent: '%',
            ProgressEventFormat.pageNum: 'pages',
            ProgressEventFormat.minutes: 'elapsed time',
          }.entries.mapL((a) => ButtonSegment(
              value: a.key,
              label: Text(a.value, style: TextStyle(fontSize: 12)))),
          // Because multi-selection is disabled by default for the
          // SegmentedButton, the `selection` argument will *only* contain
          // the newly selected segment (weird API, I know).
          onSelectionChanged: (selection) => onSelected(selection.first),
        ),
      ],
    );
  }
}
