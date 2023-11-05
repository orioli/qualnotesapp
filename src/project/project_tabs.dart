// Copyright 2023 Jose Berengueres. Qualnotes AB

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/project/team/list_members.dart';
import 'package:qualnotes/src/project/project_add_menu.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import '../app_state.dart';
import 'files/file_list.dart';
import 'setup/project_stepper.dart';

class ProjectTabs extends StatelessWidget {
  String? prj_id;
  String? prj_title;
  String? active_tab;

  ProjectTabs({super.key, this.prj_id, this.prj_title, this.active_tab});

  // this part new  to extract prj id
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);
    //debugPrint(
    //    " project  appState.projectTitle  ...  = " + appState.projectTitle!);

    // to use with ${appState.projectTitle}'),
    int index = 1;
    index = (active_tab == "first") ? index = 0 : 1;
    //debugPrint(" active_tab  / index " + this.active_tab! + index.toString());

    return DefaultTabController(
      initialIndex: index,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(' 📁 $prj_title'),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            onPressed: () {
              //Navigator.of(context).pop(true);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.fact_check_outlined),
                text: Strings.todo,
              ),
              Tab(
                icon: Icon(Icons.library_books_outlined),
                text: Strings.files,
              ),
              //Tab(
              //  icon: Icon(Icons.chat_bubble_outline),
              //  text: Strings.chat,
              //),
              Tab(
                icon: Icon(Icons.group_add_outlined),
                text: Strings.membersTab,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            Center(
              child: ProjectStepper(prj_id: prj_id ?? ''),
            ),
            Center(
              child: FileList(
                prj_id: prj_id,
              ),
            ),
            //Center(
            //  child: QAndA(prj_id: prj_id),
            //),
            Center(
              child: ListMembers(projectId: prj_id!),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              AddMenu(context, prj_id!, prj_title!);
            },
            backgroundColor: Colors.blue,
            label: const Text('Add'),
            icon: const Icon(Icons.add)),
        /*
        floatingActionButton: Consumer<ApplicationState>(
          builder: (context, appState, _) {
            if (appState.loggedIn) {
              final accountAge = (appState.lastSignInTime!)
                  .difference(appState.creationTime!)
                  .inDays;
              final trialExpired = accountAge > 14;

              return FloatingActionButton(
                onPressed: () async {
                  debugPrint("... trialExpired" + trialExpired.toString());
                  // TODO at the moment dont shwo it...
                  if (true || !trialExpired || (appState.planType == "pro")) {
                    AddMenu(context, prj_id!, prj_title!);
                  } else {
                    showUpgradeDialog(context).then((_) {
                      AddMenu(context, prj_id!, prj_title!);
                    });
                  }
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),*/
      ),
    );
  }
}
