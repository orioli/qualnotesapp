// Copyright 2023 Jose Berengueres. Qualnotes AB
import 'package:flutter/material.dart';
import 'package:qualnotes/src/widgets/strings.dart';

import 'schedule_select_list.dart';

class ScheduleSelect extends StatelessWidget {
  final String? prj_id;
  final String? type;
  ScheduleSelect({super.key, this.prj_id, this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(Strings.selectSchedule),
        ),
        body: ListSchedules(
          prj_id: prj_id,
          type: type,
        ));
  }
}
