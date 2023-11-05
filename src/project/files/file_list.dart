// Copyright 2023 Jose Berengueres. Qualnotes AB
// StreamBuidler design pattern adapted from
// https://www.youtube.com/watch?v=iZrMBB2c3DQ&t=441s&ab_channel=MrAlek

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/widgets/strings.dart';

import '../../app_state.dart';
import 'file_item.dart';

class FileList extends StatelessWidget {
  String? prj_id;
  FileList({super.key, this.prj_id});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseAuth.instance.currentUser != null
          ? FirebaseFirestore.instance
              .collection('projects')
              .doc(prj_id)
              .collection('collected-data')
              .orderBy('creation_timestamp', descending: true)
              .snapshots()
              .asBroadcastStream()
          : Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active) {
          return const CircularProgressIndicator();
        }
        final fileItems = snapshot.data?.docs;

        if (fileItems == null || fileItems.isEmpty) {
          return youHaveNoFilesTile();
        } else {
          return Consumer<ApplicationState>(builder: (context, state, _) {
            return Stack(
              children: [
                ListView.builder(
                  itemCount: snapshot.data?.size ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    return FileItem(
                      item: fileItems[index],
                      prj_id: prj_id ?? "",
                      sch_or_map_id: fileItems[index].id,
                    );
                  },
                ),
                if (state.uploading_title || state.deleting)
                  Container(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
              ],
            );
          });
        }
      },
    );
  }
}

class youHaveNoFilesTile extends StatelessWidget {
  const youHaveNoFilesTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 8,
      title: Text(
        Strings.youHaveNoFilesYet, // + " id " + item.id.toString(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
