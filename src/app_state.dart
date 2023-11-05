import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qualnotes/src/auth/auth.dart';
import 'package:qualnotes/src/project/setup/project_stepper.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum Attending { yes, no, unknown }

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  String? _projectTitle;
  Auth _auth = Auth();

  bool _isImagePickingInProgress = false;

  bool get isImagePickingInProgress => _isImagePickingInProgress;

  set isImagePickingInProgress(bool value) {
    _isImagePickingInProgress = value;
    notifyListeners();
  }

  // String? _planType;

  bool get loggedIn => _auth.isLoggedIn;
  bool get emailVerified => _auth.isEmailVerified;
  String? get userId => _auth.userId;
  String? get displayName => _auth.displayName;
  String? get email => _auth.email;
  DateTime? get creationTime => _auth.creationTime;
  DateTime? get lastSignInTime => _auth.lastSignInTime;
  //String? get planType => _planType;
  bool get isOnline => _isOnline;

  int isFileUploading = 0;
  bool isFileUploadingError = false;
  bool isSignLoading = false;
  bool uploading_title = false;
  bool deleting = false;
  bool imageLoader = false;
  bool _isOnline = true;

  bool _enableFreeSwag = defaultValues['enable_free_swag'] as bool;
  final _firebaseStorage = FirebaseStorage.instance;
  List interviewList = [];
  bool get enableFreeSwag => _enableFreeSwag;
  String _eventDate = defaultValues['event_date'] as String;
  String get eventDate => _eventDate;
  String _callToAction = defaultValues['call_to_action'] as String;
  String get callToAction => _callToAction;

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> get questions => _questions;
  set questions(List<Map<String, dynamic>> value) {
    _questions = value;
  }

  // ignore: unused_field
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  void init() async {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result == ConnectivityResult.none) {
        _isOnline = false;
        debugPrint("_isonline set to false");
      } else {
        _isOnline = true;
        if (!_auth.isLoggedIn) {
          await configureFirebaseUIAuth();
        }
        if (_auth.isLoggedIn) {
          //_fetchPlanType();
        }
      }
      debugPrint(" _isOnline" + _isOnline.toString());
      notifyListeners();
    });
    // Checking the initial connectivity status
    var result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    if (_isOnline) {
      await configureFirebaseUIAuth();
      //_fetchPlanType();
    }
  }

  deleteUser() {
    _auth.delete();
  }

  Future<void> configureFirebaseUIAuth() async {
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);
  }

/*
  Future<void> _fetchPlanType() async {
    try {
      // Fetch plan type from Firestore only when the email is verified
      DocumentSnapshot<Map<String, dynamic>> planDoc = await FirebaseFirestore
          .instance
          .collection('paid_plan')
          .doc(_auth.userId)
          .get();
      if (planDoc.exists) {
        _planType = planDoc.data()?['planType'];
      } else {
        _planType = "Free";
      }
    } catch (e) {
      print("Error fetching plan type: $e");
      print("user id is: " + _auth.userId.toString());
      _planType = "Free";
    }
  }
*/

  static Map<String, dynamic> defaultValues = <String, dynamic>{
    'event_date': 'October 18, 2022',
    'enable_free_swag': false,
    'call_to_action': 'Join us for a day full of Firebase Workshops and Pizza!',
  };

  @override
  void dispose() {
    _connectivitySubscription?.cancel();

    super.dispose();
  }

  Future<void> refreshLoggedInUser() => _auth.refreshLoggedInUser();

  Future<void> addScheduleImage(String prj_id, String sch_id, List questions,
      int index, File file) async {
    if (!loggedIn) {
      throw Exception('Must be logged in to add project');
    }
    try {
      imageLoader = true;
      notifyListeners();
      final userId = _auth.userId;
      final snapshot = await _firebaseStorage
          .ref()
          .child(
              '/user/$userId/${file.path.substring(file.path.lastIndexOf('/') + 1).replaceAll(RegExp('[^A-Za-z0-9]'), '')}')
          .putFile(file);

      await snapshot.ref.getDownloadURL().then((value) {
        final data = questions[index]['text'];
        questions.removeAt(index);
        questions.insert(index, {"image": value, "text": data});
      });
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(prj_id)
          .collection('collected-data')
          .doc(sch_id)
          .update({"questions": questions});
    } finally {
      imageLoader = false;
      notifyListeners();
    }
  }

  String? get projectTitle => _projectTitle;

  void setProjectTitle(String title) {
    _projectTitle = title;
    notifyListeners();
  }

  Future<DocumentReference> addProject(String title) {
    if (!loggedIn) {
      throw Exception('Must be logged in to add project');
    }
    _projectTitle = title; // Store the project title in the provider state
    uploading_title = true;
    notifyListeners();
    return FirebaseFirestore.instance
        .collection('projects')
        .add(<String, dynamic>{
      'contributors': '',
      'setup_step': 0,
      'title': title,
      'creationtimestamp': DateTime.now().millisecondsSinceEpoch,
      'owner_name': _auth.displayName,
      'owner_id': _auth.userId,
      'active': true,
    }).then((value) {
      uploading_title = false;
      notifyListeners();
      return value;
    });
  }

// comon function tto add map or schedule
  Future<DocumentReference> addMap(String prj_id, String title) =>
      _addMapOrSchOrWalkingMap(prj_id, title, 'map');

  Future<DocumentReference> addSchedule(String prj_id, String title) =>
      _addMapOrSchOrWalkingMap(prj_id, title, 'schedule');

  Future<DocumentReference> addWalkingMap(String prj_id, String title) =>
      _addMapOrSchOrWalkingMap(prj_id, title, 'walkingmap');

  Future<DocumentReference> addParticipantObservation(
          String prj_id, String title) =>
      _addMapOrSchOrWalkingMap(prj_id, title, 'participantobservation');

  Future<DocumentReference> _addMapOrSchOrWalkingMap(
      String prj_id, String title, String type) {
    if (!loggedIn) {
      throw Exception('Must be logged in to add project');
    }
    uploading_title = true;
    notifyListeners();
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(prj_id)
        .collection('collected-data')
        .add(<String, dynamic>{
      'title': title,
      'type': type,
      'creation_timestamp': FieldValue.serverTimestamp(),
      //'creation_timestamp': DateTime.now().millisecondsSinceEpoch,

      'owner_id': _auth.userId,
    }).then((value) {
      uploading_title = false;
      notifyListeners();
      return value;
    });
  }

  void signOut() => _auth.signOut();

  Future<DocumentReference<Map<String, dynamic>>?> addInterview(
      String prj_id,
      String title,
      File file,
      Map<String, dynamic> jsontimestampedQuestions) async {
    if (!loggedIn) {
      throw Exception('Must be logged in to add project');
    }
    DocumentReference<Map<String, dynamic>>? data;
    Map<String, dynamic> namesAndUrlsWithoutDot = {};
    try {
      uploading_title = true;
      notifyListeners();
      final userId = _auth.userId;
      final snapshot = await _firebaseStorage
          .ref()
          .child(
              '/user/$userId/${file.path.substring(file.path.lastIndexOf('/') + 1).replaceAll(RegExp('[^A-Za-z0-9]'), '')}')
          .putFile(file);

      await snapshot.ref.getDownloadURL().then((value) {
        namesAndUrlsWithoutDot.addAll({
          'title': title,
          'creation_timestamp': FieldValue.serverTimestamp(),
          'type': 'interview',
          'recording': value
        });

        if (jsontimestampedQuestions.isNotEmpty) {
          namesAndUrlsWithoutDot.addEntries(jsontimestampedQuestions.entries);
        }
      });
      data = await FirebaseFirestore.instance
          .collection('projects')
          .doc(prj_id)
          .collection('collected-data')
          .add(namesAndUrlsWithoutDot);
    } catch (e) {
      print(e);
    } finally {
      uploading_title = false;
      notifyListeners();
    }
    return data;
  }

  Future<void> addScheduleQuestions({
    required String prj_id,
    required String schedule_id,
    required List questions,
  }) async {
    if (!loggedIn) {
      throw Exception('Must be logged in to add project');
    }
    //debugPrint('******** Adding schedule questions...');

    uploading_title = true; // TODO: change this to uplaoding questions.
    notifyListeners();
    final doc = FirebaseFirestore.instance
        .collection('projects')
        .doc(prj_id)
        .collection('collected-data')
        .doc(schedule_id);
    try {
      //debugPrint('******** before await ...');

      await doc.update({'questions': questions});
      //debugPrint('******** aft await ...');
    } catch (e) {
      debugPrint('Exception adding schedule questions: $e');
    } finally {
      //debugPrint('******** finally  ...');
      uploading_title = false;
      notifyListeners();
    }
  }

  Future<void> deleteScheduleOrMap({
    required String requestor_id,
    required String prj_id,
    required String doc_id,
  }) async {
    if (!loggedIn) {
      throw Exception('Must be logged in to add project');
    }
    deleting = true;
    notifyListeners();

    // Get the project document
    DocumentSnapshot projectDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(prj_id)
        .get();

    String prjOwnerId = projectDoc.get('owner_id');

    // Get the schedule or map document
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(prj_id)
        .collection('collected-data')
        .doc(doc_id)
        .get();

    String docOwnerId = doc.get('owner_id');

    try {
      if (requestor_id == prjOwnerId || requestor_id == docOwnerId) {
        await doc.reference.delete();
      } else {
        debugPrint(
            "*** Delete try denied...  $requestor_id is not owner of $doc_id (owned by $docOwnerId );  nor owner of project: $prj_id (owned by $prjOwnerId)");
      }
    } catch (e) {
      print("Error deleting document: $e");
    } finally {
      deleting = false;
      notifyListeners();
    }
  }

  Future<void> addQuestionsTimeStamp({
    required String prj_id,
    required String schedule_id,
    required List questions,
  }) async {
    if (!loggedIn) {
      throw Exception('Must be logged in to add project');
    }
    uploading_title = true;
    notifyListeners();
    final doc = FirebaseFirestore.instance
        .collection('projects')
        .doc(prj_id)
        .collection('collected-data')
        .doc(schedule_id);
    try {
      await doc.update({'questions': questions});
    } catch (e) {
    } finally {
      uploading_title = false;
      notifyListeners();
    }
  }

  Future<void> submitDataToFirebase({
    required int index,
    required String docId,
    required List fileList,
  }) async {
    List<String> data = [];
    try {
      isFileUploading = index;
      isFileUploadingError = false;
      notifyListeners();
      Map<String, dynamic> namesAndUrls = {};
      Map<String, dynamic> namesAndUrlsWithoutDot = {};

      for (File file in fileList) {
        final userId = _auth.userId;
        UploadTask snapshot = _firebaseStorage
            .ref()
            .child(
                '/user/$userId/${file.path.substring(file.path.lastIndexOf('/') + 1).replaceAll(RegExp('[^A-Za-z0-9]'), '')}')
            .putFile(file);

        snapshot.snapshotEvents.listen((event) async {
          if (event.state.name == 'success') {
            await snapshot.snapshot.ref.getDownloadURL().then((value) {
              data.add(value);
              namesAndUrls.addAll({
                (index == 1
                    ? "info_statement"
                    : index == 2
                        ? "consent_form"
                        : "files"): index == 3 ? data : value,
              });
              namesAndUrlsWithoutDot.addAll({
                (index == 1
                    ? "info_statement"
                    : index == 2
                        ? "consent_form"
                        : "files"): index == 3 ? data : value,
              });
            });
            await FirebaseFirestore.instance
                .collection('/projects/')
                .doc(docId)
                .get()
                .then((doc) async {
              if (doc.exists) {
                await FirebaseFirestore.instance
                    .collection('/projects/')
                    .doc(docId)
                    .update(namesAndUrls)
                    .then((value) {
                  if (index == 1) {
                    Directories().filesListFirst = [];
                  } else if (index == 2) {
                    Directories().filesListSec = [];
                  } else if (index == 3) {
                    Directories().filesListThird = [];
                  }
                });

                isFileUploading = 0;
                notifyListeners();
              } else {
                await FirebaseFirestore.instance
                    .collection('/projects/')
                    .doc(docId)
                    .set(
                      namesAndUrlsWithoutDot,
                    )
                    .then((value) {
                  if (index == 1) {
                    Directories().filesListFirst = [];
                  } else if (index == 2) {
                    Directories().filesListSec = [];
                  } else if (index == 3) {
                    Directories().filesListThird = [];
                  }
                });

                isFileUploading = 0;
                notifyListeners();
              }
            });
          }
        });
        await snapshot.catchError((error, stackTrace) {
          isFileUploading = 0;
          isFileUploadingError = true;
          notifyListeners();
          return Future.error(error);
        });
      }
    } catch (e) {
      isFileUploading = 0;
      notifyListeners();
    }
  }

  Future<void> submitFormDataToFirebase({
    required String docId,
    required String name,
    required String email,
    required BuildContext context,
    required File file,
  }) async {
    List<String> data = [];
    try {
      isSignLoading = true;
      isFileUploadingError = false;
      notifyListeners();
      Map<String, dynamic> namesAndUrls = {};
      Map<String, dynamic> namesAndUrlsWithoutDot = {};
      final userId = _auth.userId;

      UploadTask snapshot = _firebaseStorage
          .ref()
          .child(
              '/user/$userId/${file.path.substring(file.path.lastIndexOf('/') + 1).replaceAll(RegExp('[^A-Za-z0-9]'), '')}')
          .putFile(file);

      snapshot.snapshotEvents.listen((event) async {
        if (event.state.name == 'success') {
          await snapshot.snapshot.ref.getDownloadURL().then((value) {
            data.add(value);
            namesAndUrls
                .addAll({'name': name, 'email': email, 'signature': value});
            namesAndUrlsWithoutDot
                .addAll({'name': name, 'email': email, 'signature': value});
          });
          await FirebaseFirestore.instance
              .collection('/projects/')
              .doc(docId)
              .collection('obtained_consents')
              .doc()
              .get()
              .then((doc) async {
            if (doc.exists) {
              await FirebaseFirestore.instance
                  .collection('/projects/')
                  .doc(docId)
                  .update(namesAndUrls);

              isSignLoading = false;
              notifyListeners();
              context.pop();
            } else {
              await FirebaseFirestore.instance
                  .collection('/projects/')
                  .doc(docId)
                  .collection('obtained_consents')
                  .doc()
                  .set(
                    namesAndUrlsWithoutDot,
                  )
                  .whenComplete(() {
                isSignLoading = false;
                notifyListeners();
              });
            }
          });
        }
      });
      await snapshot.catchError((error, stackTrace) {
        isSignLoading = false;
        isFileUploadingError = true;
        notifyListeners();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(Strings.dataHasNotBeenSaved)));
        return Future.error(error);
      });
    } catch (e) {
      isSignLoading = false;
      notifyListeners();
    }
  }
}
