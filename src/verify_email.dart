import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

class VerifyEmailPlease extends StatefulWidget {
  @override
  _VerifyEmailPleaseState createState() => _VerifyEmailPleaseState();
}

class _VerifyEmailPleaseState extends State<VerifyEmailPlease> {
  bool _isButtonDisabled = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        // Only update the state if the widget is still in the tree.
        setState(() {
          _isButtonDisabled = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Verify Email"),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await Future.delayed(Duration(milliseconds: 300));
                  appState.signOut();
                  GoRouter.of(context).go('/sign-in');
                },
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //appState.emailVerified
                //    ? Text(
                //        "Thank you! Email verified ✅",
                //        style: TextStyle(fontSize: 24),
                //        textAlign: TextAlign.center,
                //      )
                //    :
                Text(
                  "Please verify your email\n (${appState.email}) \n (check spam folder)",
                  style: TextStyle(fontSize: 24, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isButtonDisabled
                      ? null
                      : () {
                          //appState.refreshLoggedInUser();
                          debugPrint(
                              "hellooo " + appState.emailVerified.toString());
                          appState.signOut(); // Sign out

                          //if (appState.emailVerified && appState.loggedIn)
                          GoRouter.of(context).go('/sign-in');
                        },
                  child: Text('Take me to Login'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
