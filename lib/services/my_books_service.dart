import 'package:book_track/data_model.dart';

class MyBooksService {
  static List<BookProgress> all() {
    // One decent book api option is https://hardcover.app/account/api?referrer_id=15017
    // The other decent one I've found is https://openlibrary.org/dev/docs/api/books
    //    Nice thing about this one is it doesn't require any authentication
    // Google would probably work fine too https://developers.google.com/books/docs/v1/using
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
