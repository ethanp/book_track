import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const GreyBoxTextField({
  required final void Function(String) textChanged,
  final String? initialValue,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _GreyBoxTextFieldState();
}

class _GreyBoxTextFieldState() extends ConsumerState<GreyBoxTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Add a listener to trigger a rebuild when the focus state changes
    // to update the fillColor.
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        focusNode: _focusNode,
        enableSuggestions: false,
        controller: _controller,
        onChanged: widget.textChanged,
        decoration: InputDecoration(
          hintText: 'Enter progress here',
          filled: true,
          fillColor: _focusNode.hasFocus
              ? AppColors.shimmer
              : AppColors.surfaceInset,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.textSecondary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
