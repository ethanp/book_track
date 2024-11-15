import 'package:flutter/material.dart';

class AddBookPage extends StatelessWidget {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Add a book'),
          backgroundColor: Color.lerp(
            Colors.lightGreen,
            Colors.grey[300],
            0.8,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Flexible(
                child: Row(
                  children: [
                    Text('Search',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(width: 20),
                    Flexible(
                      child: TextFormField(
                        controller: _textEditingController,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
