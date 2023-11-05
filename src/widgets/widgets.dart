// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Header extends StatelessWidget {
  const Header(this.heading, {super.key});
  final String heading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          heading,
          style: const TextStyle(fontSize: 24),
        ),
      );
}

class InterviewTitle extends StatelessWidget {
  const InterviewTitle(this.content, {super.key});
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          content,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      );
}

class InterviewDetailItem extends StatelessWidget {
  const InterviewDetailItem(this.content, {super.key});
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          content,
          style: const TextStyle(fontSize: 14),
        ),
      );
}

class ParagraphCard extends StatelessWidget {
  const ParagraphCard(this.content, {super.key});
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Text(
          content,
          style: const TextStyle(fontSize: 18),
        ),
      );
}

String cropTextToNCharacters(String text, int n) {
  if (text.length > n) {
    return text.substring(0, n) + "...";
  } else {
    return text;
  }
}

class Paragraph extends StatelessWidget {
  const Paragraph(this.content, {super.key});
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          content,
          overflow: TextOverflow
              .visible, // TextOverflow.visible allows text to overflow its container

          style: const TextStyle(fontSize: 18),
        ),
      );
}

class Paragraph2 extends StatelessWidget {
  const Paragraph2(this.content, {Key? key}) : super(key: key);
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Flexible(
        // or use Expanded based on your layout needs
        child: Text(
          content,
          overflow: TextOverflow.visible,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class ParagraphCropped extends StatelessWidget {
  const ParagraphCropped(this.content, {super.key});
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          cropTextToNCharacters(content, 60),
          style: const TextStyle(fontSize: 18),
        ),
      );
}

class MapEmoji extends StatelessWidget {
  const MapEmoji(this.content, {super.key});
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Text(
          content,
          style: const TextStyle(fontSize: 36),
        ),
      );
}

class IconAndDetailStepper extends StatelessWidget {
  const IconAndDetailStepper(this.icon, this.detail, {super.key});
  final IconData icon;
  final String detail;
  static const double size16 = 16;
  static const Color color = Color.fromARGB(255, 99, 99, 99);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 7),
            Text(
              detail,
              style: const TextStyle(fontSize: size16, color: color),
            )
          ],
        ),
      );
}

class IconAndDetail extends StatelessWidget {
  const IconAndDetail(this.icon, this.detail, {super.key});
  final IconData icon;
  final String detail;
  static const double size18 = 18;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              detail,
              style: const TextStyle(fontSize: size18),
            )
          ],
        ),
      );
}

/*
class StyledButton extends StatelessWidget {
  const StyledButton({required this.child, required this.onPressed, super.key});
  final Widget child;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.deepPurple)),
        onPressed: onPressed,
        child: child,
      );
}
*/
class StyledButton extends StatelessWidget {
  const StyledButton({required this.child, required this.onPressed, super.key});
  final Widget child;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          //side: const BorderSide(color: Colors.deepPurple),
        ),
        onPressed: onPressed,
        child: child,
      );
}

// A function to fetch reflection text from Firestore
Future<String?> getReflection(String prj_id, [String? map_id]) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  DocumentReference docRef;
  if (map_id != null) {
    docRef = firestore
        .collection('projects')
        .doc(prj_id)
        .collection('collected-data')
        .doc(map_id);
  } else {
    docRef = firestore.collection('projects').doc(prj_id);
  }

  DocumentSnapshot docSnapshot = await docRef.get();

  return docSnapshot.get('reflection');
}

Future<void> _showReflectionDialog(
    BuildContext context, String? reflectionText, String prj_id,
    {String? map_id}) async {
  TextEditingController _reflectionController =
      TextEditingController(text: reflectionText);

  // Fetch the reflection and set the controller text
  String? reflection = await getReflection(prj_id, map_id);
  if (reflection != null) {
    _reflectionController.text = reflection;
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: <Widget>[
              SingleChildScrollView(
                child: TextField(
                  controller: _reflectionController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Type your reflection here...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: Text('Save'),
                    onPressed: () async {
                      // Save the updated reflection text
                      if (map_id != null) {
                        await FirebaseFirestore.instance
                            .collection('projects')
                            .doc(prj_id)
                            .collection('collected-data')
                            .doc(map_id)
                            .update({'reflection': _reflectionController.text});
                      } else {
                        await FirebaseFirestore.instance
                            .collection('projects')
                            .doc(prj_id)
                            .update({'reflection': _reflectionController.text});
                      }

                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Assume `timestamp` is your DateTime object

Future<void> showUpgradeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Upgrade to Pro'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                  'Your trial has expired. We love you keep using the app. Please cosnider supporting this project by upgrading to Pro.'),
            ],
          ),
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                child: Text('Maybe Later'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('❤️ Upgrade'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog first
                  GoRouter.of(context)
                      .go('/account'); // Navigate to the account screen
                },
              ),
            ],
          ),
        ],
      );
    },
  );
}
