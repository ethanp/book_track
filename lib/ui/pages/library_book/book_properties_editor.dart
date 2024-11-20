import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_service.dart';
import 'package:book_track/ui/common/design.dart';
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
          final isShownBook = (i) => i.supaId == widget.libraryBook.supaId;
          _format = items.where(isShownBook).first.bookFormat;
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
          child: Row(children: [
            Text('Update format: ', style: TextStyles().h2),
            DropdownMenu(
              textAlign: TextAlign.center,
              onSelected: (choice) {
                setState(() => _format = choice);
                SupabaseLibraryService.updateFormat(widget.libraryBook, choice);
                ref.invalidate(userLibraryProvider);
              },
              initialSelection: _format,
              dropdownMenuEntries: formatOptions.mapL((format) {
                print('setting label as $_format');
                return DropdownMenuEntry(
                  value: format,
                  label: _format?.name ?? 'No Format',
                  labelWidget: Text(format?.name ?? 'unknown'),
                );
              }),
            ),
          ]),
        ),
      ],
    );
  }
}
