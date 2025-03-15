import 'package:flutter/cupertino.dart';

class StatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Stats'),
      ),
      // TODO(feature): Show all book progress at once using the
      //  BooksProgressChart widget
      child: Text('Stats page does not exist yet'),
    );
  }
}
