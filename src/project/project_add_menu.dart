import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/widgets/strings.dart';

import '../widgets/add_title_dialouge.dart';
import '../app_state.dart';

Future<void> AddMenu(
  BuildContext context,
  String prj_id,
  String prj_title,
) async {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoActionSheet(
      title: const Text(Strings.whatDoWeAdd),
      message: const Text(Strings.chooseOne),
      actions: <CupertinoActionSheetAction>[
        _buildNewPOBSAction(context, prj_id),
        //_buildNewWalkingMapAction(context, prj_id),
        _buildNewInterviewAction(context, prj_id),
        _buildNewMappingAction(context, prj_id),
        _buildNewScheduleAction(context, prj_id),
        _buildCancelAction(context),
      ],
    ),
  );
}

CupertinoActionSheetAction _buildNewMappingAction(
    BuildContext context, String prj_id) {
  return CupertinoActionSheetAction(
    onPressed: () {
      showDialog(
        context: context,
        barrierColor: Colors.black45,
        builder: (context) => Consumer<ApplicationState>(
          builder: (context, appState, _) {
            return myTitleDialog(
              onPress: (val) async {
                await appState.addMap(prj_id, val).then(
                  (value) async {
                    context.pushNamed('makeMap', queryParams: {
                      'map_id': value.id,
                      'title': ((await value.get()).data()
                          as Map<String, dynamic>?)?['title'],
                      'prj_id': prj_id,
                    });
                  },
                );
                Navigator.of(context, rootNavigator: true).pop();
              },
              prj_id: prj_id,
              title: Strings.titleYourNewMap,
              hint: Strings.titleHint,
            );
          },
        ),
      );
    },
    child: const Text(Strings.newMapping),
  );
}

CupertinoActionSheetAction _buildNewWalkingMapAction(
    BuildContext context, String prj_id) {
  return CupertinoActionSheetAction(
    onPressed: () {
      Navigator.pop(context);
      context.pushNamed('makeWalkingMap', queryParams: {
        'prj_id': prj_id,
      });
    },
    child: const Text(Strings.newWalkingMap),
  );
}

CupertinoActionSheetAction _buildNewPOBSAction(
    BuildContext context, String prj_id) {
  return CupertinoActionSheetAction(
    onPressed: () {
      createNewPOBS(context, prj_id);
    },
    child: const Text(Strings.newPOBS),
  );
}

CupertinoActionSheetAction _buildNewScheduleAction(
    BuildContext context, String prj_id) {
  return CupertinoActionSheetAction(
    onPressed: () {
      createNewSchedule(context, prj_id);
    },
    child: const Text(Strings.newScheduleCaps),
  );
}

CupertinoActionSheetAction _buildNewInterviewAction(
    BuildContext context, String prj_id) {
  return CupertinoActionSheetAction(
    onPressed: () {
      Navigator.pop(context);
      context.pushNamed('interview', queryParams: {
        'prj_id': prj_id,
      });
    },
    child: const Text(Strings.newInterview),
  );
}

CupertinoActionSheetAction _buildCancelAction(BuildContext context) {
  return CupertinoActionSheetAction(
    isDestructiveAction: true,
    onPressed: () {
      Navigator.pop(context);
    },
    child: const Text(Strings.cancel),
  );
}

Future<void> createNewWalkingMap(BuildContext context, String prj_id) async {
  showDialog(
    context: context,
    barrierColor: Colors.black45,
    builder: (context) => Consumer<ApplicationState>(
      builder: (context, appState, _) {
        return myTitleDialog(
          onPress: (val) async {
            await appState.addWalkingMap(prj_id, val).then(
              (value) async {
                await Future.delayed(Duration(milliseconds: 500));

                context.pushNamed('makeWalkingMap', queryParams: {
                  'prj_id': prj_id,
                  'obs_id': value.id,
                  'title': ((await value.get()).data()
                      as Map<String, dynamic>?)?['title'],
                });
              },
            );
            // close cupertino
            Navigator.of(context, rootNavigator: true).pop();
          },
          prj_id: prj_id,
          title: Strings.enterTitle,
          hint: Strings.enterTitleHint,
        );
      },
    ),
  );
}

Future<void> createNewPOBS(BuildContext context, String prj_id) async {
  showDialog(
    context: context,
    barrierColor: Colors.black45,
    builder: (context) => Consumer<ApplicationState>(
      builder: (context, appState, _) {
        return myTitleDialog(
          onPress: (val) async {
            await appState.addParticipantObservation(prj_id, val).then(
              (value) async {
                await Future.delayed(Duration(milliseconds: 500));

                context.pushNamed('makeObservation', queryParams: {
                  'prj_id': prj_id,
                  'obs_id': value.id,
                  'title': ((await value.get()).data()
                      as Map<String, dynamic>?)?['title'],
                });
              },
            );
            // close cupertino
            Navigator.of(context, rootNavigator: true).pop();
          },
          prj_id: prj_id,
          title: Strings.enterTitle,
          hint: Strings.enterTitleHint,
        );
      },
    ),
  );
}

Future<void> createNewSchedule(BuildContext context, String prj_id) async {
  showDialog(
    context: context,
    barrierColor: Colors.black45,
    builder: (context) => Consumer<ApplicationState>(
      builder: (context, appState, _) {
        return myTitleDialog(
          onPress: (val) async {
            await appState.addSchedule(prj_id, val).then(
              (value) async {
                await Future.delayed(Duration(milliseconds: 500));

                context.pushNamed('makeSchedule', queryParams: {
                  'prj_id': prj_id,
                  'schedule_id': value.id,
                  'schedule_title': ((await value.get()).data()
                      as Map<String, dynamic>?)?['title'],
                });
              },
            );
            Navigator.of(context, rootNavigator: true).pop();
          },
          prj_id: prj_id,
          title: Strings.enterTitle,
          hint: Strings.enterTitleHint,
        );
      },
    ),
  );
}
