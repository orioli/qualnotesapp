import 'package:flutter/material.dart';

import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/widgets/widgets.dart';
import '../app_state.dart';

class NotWhitelistedScreen extends StatefulWidget {
  final String? email;

  NotWhitelistedScreen({this.email});

  @override
  _NotWhitelistedScreenState createState() => _NotWhitelistedScreenState();
}

class _NotWhitelistedScreenState extends State<NotWhitelistedScreen> {
  bool showProgressIndicator = true;
  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 1300), () {
      setState(() {
        showProgressIndicator = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Visibility(
          visible: showProgressIndicator,
          child: CircularProgressIndicator(),
          replacement: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Paragraph(
                'Hi! The email you provided *** ${widget.email} *** belongs to an organization that has not been approved yet, to enrol your organization email us at info@qualnotes.com',
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Provider.of<ApplicationState>(context, listen: false)
                      .signOut();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    GoRouter.of(context).go('/sign-in');
                  });
                },
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
