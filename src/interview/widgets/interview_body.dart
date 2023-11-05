import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import '../recording_sate.dart';
import 'interview_question_card_UI.dart';

class InterviewBody extends StatefulWidget {
  InterviewBody({
    Key? key,
    required String? prj_id,
    required String? sch_id,
    this.controller,
  })  : _prj_id = prj_id,
        _sch_id = sch_id,
        super(key: key);

  final String? _prj_id;
  final String? _sch_id;
  final CustomTimerController? controller;
  @override
  State<InterviewBody> createState() => _InterviewBodyState();
}

List dataModel = [];

class _InterviewBodyState extends State<InterviewBody> {
  Map<int, int> _askedTimestamps = {};

  Future<DocumentSnapshot<Map<String, dynamic>>>? data;
  @override
  void initState() {
    super.initState();
    data = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget._prj_id)
        .collection('collected-data')
        .doc(widget._sch_id)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: const CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(Strings.somethingWentWrong);
        }

        try {
          dataModel = snapshot.data?.data()?.isNotEmpty ?? false
              ? (snapshot.data?.data()?['questions'] ?? [])
              : [];
        } catch (e) {
          log('questions are not expected format');
          dataModel = [];
        }
        RecordingState recordingState = Provider.of<RecordingState>(context);

        return dataModel.isNotEmpty
            ? ListView.builder(
                itemBuilder: (context, index) => CustomTimer(
                  controller: widget.controller!,
                  builder: (context, remaining) {
                    return InkWell(
                      onTap: () {},
                      child: InterviewQuestionCard(
                        questionText: dataModel[index]['text'],
                        imageUrl: dataModel[index]['img'],
                        isTimeStamped: _askedTimestamps.containsKey(index),
                        timestamp: _askedTimestamps.containsKey(index)
                            ? _askedTimestamps[index]!
                            : -1,
                        onTap: () {
                          if (!(recordingState.startOfRecording == -1)) {
                            int timestamp =
                                DateTime.now().toUtc().millisecondsSinceEpoch;

                            _askedTimestamps[index] = timestamp;
                            // update the timestamp to RecordingState
                            recordingState.addTimestamp(index, timestamp);

                            // set recordingState.setTimestamps(_askedTimestamps)
                            setState(() {});
                          }
                        },
                      ),
                    );
                  },
                ),
                itemCount: dataModel.length,
              )
            : Center(
                child: Text(
                  Strings.noQuestionForSchedule,
                ),
              );
      },
    );
  }
}
