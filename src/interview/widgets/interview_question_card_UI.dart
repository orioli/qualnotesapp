import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/mapping/geonote.dart';
import 'package:qualnotes/src/mapping/widgets.dart';

import '../../widgets/widgets.dart';
import '../recording_sate.dart';

class DisplayQuestionCard extends StatelessWidget {
  final String questionText;
  final String? imageUrl;
  final String? timestamp;
  final bool? accent;

  DisplayQuestionCard({
    required this.questionText,
    this.imageUrl,
    this.timestamp,
    this.accent = false,
  });

// lets reuse cardthumbnail...
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: accent!
            ? 3
            : 1, // Apply elevation to create a sense of depth and emphasis
        margin: EdgeInsets.fromLTRB(10, 12, 10, 0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accent! ? Colors.blue : Colors.white,
                width: 3.0,
              ),
            ),
          ),
          child: ListTile(
            leading: CardThumbnail(
                gn: new GeoNote(1, "photo", 0, 0, questionText,
                    imgPath: imageUrl)),
            title: Text(timestamp == null ? "no timestamp" : timestamp!),
            subtitle: ParagraphCard(questionText),
          ),
        ));
  }
}

// this one used to timesstamp each question during interviews as they are asked...
class InterviewQuestionCard extends StatelessWidget {
  final String? questionText;
  final String? imageUrl;
  final bool isTimeStamped;
  final int timestamp;
  final VoidCallback? onTap;

  const InterviewQuestionCard({
    Key? key,
    required this.questionText,
    required this.imageUrl,
    this.isTimeStamped = false,
    required this.timestamp,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    RecordingState recordingState = Provider.of<RecordingState>(context);

    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Card(
            margin: EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: ListTile(
                leading: CardThumbnail(
                    gn: new GeoNote(1, "photo", 0, 0, "not used",
                        imgPath: imageUrl)),
                title: isTimeStamped
                    ? Text("Asked at: " +
                        timestamp2HHMMSS(
                            timestamp, recordingState.startOfRecording))
                    : Text("Not asked yet"),
                subtitle: ParagraphCard(questionText!),
                trailing: Icon(isTimeStamped
                    ? Icons.check_box
                    : Icons.check_box_outline_blank)),
          ),
/*          if (isTimeStamped)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),*/
        ],
      ),
    );
  }
}

String formatDuration(Duration d) {
  var seconds = d.inSeconds;
  final days = seconds ~/ Duration.secondsPerDay;
  seconds -= days * Duration.secondsPerDay;
  final hours = seconds ~/ Duration.secondsPerHour;
  seconds -= hours * Duration.secondsPerHour;
  final minutes = seconds ~/ Duration.secondsPerMinute;
  seconds -= minutes * Duration.secondsPerMinute;

  final List<String> tokens = [];
  if (days != 0) {
    tokens.add('${days}d');
  }
  if (tokens.isNotEmpty || hours != 0) {
    tokens.add('${hours}h');
  }
  if (tokens.isNotEmpty || minutes != 0) {
    tokens.add('${minutes}m');
  }
  tokens.add('${seconds}s');

  return tokens.join(':');
}

String timestamp2HHMMSS(int cardtimestamp, int startRec) {
  Duration difference = sinceStart(cardtimestamp, startRec);
  return formatDuration(difference);
}

Duration sinceStart(int cardtimestamp, int startRec) {
  var dCard = DateTime.fromMillisecondsSinceEpoch(cardtimestamp);
  var dStartRec = DateTime.fromMillisecondsSinceEpoch(startRec);
  Duration difference = dCard.difference(dStartRec);
  return difference;
}
