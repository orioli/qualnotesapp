// Copyright 2023 Jose Berengueres. Qualnotes AB

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/type_2_icon_in_list_items.dart';

class ScheduleItem extends StatelessWidget {
  final String prj_id;
  final String? type;

  const ScheduleItem({
    Key? key,
    required this.item,
    required this.prj_id,
    this.type,
  }) : super(key: key);

  final QueryDocumentSnapshot<Map<String, dynamic>> item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 8,
      trailing: const Icon(
        Icons.more_vert,
        color: Colors.black,
      ),
      leading: type2Icon(item.get('type').toString()),
      title: Text(
        item.get('title').toString(), // + " id: " + item.id.toString(),
        textAlign: TextAlign.left,
        style: const TextStyle(fontSize: 18),
      ),
      enabled: true,
      minLeadingWidth: 0,
      onTap: () {
        var param1 = prj_id.toString();
        var param2 = item.id.toString();
        //debugPrint("************  type = " + type.toString());
        if (type != null && type == 'walkingmap') {
          context.pushNamed('makeWalkingMap',
              queryParams: {'prj_id': param1, 'sch_id': param2});
        } else {
          context.pushNamed('interview',
              queryParams: {'prj_id': param1, 'sch_id': param2});
        }
      },

      //textAlign: item.get('sender') == 'me' ? TextAlign.end : TextAlign.start,
    );
  }
}
