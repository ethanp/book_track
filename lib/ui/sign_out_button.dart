import 'package:book_track/extensions.dart';
import 'package:book_track/main.dart';
import 'package:book_track/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';

class SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        try {
          await supabase.auth.signOut();
        } catch (error) {
          if (context.mounted) context.authError(error);
        } finally {
          if (context.mounted) context.pushReplacementPage(const LoginPage());
        }
      },
      child: const Text('Sign Out'),
    );
  }
}
