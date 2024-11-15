import 'package:book_track/data_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBooksService {
  static List<BookProgress> all() {
    return [
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
  }
}

abstract class BookRepository {
  List<Book> booksForUser(User user);
}
