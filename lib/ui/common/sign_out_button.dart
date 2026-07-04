import 'package:book_track/services/supabase_auth_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/login/login_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';

const _log = ELogger('SignOutButton');

class SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () async {
        try {
          await SupabaseAuthService.signOut();
        } catch (error) {
          _log.error('Unexpected error occurred: $error');
        } finally {
          if (context.mounted) context.pushReplacementPage(const LoginPage());
        }
      },
      child: const Text(
        'Sign Out',
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
