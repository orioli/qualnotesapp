// Copyright 2023 Jose Berengueres. Qualnotes AB
// StreamBuidler design pattern adapted from
// https://www.youtube.com/watch?v=iZrMBB2c3DQ&t=441s&ab_channel=MrAlek

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/widgets/app_sizes.dart';

import 'dart:io';

import '../app_state.dart';
import '../mapping/widgets.dart';
import 'schedule_utils.dart';

class Schedule extends StatelessWidget {
  final String? prj_id;
  final String? sch_id;
  final String? title;
  Schedule({super.key, this.prj_id, this.sch_id, this.title});

  Stream<List> _loadQuestionsStream() {
    //debugPrint("schdeule...  $prj_id   ---- $sch_id");
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(prj_id)
        .collection('collected-data')
        .doc(sch_id)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!.containsKey('questions')) {
        return (snapshot.data()!['questions'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } else {
        return [];
      }
    });
  }

  Future<void> _addQuestionModelSheet(
    BuildContext context,
    TextEditingController controller,
    int index,
    bool isEdit,
    String? prj_id,
    String? sch_id,
    List<Map<String, dynamic>> qlist,
  ) async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Add this line
      builder: (BuildContext context) {
        return FractionallySizedBox(
          // Wrap the Padding with FractionallySizedBox
          heightFactor: 0.6, // Set the height factor to 0.8
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Edit question' : 'Add question',
                  ),
                ),
                SizedBox(height: 16),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isEdit)
                        ElevatedButton(
                          onPressed: () async {
                            // Delete the current question
                            qlist.removeAt(index);

                            // Update Firestore
                            await FirebaseFirestore.instance
                                .collection('projects')
                                .doc(prj_id)
                                .collection('collected-data')
                                .doc(sch_id)
                                .update({
                              'questions': qlist,
                            });

                            // Update questions in ApplicationState
                            Provider.of<ApplicationState>(context,
                                    listen: false)
                                .questions = qlist;

                            Navigator.pop(context);
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                          ),
                          child: Text('Delete'),
                        ),
                      ElevatedButton(
                        onPressed: () async {
                          String text = controller.text
                              .trim(); // Remove leading and trailing whitespaces
                          if (text.isNotEmpty) {
                            // Check if the text is not empty
                            if (isEdit) {
                              // Update Firestore for existing question
                              qlist[index]['text'] = text;
                            } else {
                              // Add new question to the list
                              qlist.add({"text": text});
                            }

                            // Update Firestore
                            await FirebaseFirestore.instance
                                .collection('projects')
                                .doc(prj_id)
                                .collection('collected-data')
                                .doc(sch_id)
                                .update({
                              'questions': qlist,
                            });

                            Navigator.pop(context);
                          }
                        },
                        child: Text(isEdit ? 'Save' : 'Add question'),
                      ),
                    ])
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: StreamBuilder<List>(
          stream: _loadQuestionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else {
              final _qlist = snapshot.data != null
                  ? snapshot.data!.cast<Map<String, dynamic>>()
                  : <Map<String, dynamic>>[];
              Provider.of<ApplicationState>(context, listen: false).questions =
                  _qlist;
              ; // Set the questions in ApplicationState
              return Consumer<ApplicationState>(builder: (context, state, _) {
                return Stack(
                  children: [
                    ReorderableListView.builder(
                        itemCount: _qlist.length,
                        itemBuilder: (BuildContext context, int index) {
                          return InkWell(
                            key: ValueKey(
                                _qlist[index]), // Unique key for each item
                            onTap: () async {
                              TextEditingController _controller =
                                  TextEditingController(
                                      text: _qlist[index]['text']);
                              await _addQuestionModelSheet(
                                context,
                                _controller,
                                index,
                                true, // isEdit is true because you're editing an existing question
                                prj_id,
                                sch_id,
                                _qlist,
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
                              child: ListTile(
                                trailing: Icon(Icons.drag_handle_sharp),
                                leading: InkWell(
                                  onTap: () async {
                                    debugPrint(
                                        "state.isImagePickingInProgress " +
                                            state.isImagePickingInProgress
                                                .toString());
                                    if (state.isImagePickingInProgress) return;
                                    Overlay.of(context).insert(
                                        _overlayEntry); // show CircularProgressIndicator

                                    try {
                                      state.isImagePickingInProgress = true;
                                      if (_qlist[index]['img'] != null) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => FullScreenImgUrl(
                                                imageUrl: _qlist[index]['img']),
                                          ),
                                        );
                                      } else {
                                        File? imageFile = await pickImage();
                                        if (imageFile != null) {
                                          String? imageUrl =
                                              await uploadImage(imageFile);
                                          if (imageUrl != null) {
                                            // Update Firestore
                                            _qlist[index]['img'] = imageUrl;
                                            await FirebaseFirestore.instance
                                                .collection('projects')
                                                .doc(prj_id)
                                                .collection('collected-data')
                                                .doc(sch_id)
                                                .update({
                                              'questions': _qlist,
                                            });

                                            // Update questions in ApplicationState
                                            Provider.of<ApplicationState>(
                                                    context,
                                                    listen: false)
                                                .questions = _qlist;
                                          }
                                        }
                                      } //else
                                    } finally {
                                      state.isImagePickingInProgress = false;
                                      _overlayEntry
                                          .remove(); // hide CircularProgressIndicator
                                    }
                                  },
                                  child: _qlist[index]['img'] != null
                                      ? SizedBox(
                                          width: AppSizes.thumbnailImgHeight,
                                          height: AppSizes.thumbnailImgHeight,
                                          child: LoadingImage(
                                              url: _qlist[index]['img']),
                                        )
                                      : Container(
                                          width: AppSizes.thumbnailImgHeight,
                                          height: AppSizes.thumbnailImgHeight,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                          child: Icon(Icons.photo,
                                              color: Colors.grey[600]),
                                        ),
                                ),
                                title: Text(_qlist[index]['text']),
                              ),
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) async {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final Map<String, dynamic> movedItem =
                              _qlist.removeAt(oldIndex);
                          _qlist.insert(newIndex, movedItem);

                          // Update Firestore
                          await FirebaseFirestore.instance
                              .collection('projects')
                              .doc(prj_id)
                              .collection('collected-data')
                              .doc(sch_id)
                              .update({
                            'questions': _qlist,
                          });

                          // Update questions in ApplicationState
                          Provider.of<ApplicationState>(context, listen: false)
                              .questions = _qlist;
                        }),
                    if (state.uploading_title)
                      Container(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                  ],
                );
              });
            }
          }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addQuestionModelSheet(
          context,
          TextEditingController(),
          0,
          false, // isEdit is false because you're adding a new question
          prj_id,
          sch_id,
          Provider.of<ApplicationState>(context, listen: false).questions,
        ),
        label: const Text('Question'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.blue,
        hoverColor: Colors.black,
      ),
    );
  }

  OverlayEntry _overlayEntry = OverlayEntry(
    builder: (BuildContext context) => Center(
      child: CircularProgressIndicator(),
    ),
  );
}
