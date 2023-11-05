// Copyright 2023 Jose Berengueres. Qualnotes AB
// StreamBuidler design pattern adapted from Alek Anstrom video https://www.youtube.com/watch?v=iZrMBB2c3DQ&t=441s&ab_channel=MrAlek

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';
import 'package:qualnotes/src/widgets/widgets.dart';

import '../widgets/strings.dart';
import 'home_project_list_item.dart';

class ProjectList extends StatelessWidget {
  ProjectList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) {
        // TODO: worried about how fail proof this is...
        final userId = appState.userId;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseAuth.instance.currentUser != null
              ? FirebaseFirestore.instance
                  .collection('projects')
                  .where('owner_id', isEqualTo: userId)
                  .where('active', isEqualTo: true)

                  // TODO: create index in firebase otherise this does not work
                  //.orderBy('title')
                  .snapshots()
                  .asBroadcastStream()
              : Stream.empty(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint(snapshot.hasError.toString());
            }

            if (snapshot.connectionState != ConnectionState.active) {
              return Center(child: const CircularProgressIndicator());
            }

            final userId = appState.userId;

            // Fetch the projects where the user is a member
            // this query reuired https://console.firebase.google.com/v1/r/project/qnweb-5f924/firestore/indexes?create_exemption=Ck9wcm9qZWN0cy9xbndlYi01ZjkyNC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbWVtYmVycy9maWVsZHMvdXNlcklkEAIaCgoGdXNlcklkEAE

            FirebaseFirestore.instance
                .collectionGroup('members')
                .where('userId', isEqualTo: userId)
                .get()
                .then((querySnapshot) {
              querySnapshot.docs.forEach((doc) {
                //print("Project reference: ${doc.reference.parent.parent}");
                //print("Project reference: ${doc.reference}");
                //print("Project id: ${doc.reference.parent.parent!.id}");
              });
            });

            final projectItems = snapshot.data?.docs ?? [];

            return SingleChildScrollView(
              child: Column(
                children: projectItems.isEmpty
                    ? [Paragraph('\n${Strings.welcome}')]
                    : projectItems.map((projectItem) {
                        return ProjectItem(item: projectItem);
                      }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

Future<List<DocumentReference>> _getInvitedProjects(String userId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collectionGroup('members')
      .where('userId', isEqualTo: userId)
      .get();

  return querySnapshot.docs.map((doc) => doc.reference.parent.parent!).toList();
}
