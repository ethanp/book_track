import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GreyBoxTextField extends ConsumerStatefulWidget {
  const GreyBoxTextField({required this.textChanged});

  final void Function(String) textChanged;

  @override
  ConsumerState createState() => _GreyBoxTextFieldState();
}

class _GreyBoxTextFieldState extends ConsumerState<GreyBoxTextField> {
  final TextEditingController _controller = TextEditingController();
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
      child: TextFormField(
        controller: _controller,
        onChanged: (String newText) => widget.textChanged(newText),
        focusNode: _focusNode,
        decoration: InputDecoration(
          filled: true,
          // Turns darker while focused,
          fillColor: Colors.grey[_focusNode.hasFocus ? 300 : 200],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          // Border has sides only when focused
          border: border(BorderSide.none),
          focusedBorder:
              border(BorderSide(color: Colors.grey[500]!, width: 1.5)),
          hintText: 'Enter progress here',
        ),
      ),
    );
  }

  static OutlineInputBorder border(BorderSide borderSide) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: borderSide,
    );
  }
}
