import 'dart:async';

import 'package:book_track/services/supabase_auth_service.dart';
import 'package:book_track/ui/common/mainstage_and_bottom_navbar.dart';
import 'package:book_track/ui/pages/login/login_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// During development, it is important to get the generators going via
/// `dart run build_runner watch` as recommended on the riverpod
/// getting-started docs: https://riverpod.dev/docs/introduction/getting_started.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );
  runApp(ProviderScope(child: const TopLevelWidget()));
}

class TopLevelWidget extends ConsumerStatefulWidget {
  const TopLevelWidget({super.key});

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
      title: 'The app itself',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        // Always use light mode (for now, for simplicity).
        brightness: Brightness.light,
      ),
      home: SupabaseAuthService.isLoggedOut
          ? const LoginPage()
          : MainstageAndBottomNavbar(),
    );
  }
}
