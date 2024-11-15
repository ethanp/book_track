import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/add_book_page.dart';
import 'package:book_track/ui/login_page.dart';
import 'package:book_track/ui/my_bottom_nav_bar.dart';
import 'package:book_track/ui/reading_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// During development, it may be important to get the generators going via
/// `dart run build_runner watch` as recommended on the riverpod
/// getting-started docs: https://riverpod.dev/docs/introduction/getting_started.
Future<void> main() async {
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );
  runApp(ProviderScope(child: const Outermost()));
}

final supabase = Supabase.instance.client;

class Outermost extends StatelessWidget {
  const Outermost({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The app itself',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : RootAppWidget(),
    );
  }
}

class RootAppWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int curIdx = ref.watch(selectedBottomBarIdxProvider);
    return switch (curIdx) {
      0 => RenameWidget(),
      _ => Scaffold(
          body: Text('Unimplemented error'),
          bottomNavigationBar: MyBottomNavBar(),
        ),
    };
  }
}

class RenameWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('= Book = Track ='),
        backgroundColor: Color.lerp(Colors.lightGreen, Colors.grey[300], 0.8),
        actions: [signOutButton(context)],
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        color: Color.lerp(Colors.yellow, Colors.grey[100], .98),
        child: sessionUi(),
      ),
      floatingActionButton: addBookFab(context),
      bottomNavigationBar: MyBottomNavBar(),
    );
  }

  TextButton signOutButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        try {
          await supabase.auth.signOut();
        } on AuthException catch (error) {
          if (context.mounted) {
            context.showSnackBar(error.message, isError: true);
          }
        } catch (error) {
          if (context.mounted) {
            context.showSnackBar(
              'Unexpected error occurred: $error',
              isError: true,
            );
          }
        } finally {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
        }
      },
      child: const Text('Sign Out'),
    );
  }

  Widget addBookFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AddBookPage()),
      ),
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
    );
  }

  Widget sessionUi() {
    final List<BookProgress> books = [
      BookProgress(
        Book(
          'Electronics for Dummies',
          'Gen X hacker',
          2019,
          BookType.paperback,
          960,
          null,
        ),
        DateTime(2024),
        ProgressHistory([
          ProgressEvent(DateTime.now(), 74),
        ]),
      ),
      BookProgress(
        Book(
          'Rich Dad FIRE',
          'Robert Kiyosaki',
          2002,
          BookType.audiobook,
          100,
          null,
        ),
        DateTime(2024),
        ProgressHistory([
          ProgressEvent(DateTime.now(), 95),
        ]),
      ),
      BookProgress(
        Book(
          'Book 3',
          'Book 3 Author',
          2042,
          BookType.paperback,
          124,
          null,
        ),
        DateTime(2024),
        ProgressHistory([
          ProgressEvent(DateTime.now(), 2),
        ]),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resume reading',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        Expanded(
          child: ListView(
            children: books
                .map(
                  (book) => ListTile(
                    title: Text(book.book.title),
                    subtitle: Text(book.book.author),
                    leading: Icon(Icons.question_mark),
                    trailing: ReadingProgressIndicator(
                      progressPercent:
                          book.progressHistory.progressEvents.last.progress,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
