import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class ReflectionButton extends StatelessWidget {
  final String prj_id;
  final String? mapId;
  final String? interviewId;

  ReflectionButton({
    required this.prj_id,
    this.mapId,
    this.interviewId,
  });

  Future<String?> getReflectionText(BuildContext context) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot doc;

    if (interviewId != null) {
      doc = await firestore
          .collection('projects')
          .doc(prj_id)
          .collection('collected-data')
          .doc(interviewId)
          .get();
    } else {
      doc = await firestore.collection('projects').doc(prj_id).get();
    }
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (doc.exists && data?.containsKey('reflection') == true) {
      return data?['reflection'];
    } else {
      return null;
    }
  }

  Future<void> saveReflectionText(BuildContext context, String newText) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (interviewId != null) {
      await firestore
          .collection('projects')
          .doc(prj_id)
          .collection('collected-data')
          .doc(interviewId)
          .set({'reflection': newText}, SetOptions(merge: true));
    } else {
      await firestore
          .collection('projects')
          .doc(prj_id)
          .set({'reflection': newText}, SetOptions(merge: true));
    }
  }

  void _showReflectionModalSheet(BuildContext context) async {
    String? initialText = await getReflectionText(context);
    TextEditingController textController =
        TextEditingController(text: initialText);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  saveReflectionText(context, textController.text);
                  Navigator.of(context).pop();
                },
                child: Text('Save'),
              ),
              SizedBox(height: 5),
              TextField(
                controller: textController,
                maxLines: null,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: 'Reflection',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _showReflectionModalSheet(context),
      child: Text('Reflection'),
    );
  }
}
