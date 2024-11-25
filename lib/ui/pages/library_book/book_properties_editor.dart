import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookPropertiesEditor extends ConsumerStatefulWidget {
  const BookPropertiesEditor(this.libraryBook);

  final LibraryBook libraryBook;

  @override
  ConsumerState createState() => _EditableBookPropertiesState();
}

class _EditableBookPropertiesState extends ConsumerState<BookPropertiesEditor> {
  BookFormat? _format;

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
          // TODO does this ever get called? Is this block still needed?
          //  setState() is called from within build() so maybe not? Does it
          //  get called when a button is pressed and the setState() call from
          //  build() would not be triggered in that case?
          print('sourcing stored format');
          final LibraryBook shownBook = items.where(isShownBook).first;
          _format = shownBook.bookFormat;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [author(), bookFormat()]);
  }

  Widget author() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        'Author: ${widget.libraryBook.book.author}',
        textAlign: TextAlign.center,
        style: TextStyles().h4,
      ),
    );
  }

  Padding bookFormat() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
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

  Map<RenderableFormat, Widget> formatNames() {
    var formats = List.from(BookFormat.values)..add(null);
    return {
      for (final BookFormat? format in formats)
        RenderableFormat(format): paddedText(format)
    };
  }

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
