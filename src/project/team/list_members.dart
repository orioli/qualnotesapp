import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../app_state.dart';
import 'invite_widgets.dart';

class ListMembers extends StatelessWidget {
  final String projectId;

  ListMembers({required this.projectId});

/*
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Something went wrong"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data?.docs ?? [];

        if (members.isEmpty) {
          return Column(children: [
            Paragraph("Users who join this project will list here"),
          ]);

          //Center(child: Text("No members have joined the project yet."));
        }

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (BuildContext context, int index) {
            final memberData = members[index].data();
            final memberName = memberData[
                'displayName']; // Replace with the actual user name if available
            //final memberId = memberData['userId']; // Replace with the actual user name if available
            final memberRole = memberData['role'];
            final memberJoinedAt =
                (memberData['joinedAt'] as Timestamp).toDate();

            return ListTile(
              title: Text(memberName),
              subtitle: Text("Role: $memberRole Joined: $memberJoinedAt"),
            );
          },
        );
      },
    );
  }
}
*/
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get(),
      builder: (context, projectSnapshot) {
        if (projectSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!projectSnapshot.hasData) {
          return Center(child: Text("Project not found"));
        }

        final projectData = projectSnapshot.data?.data();
        final String ownerName = projectData?['owner_name'] ?? '';
        final String ownerId = projectData?['owner_id'] ?? '';

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('projects')
              .doc(projectId)
              .collection('members')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Something went wrong"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final members = snapshot.data?.docs ?? [];
            final appState =
                Provider.of<ApplicationState>(context, listen: false);
            final String? currentUserId = appState.userId;
            //final String? currentUserEmail = appState.email;

            return ListView.builder(
              itemCount: members.length +
                  2, // Add one for the owner and one for blue add people tile
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  // Owner details
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.supervisor_account_outlined,
                        color: Colors.blueGrey,
                      ),
                      title: Text(ownerName),
                      subtitle: Text(ownerId == currentUserId
                          ? "Role: Admin (yes that's you 😉)"
                          : "Role: project Admin 💫 "),

                      //subtitle: Text("Role: Owner"),
                    ),
                  );
                } else if (index > 0 && index <= members.length) {
                  final memberData = members[index - 1].data();
                  final memberName = memberData['displayName'];
                  final memberRole = memberData['role'];
                  final memberId = memberData['userId'];
                  final email = memberData['email'];

                  final memberJoinedAt =
                      (memberData['joinedAt'] as Timestamp).toDate();
                  final dateFormatted =
                      DateFormat('yyyy-MMM-dd HH:mm').format(memberJoinedAt);

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.person_outlined,
                        color: Colors.blueGrey,
                      ),
                      title: Text(memberName),
                      subtitle: Text(memberId == currentUserId
                          ? "Role: $memberRole Joined: $dateFormatted (that's you 😉) "
                          : "Role: $memberRole Joined: $dateFormatted "),
                      //subtitle: Text("Role: $memberRole Joined: $memberJoinedAt"),
                    ),
                  );
                } // list memebers
                else if (index == members.length + 1) {
                  return Card(
                    child: ListTile(
                      onTap: () async {
                        final link = await generateInvitationLink(projectId);

                        await showCopyToClipboardDialog(context, link);
                        print(link);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRCodeScreen(link: link),
                          ),
                        );
                      },
                      leading: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue,
                      ),
                      title: Text(
                        "Add people",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  );
                }
                return null;
              },
            );
          },
        );
      },
    );
  }
}



//    return Paragraph(
  //      "no collabroators memebers yet, try to send invite to them ?");
