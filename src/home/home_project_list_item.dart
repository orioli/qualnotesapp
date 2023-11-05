import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

void openProject(BuildContext context, String prjId, String prjTitle) {
  final appState = Provider.of<ApplicationState>(context, listen: false);
  appState.setProjectTitle(prjTitle);

  context.pushNamed('project',
      queryParams: {'prj_id': prjId, 'prj_title': prjTitle});
}

class ProjectItem extends StatelessWidget {
  const ProjectItem({
    Key? key,
    required this.item,
  }) : super(key: key);

  final QueryDocumentSnapshot<Map<String, dynamic>> item;

  @override
  Widget build(BuildContext context) {
    bool isActive =
        item.data().containsKey('active') ? item.get('active') : false;

    return isActive
        ? Card(
            child: ListTile(
              horizontalTitleGap: 8,
              trailing: PopupMenuButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.black,
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  const PopupMenuItem(
                    value: 'open',
                    child: Text('Open'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'open') {
                    openProject(context, item.id.toString(),
                        item.get('title').toString());
                  } else if (value == 'delete') {
                    _deleteProject(context);
                  }
                },
              ),
              leading: const Icon(
                Icons.folder_outlined,
                color: Colors.black,
              ),
              title: Text(
                item.get('title').toString(),
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 18),
              ),
              enabled: true,
              minLeadingWidth: 0,
              onTap: () {
                //_openProject(context);
                openProject(
                    context, item.id.toString(), item.get('title').toString());
              },
            ),
          )
        : SizedBox.shrink();
  }

/*
  void _openProject(BuildContext context) {
    var param1 = item.id.toString();
    var param2 = item.get('title').toString();
    final appState = Provider.of<ApplicationState>(context, listen: false);
    appState.setProjectTitle(param2);

    context.pushNamed('project',
        queryParams: {'prj_id': param1, 'prj_title': param2});
  }
*/
  void _deleteProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: const Text('Are you sure you want to delete this project?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('projects')
                    .doc(item.id)
                    .update({'active': false});
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
