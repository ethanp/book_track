import 'package:flutter/material.dart';

void main() {
  runApp(const RootAppWidget());
}

class RootAppWidget extends StatefulWidget {
  const RootAppWidget({super.key});

  @override
  State<RootAppWidget> createState() => _RootAppWidgetState();
}

class _RootAppWidgetState extends State<RootAppWidget> {
  int _currentBottomBarIdx = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The app itself',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('= Book = Track ='),
          backgroundColor: Color.lerp(
            Colors.lightGreen,
            Colors.grey[300],
            0.8,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: currentUi(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => print('hello'),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add),
                Text(
                  'Add book',
                  style: TextStyle(fontSize: 8),
                )
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (idx) => setState(() => _currentBottomBarIdx = idx),
          currentIndex: _currentBottomBarIdx,
          backgroundColor: Color.lerp(
            Colors.lightGreen,
            Colors.grey[100],
            .92,
          ),
          selectedItemColor: Colors.black,
          selectedFontSize: 18,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Session',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ssid_chart),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }

  Widget currentUi() {
    switch (_currentBottomBarIdx) {
      case 0:
        return SessionUi();
      case 1:
        return Text('hello');
      default:
        return Text('Error happened, unknown UI $_currentBottomBarIdx');
    }
  }
}

class SessionUi extends StatelessWidget {
  const SessionUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('Resume reading', style: TextStyle(fontSize: 40)),
      Expanded(
        child: ListView(children: [
          ListTile(
            title: Text('Electronics for Dummies'),
            subtitle: Text('Gen X hacker'),
            leading: Icon(Icons.question_mark),
          ),
          ListTile(
            title: Text('Rich Dad FIRE'),
            subtitle: Text('Robert Kiyosaki'),
            leading: Icon(Icons.question_mark),
            trailing: SizedBox(
              width: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(children: [
                        Container(
                          height: 12,
                          width: 74,
                          color: Colors.green,
                          padding: EdgeInsets.zero,
                        ),
                        Container(
                          height: 12,
                          width: 24,
                          color: Colors.orange,
                        ),
                      ]),
                    ),
                  ),
                  Text('75%'),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text('Book 3 title'),
            subtitle: Text('Author 3 Name'),
            leading: Icon(Icons.question_mark),
          ),
        ]),
      )
    ]);
  }
}
