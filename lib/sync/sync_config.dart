import 'package:book_track/app_identity.dart';
import 'package:book_track/sync/powersync_schema.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _log = ELogger('BookTrackSync');

const _fkDependencies = <String, Set<String>>{
  'books': {},
  'library_books': {'books'},
  'library_book_formats': {'library_books'},
  'progress_events': {'library_books', 'library_book_formats'},
};

SyncConfig buildBookTrackSyncConfig(SharedPreferences preferences) {
  return DotEnvSyncBootstrap.build(
    preferences: preferences,
    appName: AppIdentity.syncAppName,
    powersyncPort: 8087,
    postgrestPort: 3010,
    schema: bookTrackSchema,
    upload: UploadSettings(
      strategy: TieredBatchUploadStrategy(dependencies: _fkDependencies),
    ),
    onSyncError: _log.warn,
  );
}
