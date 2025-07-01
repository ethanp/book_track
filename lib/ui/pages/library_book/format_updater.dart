import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormatUpdater extends ConsumerStatefulWidget {
  const FormatUpdater(this.initialBookFormat, this.updateBookFormat);

  final BookFormat initialBookFormat;

  final Future<void> Function(BookFormat newFormat) updateBookFormat;

  @override
  ConsumerState createState() => _FormatUpdaterState();
}

class _FormatUpdaterState extends ConsumerState<FormatUpdater> {
  late BookFormat _currFormat = widget.initialBookFormat;
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _editing
                ? formatSelector()
                : Text(_currFormat.name, style: TextStyles.value),
            updateButton(),
          ],
        ),
      ),
    );
  }

  Widget formatSelector() {
    return CupertinoSegmentedControl<BookFormat>(
      padding: EdgeInsets.zero,
      onValueChanged: updateFormat,
      groupValue: _currFormat,
      children: formatSegments(),
    );
  }

  /// * Key - the BookFormat to assign when widget is clicked
  /// * Value - the `label` [Widget] for this segment
  ///
  /// It returns a `LinkedHashMap` that will iterate in enum-declaration order.
  Map<BookFormat, Widget> formatSegments() {
    return Map.fromIterables(
      BookFormat.values,
      BookFormat.values.map(
        (format) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text(format.name, style: const TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

  Future<void> updateFormat(BookFormat selectedFormat) async {
    await widget.updateBookFormat(selectedFormat);

    // Note: this is still needed even though we invalidate the provider below.
    //  TODO(clarification) Ask ChatGpt? Possibly, it's because this is a stateful
    //   widget, which (may?) mean it's rebuild will *not* be triggered  by
    //   the parent rebuilding.
    setState(() {
      _currFormat = selectedFormat;
      _editing = false;
    });

    // This updates the length field format shown,
    //  e.g. in the case that the format transitioned from paper to audio.
    ref.invalidate(userLibraryProvider);
  }

  Widget updateButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => setState(() => _editing = !_editing),
      child:
          Text(_editing ? 'Cancel' : 'Update', style: TextStyles.valueButton),
    );
  }
}
