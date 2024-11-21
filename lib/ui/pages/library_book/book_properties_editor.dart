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
  Widget build(BuildContext context) {
    List<BookFormat?> formatOptions = List.from(BookFormat.values);
    formatOptions.add(null);
    ref.watch(userLibraryProvider).whenData((items) => setState(() {
          bool isShownBook(LibraryBook book) =>
              book.supaId == widget.libraryBook.supaId;
          final LibraryBook shownBook = items.where(isShownBook).first;
          _format = shownBook.bookFormat;
        }));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Author: ${widget.libraryBook.book.author}',
            textAlign: TextAlign.center,
            style: TextStyles().h2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Book format: ', style: TextStyles().h3),
              SizedBox(height: 12),
              // We have to wrap BookFormat with Renderable format because
              // nullable types are not allowed as a type param for
              // CupertinoSegmentedControl.
              CupertinoSegmentedControl<RenderableFormat>(
                onValueChanged: (RenderableFormat selectedFormat) {
                  setState(() => _format = selectedFormat.bookFormat);
                  SupabaseLibraryService.updateFormat(
                      widget.libraryBook, selectedFormat.bookFormat);
                  ref.invalidate(userLibraryProvider);
                },
                groupValue: RenderableFormat(_format),
                children: {
                  for (final format in formatOptions)
                    RenderableFormat(format): Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Text(
                        format?.name ?? 'unknown',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
