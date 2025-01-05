import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormatUpdater extends ConsumerStatefulWidget {
  const FormatUpdater(this.initialBookFormat, this.updateBookFormat);

  final BookFormat? initialBookFormat;

  final void Function(BookFormat newFormat) updateBookFormat;

  @override
  ConsumerState createState() => _FormatUpdaterState();
}

class _FormatUpdaterState extends ConsumerState<FormatUpdater> {
  late BookFormat? _currFormat = widget.initialBookFormat;
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
                : Text(
                    _currFormat?.name ?? 'unknown',
                    style: TextStyles().value,
                  ),
            updateButton(),
          ],
        ),
      ),
    );
  }

  Widget formatSelector() {
    final shownFormats = List.from(BookFormat.values);

    // `null` should only be shown if it is the current value.
    // It shouldn't be something you can *choose*.
    if (_currFormat == null) shownFormats.add(null);

    return CupertinoSegmentedControl<RenderableFormat>(
      padding: EdgeInsets.zero,
      onValueChanged: updateFormat,
      groupValue: RenderableFormat(_currFormat),
      children: {
        for (final BookFormat? format in shownFormats)
          // Note: We have to wrap BookFormat with Renderable format because
          // nullable types are not allowed as type param for
          // CupertinoSegmentedControl.
          RenderableFormat(format): Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              format?.name ?? 'unknown',
              style: const TextStyle(fontSize: 10),
            ),
          )
      },
    );
  }

  void updateFormat(RenderableFormat selectedFormat) {
    if (selectedFormat.bookFormat == null) return;
    setState(() {
      _currFormat = selectedFormat.bookFormat;
      _editing = false;
    });
    widget.updateBookFormat(selectedFormat.bookFormat!);

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
