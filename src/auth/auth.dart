import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Auth extends ChangeNotifier {
  var _isLoggedIn = false;
  var _isEmailVerified = false;
  String? _displayName;
  String? _userId;
  String? _email;
  DateTime? _creationTime;
  DateTime? _lastSignInTime;

  bool get isLoggedIn => _isLoggedIn;
  bool get isEmailVerified => _isEmailVerified;
  String? get userId => _userId;
  String? get displayName => _displayName;
  String? get email => _email;
  DateTime? get creationTime => _creationTime;
  DateTime? get lastSignInTime => _lastSignInTime;

  // Create a StreamController for emailVerified
  final _emailVerifiedController = StreamController<bool>.broadcast();
  // The getter for the stream
  Stream<bool> get emailVerifiedStream => _emailVerifiedController.stream;
  set isEmailVerified(bool value) {
    _isEmailVerified = value;
    notifyListeners();
  }

  late StreamSubscription<User?> _authStateChanges;

  Auth() {
    _authStateChanges =
        FirebaseAuth.instance.userChanges().listen((User? user) async {
      if (user == null) {
        _isLoggedIn = false;
        _isEmailVerified = false;
        _userId = null;
        _displayName = null;
        _email = null;
        _creationTime = null;
      } else {
        _isLoggedIn = true;
        _isEmailVerified = user.emailVerified;
        _userId = user.uid;
        _displayName = user.displayName;
        _email = user.email;
        _creationTime = user.metadata.creationTime;
        _lastSignInTime = user.metadata.lastSignInTime;

        // Adding value to the stream
        // _emailVerifiedController.add(user.emailVerified);
        //_planType = "not defined";
      }
      notifyListeners();
    });
  }

  void delete() {
    FirebaseAuth.instance.currentUser!.delete();
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<void> refreshLoggedInUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
  }

/*
  Future<void> refreshLoggedInUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      // After calling reload, get a new instance of the current user
      // and check the updated emailVerified status.
      currentUser = FirebaseAuth.instance.currentUser;
      // Wait for a second to give Firebase time to update the emailVerified status
      await Future.delayed(Duration(seconds: 2));
      if (currentUser != null && currentUser.emailVerified) {
        this.isEmailVerified = currentUser.emailVerified;
      }
/*
        if (_isEmailVerified) {
          // becuase firebase rules
      }
      */
    }
  }
*/
  @override
  void dispose() {
    _authStateChanges.cancel();
    _emailVerifiedController
        .close(); // Don't forget to close the StreamController

    super.dispose();
  }
}
