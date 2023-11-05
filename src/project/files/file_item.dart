// Copyright 2023 Jose Berengueres. Qualnotes AB

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';

import '../../widgets/popup_confirmation.dart';
import '../../widgets/type_2_icon_in_list_items.dart';

class FileItem extends StatelessWidget {
  const FileItem({
    Key? key,
    required this.item,
    required this.prj_id,
    required this.sch_or_map_id,
  }) : super(key: key);
  final String prj_id;
  final String sch_or_map_id;
  final QueryDocumentSnapshot<Map<String, dynamic>> item;

  void _onDelete({
    required BuildContext context,
    //required bool isSchedule,
    required ApplicationState state,
    required String title,
  }) async {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: PopupConfirmation(
              onConfirm: () {
                state
                    .deleteScheduleOrMap(
                  //isScheduleQuestion: false,
                  requestor_id: state.userId!,
                  prj_id: prj_id,
                  doc_id: sch_or_map_id,
                  //isSchedule: isSchedule
                )
                    .then((value) {
                  Navigator.of(context, rootNavigator: true).pop();
                });
              },
              title: title,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        horizontalTitleGap: 8,
        trailing: Consumer<ApplicationState>(builder: (context, state, _) {
          List<PopupMenuEntry<int>> popupData = [
            PopupMenuItem<int>(
              value: 1,
              onTap: () => _onDelete(
                //isSchedule: true,
                context: context,
                state: state,
                title: "delete",
              ),
              child: Text('Delete'),
            ),
          ];
          return PopupMenuButton<int>(
            onSelected: (int item) {},
            itemBuilder: (BuildContext context) => popupData,
            child: Icon(
              Icons.more_vert,
              color: Colors.black,
            ),
          );
        }),
        leading: type2Icon(item.get('type').toString()),
        title: Text(
          item.get('title').toString(),
          // +
          //    "::" +
          //    item.get('type').toString(), // + " id " + item.id.toString(),
          textAlign: TextAlign.left,
          style: const TextStyle(fontSize: 18),
        ),

        enabled: true,
        minLeadingWidth: 0,
        onTap: () async {
          switch (item.get('type').toString()) {
            case 'interview':
              debugPrint('interview:' + item.toString());
              if (item.data().containsKey('questions') == true) {
                final questions = item.get('questions');
                final questionsEncoded = questions != null
                    ? jsonEncode(questions)
                    : '[]'; // Assign a default value if null

                context.pushNamed('interview_play', queryParams: {
                  'prj_id': prj_id,
                  'interview_id': item.id.toString(),
                  'interview_title': item.get('title').toString(),
                  'recording': item.get('recording').toString(),
                  'questions': questionsEncoded,
                });
              } else {
                context.pushNamed('interview_play', queryParams: {
                  'prj_id': prj_id,
                  'interview_id': item.id.toString(),
                  'interview_title': item.get('title').toString(),
                  'recording': item.get('recording').toString(),
                });
              }
              break;

            case 'schedule':
              context.pushNamed('makeSchedule', queryParams: {
                'prj_id': prj_id,
                'schedule_id': item.id.toString(),
                'schedule_title': item.get('title').toString(),
              });
              // TO DO: open schedule for editing. have same effect as edit submenu in trailing icon;
              break;
            case 'participantobservation':
              context.pushNamed('makeObservation', queryParams: {
                'prj_id': prj_id,
                'obs_id': item.id.toString(),
                'title': item.get('title').toString(),
                'editExistingPoints': "true", // A
              });
              // TO DO: open schedule for editing. have same effect as edit submenu in trailing icon;
              break;
            case 'map':
              String result =
                  (await _askEditOrPlayMapDialog(context)) as String;

              if (result == 'cancel') {
                break;
              }
              String route = "not defined yet";

              if (result == 'play') {
                route = "playMap"; // Navigate to add more points mode
                context.pushNamed(route, queryParams: {
                  'prj_id': prj_id, // TODO, LIFT TO STATE
                  'map_id': item.id.toString(), // TODO, LIFT TO STATE
                  'title': item.get('title').toString(), // TODO, LIFT TO STATE
                });
              }
              if (result == 'edit') {
                route = "MakeMap";
                context.pushNamed(route, queryParams: {
                  'prj_id': prj_id,
                  'map_id': item.id.toString(),
                  'title': item.get('title').toString(),
                  'editExistingPoints': "true", // Add this line
                });
              }

              // TO DO: open schedule for editing. have same effect as edit submenu in trailing icon;
              break;
            default:
          }
        },
        //textAlign: item.get('sender') == 'me' ? TextAlign.end : TextAlign.start,
      ),
    );
  }

  Future<String?> _askEditOrPlayMapDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose mode'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Edit or Play map?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                // Return 'play'
                Navigator.of(context).pop('cancel');
              },
            ),
            TextButton(
              child: Text('Play'),
              onPressed: () {
                // Return 'play'
                Navigator.of(context).pop('play');
              },
            ),
            TextButton(
              child: Text('Edit'),
              onPressed: () {
                // Return 'add'
                Navigator.of(context).pop('edit');
              },
            ),
          ],
        );
      },
    );
  }

  // TO DO: rename as edit Schedule... shoudl be more general
  Future<void> _onTap(bool isDelete, BuildContext context) async {
    FirebaseFirestore.instance
        .collection('projects')
        .doc(prj_id)
        .collection('collected-data')
        .doc(sch_or_map_id)
        .get()
        .then(
      (value) async {
        List data;
        try {
          data = value.get('questions') as List;
        } catch (e) {
          data = [];
        }
        context.pushNamed(
          'makeSchedule',
          queryParams: {
            'schedule_title': item['title'],
            'prj_id': prj_id,
            'schedule_id': sch_or_map_id
          },
          extra: data,
        );
      },
    );
  }
}
