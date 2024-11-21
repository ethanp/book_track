import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:flutter/material.dart';

class UpdateFormatSelector extends StatelessWidget {
  const UpdateFormatSelector({
    required this.currentlySelectedFormat,
    required this.onSelected,
    required this.book,
  });

  final ProgressEventFormat currentlySelectedFormat;
  final void Function(ProgressEventFormat) onSelected;
  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Progress update format:'),
        SegmentedButton<ProgressEventFormat>(
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: ifSelected(Colors.blue, otw: Colors.grey[200]),
            foregroundColor: ifSelected(Colors.white, otw: Colors.black),
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
    Color? blue, {
    required Color? otw,
  }) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? blue : otw,
      );

  List<ButtonSegment<ProgressEventFormat>> segments() => {
        ProgressEventFormat.percent: '%',
        if (book.bookFormat == BookFormat.audiobook)
          ProgressEventFormat.minutes: 'audio minutes'
        else
          ProgressEventFormat.pageNum: 'pages',
      }.entries.mapL((format) => ButtonSegment(
          value: format.key,
          label: Text(format.value, style: TextStyle(fontSize: 12))));
}
