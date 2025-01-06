import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormatUpdater extends ConsumerStatefulWidget {
  const FormatUpdater(this.initialBookFormat, this.updateBookFormat);

  final BookFormat initialBookFormat;

  final void Function(BookFormat newFormat) updateBookFormat;

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
                : Text(_currFormat.name, style: TextStyles().value),
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
      children: {
        for (final BookFormat format in BookFormat.values)
          // Note: We have to wrap BookFormat with Renderable format because
          // nullable types are not allowed as type param for
          // CupertinoSegmentedControl.
          format: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              format.name,
              style: const TextStyle(fontSize: 10),
            ),
          )
      },
    );
  }

  void updateFormat(BookFormat selectedFormat) {
    setState(() {
      _currFormat = selectedFormat;
      _editing = false;
    });
    widget.updateBookFormat(selectedFormat);

    // This is to update the length field format shown,
    //  e.g. in the case that the format transitioned from paper to audio.
    ref.invalidate(userLibraryProvider);
  }

  Widget updateButton() {
    return ElevatedButton(
      style: Buttons.updateButtonStyle(
        color: _editing ? Colors.red.shade300 : CupertinoColors.systemGrey6,
      ),
      onPressed: () => setState(() => _editing = !_editing),
      child: Text(_editing ? 'Cancel' : 'Update'),
    );
  }
}
