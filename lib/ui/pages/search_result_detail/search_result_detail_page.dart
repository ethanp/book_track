import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/length_input.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cover_art.dart';

const _log = ELogger('SearchResultDetailPage');

class const SearchResultDetailPage(final OpenLibraryBook book)
    extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _SearchResultDetailPage();
}

class _SearchResultDetailPage() extends ConsumerState<SearchResultDetailPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: EAppHeader(title: widget.book.title),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [CoverArt(widget.book), bookMetadata(), formatButtons()],
          ),
        ),
      ),
    );
  }

  Widget formatButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Text("I'm reading this in", style: AppTextStyles.h2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _saving
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: BookFormat.values.mapL(typeButton),
                  ),
          ),
        ],
      ),
    );
  }

  Widget typeButton(BookFormat bookType) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: FilledButton(
        onPressed: () => _promptForLength(bookType),
        style: FilledButton.styleFrom(backgroundColor: bookType.color),
        child: Text(bookType.name, style: EText.label.small.white),
      ),
    );
  }

  Future<void> _promptForLength(BookFormat bookType) async {
    final isAudiobook = bookType == BookFormat.audiobook;
    final initialLength = widget.book.numPagesMedian;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => _LengthInputDialog(
        isAudiobook: isAudiobook,
        initialValue: isAudiobook ? null : initialLength,
      ),
    );

    if (result != null && mounted) {
      await addBookToLibrary(bookType, result);
    }
  }

  Future<void> addBookToLibrary(BookFormat bookType, int length) async {
    setState(() => _saving = true);
    try {
      await SupabaseLibraryService.addBook(widget.book, bookType, length);
    } catch (error, stack) {
      _log.error('(${error.runtimeType}) $error', error, stack);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        context.popUntilFirst();
      }
      ref.invalidate(userLibraryProvider);
    }
  }

  Widget bookMetadata() {
    return Column(
      children: [
        keyValueText('Title: ', widget.book.title),
        keyValueText('Author: ', widget.book.firstAuthor),
        keyValueText(
          'First Pub\'d: ',
          widget.book.yearFirstPublished.toString(),
        ),
        if (widget.book.numPagesMedian != null)
          keyValueText('Pages (est): ', widget.book.numPagesMedian!.toString()),
      ],
    );
  }

  Widget keyValueText(String key, String value) {
    final TextStyle metadataValue = AppTextStyles.body;
    final TextStyle metadataKey = AppTextStyles.label;
    final Widget keyWidget = SizedBox(
      width: 90,
      child: Text(
        key,
        style: metadataKey,
        maxLines: 3,
        textAlign: TextAlign.right,
      ),
    );
    final Widget valueWidget = SizedBox(
      width: 200,
      child: Text(value, style: metadataValue, maxLines: 3),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [keyWidget, SizedBox(width: 16), valueWidget]),
    );
  }
}

class const _LengthInputDialog({
  required final bool isAudiobook,
  final int? initialValue,
}) extends StatefulWidget {
  @override
  State<_LengthInputDialog> createState() => _LengthInputDialogState();
}

class _LengthInputDialogState() extends State<_LengthInputDialog> {
  late final LengthInputController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LengthInputController.fromAudiobook(
      isAudiobook: widget.isAudiobook,
      initialValue: widget.isAudiobook ? null : widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitEnteredLength() {
    final length = _controller.value;
    if (length != null && length > 0) Navigator.pop(context, length);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isAudiobook ? 'Audiobook Length' : 'Book Length'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isAudiobook
                  ? 'How long is the audiobook?'
                  : 'How many pages?',
            ),
            const SizedBox(height: 8),
            LengthInput(
              controller: _controller,
              autofocus: true,
              showLabel: !widget.isAudiobook,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
      actions: _controller.dialogActions(context, _submitEnteredLength),
    );
  }
}
