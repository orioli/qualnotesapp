// Copyright 2023 Jose Berengueres. Qualnotes AB

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';
import 'package:qualnotes/src/widgets/strings.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Remove padding
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Consumer<ApplicationState>(
              builder: (context, appState, _) {
                return Text(appState.displayName ?? '');
              },
            ),
            accountEmail: Consumer<ApplicationState>(
              builder: (context, appState, _) {
                return Text(appState.email ?? '');
              },
            ),
            // ...
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: Image.asset(
                  'assets/images/icon.jpg',
                  fit: BoxFit.cover,
                  width: 90,
                  height: 90,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage('assets/images/bg4.jpg'),
              ),
            ),
          ),
          /*ListTile(
            leading: Icon(Icons.person),
            title: Text(Strings.account),
            onTap: () => GoRouter.of(context).go('/profile'),
          ),*/
          ListTile(
            leading: Icon(
              Icons.person_off,
              color: Colors.red,
            ),
            title: Text(
              "Delete account\n(cannot be undone)",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => GoRouter.of(context).go('/profile'),
          ),
          ListTile(
            leading: Icon(Icons.person_3),
            title: Text(Strings.account),
            onTap: () => GoRouter.of(context).go('/account'),
          ),
          ListTile(
            leading: Icon(Icons.qr_code_scanner),
            title: Text("Join a project"),
            onTap: () => GoRouter.of(context).go('/scanner'),
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text(Strings.policies),
            onTap: () => GoRouter.of(context).go('/privacy-policy'),
          ),
          Divider(),
          Consumer<ApplicationState>(
            builder: (context, appState, _) {
              return ListTile(
                title: Text(Strings.exit),
                leading: Icon(Icons.exit_to_app),
                onTap: () {
                  appState.signOut();
                  context.go('/sign-in');
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
