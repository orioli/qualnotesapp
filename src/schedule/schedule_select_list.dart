// Copyright 2023 Jose Berengueres. Qualnotes AB
// StreamBuidler design pattern adapted from
// https://www.youtube.com/watch?v=iZrMBB2c3DQ&t=441s&ab_channel=MrAlek

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import '../project/project_add_menu.dart';
import 'schedule_select_item.dart';

class ListSchedules extends StatelessWidget {
  final String? prj_id;
  final String? type;

  ListSchedules({
    Key? key,
    required this.prj_id,
    this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseAuth.instance.currentUser != null
            ? FirebaseFirestore.instance
                .collection('projects')
                .doc(prj_id)
                .collection("collected-data")
                .where('type', isEqualTo: 'schedule')
                .snapshots()
                .asBroadcastStream()
            : Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return Center(child: const CircularProgressIndicator());
          }

          final fileItems = snapshot.data?.docs;
          if (fileItems!.isEmpty) {
            return DefaultEmptyListView(
              prj_id: prj_id,
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data?.size ?? 0,
              itemBuilder: (BuildContext context, int index) {
                return ScheduleItem(
                    item: fileItems[index], prj_id: prj_id!, type: type);
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          createNewSchedule(context, prj_id!);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class DefaultEmptyListView extends StatelessWidget {
  final String? prj_id;

  const DefaultEmptyListView({
    Key? key,
    required this.prj_id,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 8,
      onTap: () {
        createNewSchedule(context, this.prj_id!);
      },
      leading: const Icon(
        Icons.add_circle_outline,
        color: Colors.blue,
      ),
      subtitle: Text(
        "This project has no schedules yet...",
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
      title: Text(
        Strings.newSchedule, // + " id " + item.id.toString(),
        textAlign: TextAlign.left,
        style: const TextStyle(fontSize: 18, color: Colors.blue),
      ),
    );
  }
}
