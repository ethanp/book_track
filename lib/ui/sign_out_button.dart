import 'package:book_track/extensions.dart';
import 'package:book_track/main.dart';
import 'package:book_track/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        try {
          await supabase.auth.signOut();
        } catch (error) {
          final String message = error is AuthException
              ? error.message
              : 'Unexpected error occurred: $error';
          if (context.mounted) context.showSnackBar(message, isError: true);
        } finally {
          if (context.mounted) context.pushReplacementPage(const LoginPage());
        }
      },
      child: const Text('Sign Out'),
    );
  }
}
