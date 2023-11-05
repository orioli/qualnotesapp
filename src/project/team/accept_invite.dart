import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../AuthFunc.dart';

class AcceptInvitationScreen extends StatelessWidget {
  final String token;

  AcceptInvitationScreen({required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📨 QualNotes Invite')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('You have been invited to collaborate on a project.'),
            SizedBox(height: 16),
            Consumer<ApplicationState>(
              builder: (context, appState, _) {
                if (appState.loggedIn) {
                  return ElevatedButton(
                    child: Text('Accept invite?'),
                    onPressed: () async {
                      Map<String, dynamic> result = await acceptInvitation(
                          token, appState.userId!, appState.displayName!);
                      bool success = result['success'];
                      String projectId = result['projectId'];
                      if (success) {
                        getProjectData(projectId).then((projectData) {
                          final projectTitle =
                              projectData.data()?['title'] ?? 'No title';

                          inviteSuccessAlert(context, projectTitle, projectId);
                        }).catchError((error) {
                          // Handle the error here
                          debugPrint('Failed to fetch project data: $error');
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Failed to join the project. Please try again.')),
                        );
                      }
                    },
                  );
                } else {
                  return Column(
                    children: [
                      Text(
                          'Please sign up or log in to accept the invitation.'),
                      SizedBox(height: 16),

                      Consumer<ApplicationState>(
                        builder: (context, appState, _) => AuthFunc(
                          loggedIn: appState.loggedIn,
                          signOut: appState.signOut,
                        ),
                      ),

                      // Your existing sign-up and log-in buttons or widgets
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void inviteSuccessAlert(
      BuildContext context, projectTitle, String projectId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You are now a member of project $projectTitle'),
          actions: <Widget>[
            TextButton(
              child: Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Go to Project'),
              onPressed: () {
                Navigator.of(context).pop();
                context.goNamed(
                  'project',
                  queryParams: {
                    'prj_id': projectId,
                    'prj_title': projectTitle,
                    'active_tab': 'second',
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> acceptInvitation(
      String token, String userId, String displayName) async {
    // Get the invitation data from Firestore
    final invitationRef =
        FirebaseFirestore.instance.collection('project_invitations').doc(token);
    final invitationSnapshot = await invitationRef.get();

/*

    if (!invitationSnapshot.exists ||
        invitationSnapshot['status'] != 'pending') {
      return {'success': false, 'projectId': "error or invite not pending"};
    }
    */
    // else....
    final projectId = invitationSnapshot['projectId'];

    // Grant access to the project by adding the user to the project's members collection
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(userId)
        .set({
      'userId': userId,
      'displayName': displayName,
      'role': 'member',
      'joinedAt': Timestamp.now(),
    });

    await invitationRef.update({'status': 'at least one user accepted'});

    return {'success': true, 'projectId': projectId};
  }
}

Future<DocumentSnapshot<Map<String, dynamic>>> getProjectData(
    String projectId) async {
  final projectDocument = await FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId)
      .get();

  if (projectDocument.exists) {
    return projectDocument;
  } else {
    throw Exception("Project not found");
  }
}
