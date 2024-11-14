import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
  );
  runApp(const Outermost());
}

final supabase = Supabase.instance.client;

class Outermost extends StatelessWidget {
  const Outermost({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The app itself',
      theme: ThemeData(useMaterial3: true),
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : RootAppWidget(),
    );
  }
}

class RootAppWidget extends StatefulWidget {
  const RootAppWidget({super.key});

  @override
  State<RootAppWidget> createState() => _RootAppWidgetState();
}

class _RootAppWidgetState extends State<RootAppWidget> {
  int _currentBottomBarIdx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('= Book = Track ='),
        backgroundColor: Color.lerp(
          Colors.lightGreen,
          Colors.grey[300],
          0.8,
        ),
        actions: [
          TextButton(
              onPressed: () async {
                try {
                  await supabase.auth.signOut();
                } on AuthException catch (error) {
                  if (mounted) {
                    context.showSnackBar(error.message, isError: true);
                  }
                } catch (error) {
                  if (mounted) {
                    context.showSnackBar('Unexpected error occurred',
                        isError: true);
                  }
                } finally {
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }
                }
              },
              child: const Text('Sign Out'))
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        color: Color.lerp(Colors.yellow, Colors.grey[100], .98),
        child: currentUi(),
      ),
      floatingActionButton: currentFab(),
      bottomNavigationBar: bottomNav(),
    );
  }

  Widget bottomNav() {
    return BottomNavigationBar(
      onTap: (idx) => setState(() => _currentBottomBarIdx = idx),
      currentIndex: _currentBottomBarIdx,
      backgroundColor: Color.lerp(Colors.lightGreen, Colors.grey[100], .92),
      selectedItemColor: Colors.black,
      selectedFontSize: 18,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Session',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.ssid_chart),
          label: 'Progress',
        ),
      ],
    );
  }

  Widget? currentFab() {
    switch (_currentBottomBarIdx) {
      case 0:
        return FloatingActionButton(
          onPressed: () => print('hello'),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add),
                Text(
                  'Add book',
                  style: TextStyle(fontSize: 8),
                )
              ],
            ),
          ),
        );
      default:
        return null;
    }
  }

  Widget currentUi() {
    switch (_currentBottomBarIdx) {
      case 0:
        return sessionUi();
      case 1:
        return Text('hello');
      default:
        return Text('Error happened, unknown UI $_currentBottomBarIdx');
    }
  }

  Widget sessionUi() {
    return Column(children: [
      Text('Resume reading', style: TextStyle(fontSize: 40)),
      Expanded(
        child: ListView(children: [
          ListTile(
            title: Text('Electronics for Dummies'),
            subtitle: Text('Gen X hacker'),
            leading: Icon(Icons.question_mark),
          ),
          ListTile(
            title: Text('Rich Dad FIRE'),
            subtitle: Text('Robert Kiyosaki'),
            leading: Icon(Icons.question_mark),
            trailing: SizedBox(
              width: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(children: [
                        Container(
                          height: 12,
                          width: 74,
                          color: Colors.green,
                          padding: EdgeInsets.zero,
                        ),
                        Container(
                          height: 12,
                          width: 24,
                          color: Colors.orange,
                        ),
                      ]),
                    ),
                  ),
                  Text('75%'),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text('Book 3 title'),
            subtitle: Text('Author 3 Name'),
            leading: Icon(Icons.question_mark),
          ),
        ]),
      )
    ]);
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      if (mounted) {
        context.showSnackBar('Check your email for a login link!');

        _emailController.clear();
      }
    } on AuthException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        if (_redirecting) return;
        final session = data.session;
        if (session != null) {
          _redirecting = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Outermost()),
          );
        }
      },
      onError: (error) => context.showSnackBar(
          error is AuthException
              ? error.message
              : 'Unexpected error occurred: $error',
          isError: true),
    );
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Sign in via the magic link with your email below'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            child: Text(_isLoading ? 'Sending...' : 'Send Magic Link'),
          ),
        ],
      ),
    );
  }
}
