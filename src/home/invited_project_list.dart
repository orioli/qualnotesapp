import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';

import 'home_project_list_item.dart';

class InvitedProjectList extends StatelessWidget {
  const InvitedProjectList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) {
        final userId = appState.userId;

        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collectionGroup('members')
              .where('userId', isEqualTo: userId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: const CircularProgressIndicator());
            }

            final projectRefs = snapshot.data?.docs
                    .map((doc) => doc.reference.parent.parent!)
                    .toList() ??
                [];

            return SingleChildScrollView(
              child: Column(
                children: projectRefs.map((projectRef) {
                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: projectRef.get(),
                    builder: (context, projectSnapshot) {
                      if (projectSnapshot.hasData) {
                        return InvitedProjectItem(item: projectSnapshot.data!);
                      } else if (projectSnapshot.hasError) {
                        return Text("Error: ${projectSnapshot.error}");
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class InvitedProjectItem extends StatelessWidget {
  const InvitedProjectItem({
    Key? key,
    required this.item,
  }) : super(key: key);

  final DocumentSnapshot<Map<String, dynamic>> item;

  @override
  Widget build(BuildContext context) {
    bool isActive =
        item.data()!.containsKey('active') ? item.get('active') : false;

    return isActive
        ? Card(
            child: ListTile(
              horizontalTitleGap: 8,
              leading: const Icon(
                Icons.folder_shared_outlined,
                color: Colors.black,
              ),
              title: Text(
                item.get('title').toString() + " (collab)",
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 18),
              ),
              enabled: true,
              minLeadingWidth: 0,
              onTap: () {
                openProject(
                    context, item.id.toString(), item.get('title').toString());
              },
            ),
          )
        : SizedBox.shrink();
  }
}
