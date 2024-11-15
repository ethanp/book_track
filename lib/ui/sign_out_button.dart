import 'package:book_track/extensions.dart';
import 'package:book_track/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';

class SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}
