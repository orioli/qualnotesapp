import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qualnotes/src/widgets/strings.dart';

import 'widgets/widgets.dart';

class AuthFunc extends StatelessWidget {
  const AuthFunc({
    super.key,
    required this.loggedIn,
    required this.signOut,
    this.enableFreeSwag = false,
  });

  final bool loggedIn;
  final void Function() signOut;
  final bool enableFreeSwag;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 8,
            top: 8,
            bottom: 8,
            right: 8,
          ),
          child: StyledButton(
              onPressed: () {
                !loggedIn ? context.push('/sign-in') : signOut();
              },
              child: !loggedIn
                  ? const Text(Strings.signIn)
                  : const Text(Strings.logout)),
        ),
        Visibility(
            visible: loggedIn,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: StyledButton(
                  onPressed: () {
                    context.push('/profile');
                  },
                  child: const Text(Strings.profile)),
            )),
        Visibility(
            visible: enableFreeSwag,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: StyledButton(
                  onPressed: () {
                    throw Exception('free swag unimplemented');
                  },
                  child: const Text(Strings.freeSwag)),
            )),
      ],
    );
  }
}
