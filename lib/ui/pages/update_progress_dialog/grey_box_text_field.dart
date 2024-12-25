import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GreyBoxTextField extends ConsumerStatefulWidget {
  const GreyBoxTextField({required this.textChanged, this.initialValue});

  final void Function(String) textChanged;
  final String? initialValue;

  @override
  ConsumerState createState() => _GreyBoxTextFieldState();
}

class _GreyBoxTextFieldState extends ConsumerState<GreyBoxTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
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
      child: CupertinoTextField(
        focusNode: _focusNode,
        enableSuggestions: false,
        placeholder: 'Enter progress here',
        controller: _controller,
        onChanged: (String newText) => widget.textChanged(newText),
        decoration: styleSearchBox(),
      ),
    );
  }

  BoxDecoration styleSearchBox() {
    return BoxDecoration(
      color: _focusNode.hasFocus
          ? CupertinoColors.systemGrey4
          : CupertinoColors.systemGrey5,
      borderRadius: BorderRadius.circular(8),
      border: _focusNode.hasFocus
          ? Border.all(color: CupertinoColors.systemGrey, width: 1.5)
          : Border.all(color: Colors.transparent, width: 0),
    );
  }
}
