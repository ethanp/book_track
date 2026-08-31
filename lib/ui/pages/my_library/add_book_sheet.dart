import 'package:book_track/ui/pages/add_a_book/add_book_modal_body.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

class const AddBookSheet() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _sheetPanel(
      context,
      child: Column(
        children: [
          _sheetDragHandle(),
          const Expanded(child: AddBookModalBody()),
        ],
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => AddBookSheet(),
    );
  }

  Widget _sheetPanel(BuildContext context, {required Widget child}) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Container(
        decoration: const BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _sheetDragHandle() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: EColors.borderStrong,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}
