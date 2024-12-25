import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/services/supabase_auth_service.dart';
import 'package:book_track/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';

class SignOutButton extends StatelessWidget {
  static final SimpleLogger log = SimpleLogger(prefix: 'SignOutButton');

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        try {
          await SupabaseAuthService.signOut();
        } catch (error) {
          log('Unexpected error occurred: $error', error: true);
        } finally {
          if (context.mounted) context.pushReplacementPage(const LoginPage());
        }
      },
      child: Text(
        'Sign Out',
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
      ),
    );
  }
}
