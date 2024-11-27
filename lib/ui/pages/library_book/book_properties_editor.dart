import 'package:book_track/data_model.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookPropertiesEditor extends ConsumerStatefulWidget {
  const BookPropertiesEditor(this.libraryBook);

  final LibraryBook libraryBook;
  static final SimpleLogger log = SimpleLogger(prefix: 'BookPropertiesEditor');

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
          // The point of this block is to update this widget state when
          // an inner widget like the buttons modifies the backend. The
          // button invalidates the provider, which triggers this block.
          BookPropertiesEditor.log('sourcing stored format');
          final LibraryBook shownBook = items.where(isShownBook).first;
          _format = shownBook.bookFormat;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [author(), bookFormat()],
    );
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

  Widget bookFormat() {
    return Padding(
      padding: const EdgeInsets.all(12),
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
