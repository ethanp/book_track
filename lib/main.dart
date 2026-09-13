import 'dart:async';

import 'package:book_track/app_identity.dart';
import 'package:book_track/sync/sync_config.dart';
import 'package:book_track/ui/common/mainstage_and_bottom_navbar.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _logger = ELogger('BookTrackMain');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installAppLogCapture();
  await loadAppDotEnv();

  if (!DotEnvSyncBootstrap.isConfigured()) {
    throw StateError(
      'Set POWERSYNC_JWT_SECRET and SERVER_HOST_LAN or '
      'SERVER_HOST_TAILSCALE in .env '
      '(ethan_sync is required for local storage).',
    );
  }

  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      syncConfigProvider.overrideWith(
        (ref) => buildBookTrackSyncConfig(preferences),
      ),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TopLevelWidget(),
    ),
  );
  unawaited(_startSync(container));
}

Future<void> _startSync(ProviderContainer container) async {
  try {
    await SyncLifecycle.start(container);
    _logger.fine('ethan_sync started');
  } catch (error, stackTrace) {
    _logger.error('ethan_sync failed to start', error, stackTrace);
  }
}

class const TopLevelWidget() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppIdentity.displayName,
      debugShowCheckedModeBanner: false,
      theme: ETheme.material3Dark,
      home: MainstageAndBottomNavbar(),
    );
  }
}
