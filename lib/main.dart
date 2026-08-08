import 'dart:async';

import 'package:book_track/services/supabase_auth_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/mainstage_and_bottom_navbar.dart';
import 'package:book_track/ui/pages/login/login_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// During development, it is important to get the generators going via
/// `dart run build_runner watch` as recommended on the riverpod
/// getting-started docs: https://riverpod.dev/docs/introduction/getting_started.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installAppLogCapture();
  await loadAppDotEnv(isOptional: false);
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );
  runApp(ProviderScope(child: const TopLevelWidget()));
}

class TopLevelWidget extends ConsumerStatefulWidget {
  const TopLevelWidget();

  @override
  ConsumerState<TopLevelWidget> createState() => _TopLevelWidgetState();
}

class _TopLevelWidgetState extends ConsumerState<TopLevelWidget> {
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = SupabaseAuthService.onAuthStateChange(
      onEvent: (AuthState state) {
        // Force a rebuild when auth state changes
        setState(() {});
      },
      onError: (Object error) {
        // Log the error, but don't prevent the app from trying to render
        print('Auth state change error: $error');
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Book Track',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        barBackgroundColor: AppColors.navBarBackground,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primary,
          textStyle: const TextStyle(
            inherit: false,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          navTitleTextStyle: const TextStyle(
            inherit: false,
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: const TextStyle(
            inherit: false,
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (SupabaseAuthService.isLoggedOut) {
      return const LoginPage();
    }

    return MainstageAndBottomNavbar();
  }
}
