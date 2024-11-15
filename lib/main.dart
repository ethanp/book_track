import 'dart:async';

import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/my_bottom_nav_bar.dart';
import 'package:book_track/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// During development, it is important to get the generators going via
/// `dart run build_runner watch` as recommended on the riverpod
/// getting-started docs: https://riverpod.dev/docs/introduction/getting_started.
Future<void> main() async {
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );
  runApp(ProviderScope(child: const WholeAppWidget()));
}

final supabase = Supabase.instance.client;

class WholeAppWidget extends ConsumerWidget {
  const WholeAppWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedIdx = ref.watch(selectedBottomBarIdxProvider);
    return MaterialApp(
      title: 'The app itself',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : MyBottomNavBar.elements[selectedIdx].page,
    );
  }
}
