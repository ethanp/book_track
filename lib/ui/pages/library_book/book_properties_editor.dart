import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookPropertiesEditor extends ConsumerStatefulWidget {
  const BookPropertiesEditor(this.libraryBook);

  final LibraryBook libraryBook;

  @override
  ConsumerState createState() => _EditableBookPropertiesState();
}

class _EditableBookPropertiesState extends ConsumerState<BookPropertiesEditor> {
  BookFormat? _format;
  static final SimpleLogger log = SimpleLogger(prefix: 'BookPropertiesEditor');

  @override
  void initState() {
    super.initState();
    _format = widget.libraryBook.bookFormat;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    ref.watch(userLibraryProvider).whenData((items) => setState(() {
          bool isShownBook(LibraryBook book) =>
              book.supaId == widget.libraryBook.supaId;
          // The point of this block is to update this widget state when
          // an inner widget like the buttons modifies the backend. The
          // button invalidates the provider, which triggers this block.
          log('sourcing stored format');
          final LibraryBook shownBook = items.where(isShownBook).first;
          _format = shownBook.bookFormat;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          author(),
          length(),
          bookFormat(),
        ],
      ),
    );
  }

  Widget author() {
    return editableBookProperty(
      title: 'Author',
      value: widget.libraryBook.book.author ?? 'unknown',
      onPressed: () => print('Author pressed'),
    );
  }

  Widget length() {
    return editableBookProperty(
      title: 'Length',
      value: widget.libraryBook.bookLengthString,
      onPressed: () => print('Length pressed'),
    );
  }

  Widget editableBookProperty({
    required String title,
    required String value,
    required void Function() onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title: $value', style: TextStyles().h4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: FlutterHelpers.roundedRect(radius: 10),
              padding: EdgeInsets.zero,
            ),
            onPressed: onPressed,
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget bookFormat() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Book format: ', style: TextStyles().h4),
          SizedBox(height: 12),
          // We have to wrap BookFormat with Renderable format because
          // nullable types are not allowed as a type param for
          // CupertinoSegmentedControl.
          CupertinoSegmentedControl<RenderableFormat>(
            onValueChanged: updateFormat,
            groupValue: RenderableFormat(_format),
            children: formatNames(),
          ),
        ],
      ),
    );
  }

  void updateFormat(RenderableFormat selectedFormat) {
    setState(() => _format = selectedFormat.bookFormat);
    SupabaseLibraryService.updateFormat(
        widget.libraryBook, selectedFormat.bookFormat);
    ref.invalidate(userLibraryProvider);
  }

  Map<RenderableFormat, Widget> formatNames() => {
        for (final BookFormat? format
            in List.from(BookFormat.values)..add(null))
          RenderableFormat(format): paddedText(format)
      };

  Widget paddedText(BookFormat? format) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 8,
      ),
      child: Text(
        format?.name ?? 'unknown',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}
