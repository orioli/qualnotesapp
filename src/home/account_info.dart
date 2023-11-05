import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account info & stats'),
      ),
      body: Center(
        child: Consumer<ApplicationState>(
          builder: (context, appState, _) {
            final userId = appState.userId ?? '';
            final userEmail = appState.email ?? 'No email found';
            final DateTime? creationTime = appState.creationTime;
            final DateTime? lastSignInTime = appState.lastSignInTime;

            String activedays = "N/A";
            if (lastSignInTime != null) {
              int differenceInDays =
                  lastSignInTime.difference(creationTime!).inDays;
              activedays = differenceInDays.toString();
              // Use the 'differenceInDays' value in a Text widget or any other widget
            }
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Add this StreamBuilder
/*
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseAuth.instance.currentUser != null
                      ? FirebaseFirestore.instance
                          .collection('paid_plan')
                          .doc(userId)
                          .snapshots()
                      : Stream.empty(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return Text("Error retrieving plan details.");
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Plan Type: Free"),
                          ElevatedButton(
                            onPressed: () {
                              // Handle upgrade to pro action
                            },
                            child: Text("Upgrade to Pro"),
                          ),
                        ],
                      );
                    }

                    final planData = snapshot.data!.data();
                    final planType = planData?['planType'] ?? 'Free';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Plan Type: $planType"),
                        SizedBox(height: 16),
                        if (planType != "pro")
                          Text("For unlimited feautres and 24/7 support..."),
                        SizedBox(height: 16),
                        if (planType != "pro")
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Upgrade'),
                                    content: Text(
                                        'To upgrade get in touch at info@qualnotes.com'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Close'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Text("Upgrade"),
                          ),
                        SizedBox(height: 16),
                        if (planType == "pro")
                          Text("thank you 🤗 for being a pro"),
                      ],
                    );
                  },
                ),

                SizedBox(height: 16),
                SizedBox(height: 16),
*/
                  Text('User Email: $userEmail'),
                  SizedBox(height: 16),
                  _buildProjectCount(context, userId),
                  SizedBox(height: 16),
                  Text('user Id : $userId'),
                  SizedBox(height: 16),
                  Text(
                      'Account Created at: ${creationTime?.toString() ?? 'N/A'}'),
                  SizedBox(height: 16),
                  Text(
                      'Last Sign in at: ${lastSignInTime?.toString() ?? 'N/A'}'),

                  SizedBox(height: 16),
                  Text('Days since sign up: $activedays'),
                  SizedBox(height: 16),
                  SizedBox(height: 16),
                ]);
          },
        ),
      ),
    );
  }

  StreamBuilder<QuerySnapshot<Map<String, dynamic>>> _buildProjectCount(
      BuildContext context, String userId) {
    final projectsRef = FirebaseFirestore.instance.collection('projects');
    final userProjectsStream =
        projectsRef.where('owner_id', isEqualTo: userId).snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseAuth.instance.currentUser != null
          ? userProjectsStream
          : Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final projects = snapshot.data?.docs ?? [];
        return Text("Projects you are admin: ${projects.length}");
      },
    );
  }
}

class DeletionSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Deletion'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Account deletion successful',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
