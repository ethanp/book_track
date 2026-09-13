import 'package:book_track/sync/library_repository.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryRepositoryProvider = FutureProvider<LibraryRepository>((
  ref,
) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return LibraryRepository(database);
});
