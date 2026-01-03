import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/services/supabase_library_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/length_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManualBookForm extends ConsumerStatefulWidget {
  const ManualBookForm({required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<ManualBookForm> createState() => _ManualBookFormState();
}

class _ManualBookFormState extends ConsumerState<ManualBookForm> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _yearController = TextEditingController();
  late LengthInputController _lengthController;

  BookFormat _selectedFormat = BookFormat.paperback;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lengthController = LengthInputController.fromAudiobook(isAudiobook: false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _yearController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  bool get isAudiobook => _selectedFormat == BookFormat.audiobook;

  bool get canSave =>
      _titleController.text.isNotEmpty && (_lengthController.value ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          const SizedBox(height: 24),
          textField(
            controller: _titleController,
            label: 'Title',
            placeholder: 'Book title (required)',
          ),
          textField(
            controller: _authorController,
            label: 'Author',
            placeholder: 'Author name',
          ),
          textField(
            controller: _yearController,
            label: 'Year Published',
            placeholder: 'e.g. 2024',
            keyboardType: TextInputType.number,
          ),
          formatSelector(),
          lengthField(),
          const SizedBox(height: 32),
          saveButton(),
        ],
      ),
    );
  }

  Widget header() {
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onBack,
          child: const Icon(CupertinoIcons.back),
        ),
        Expanded(
          child: Text(
            'Add Book Manually',
            style: TextStyles.h1,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyles.h4),
          const SizedBox(height: 4),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            padding: const EdgeInsets.all(12),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget formatSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Format', style: TextStyles.h4),
          const SizedBox(height: 8),
          Row(
            children: BookFormat.values.map(formatButton).toList(),
          ),
        ],
      ),
    );
  }

  Widget formatButton(BookFormat format) {
    final isSelected = _selectedFormat == format;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: isSelected ? formatColor(format) : CupertinoColors.systemGrey4,
          onPressed: () => selectFormat(format),
          child: Text(
            format.name,
            style: TextStyles.value.copyWith(
              fontSize: 12,
              color: isSelected ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ),
      ),
    );
  }

  Color formatColor(BookFormat format) => switch (format) {
        BookFormat.audiobook => CupertinoColors.systemOrange,
        BookFormat.eBook => CupertinoColors.systemBlue,
        BookFormat.paperback => CupertinoColors.systemRed,
        BookFormat.hardcover => CupertinoColors.systemGreen,
      };

  void selectFormat(BookFormat format) {
    if (format == _selectedFormat) return;
    setState(() {
      _selectedFormat = format;
      _lengthController.dispose();
      _lengthController =
          LengthInputController.fromAudiobook(isAudiobook: isAudiobook);
    });
  }

  Widget lengthField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAudiobook ? 'Length (h:mm)' : 'Pages', style: TextStyles.h4),
          const SizedBox(height: 4),
          LengthInput(
            controller: _lengthController,
            showLabel: !isAudiobook,
            fieldWidth: 80,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget saveButton() {
    return CupertinoButton.filled(
      onPressed: canSave && !_saving ? save : null,
      child: _saving
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : const Text('Add to Library'),
    );
  }

  Future<void> save() async {
    setState(() => _saving = true);
    try {
      final year = int.tryParse(_yearController.text);
      await SupabaseLibraryService.addManualBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim().nullIfEmpty,
        yearPublished: year,
        format: _selectedFormat,
        length: _lengthController.value!,
      );
      if (mounted) {
        ref.invalidate(userLibraryProvider);
        context.popUntilFirst();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
