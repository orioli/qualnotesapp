import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qualnotes/src/interview/widgets/image_view.dart';
import 'package:qualnotes/src/project/setup/widgets/reflection.dart';
import 'package:video_player/video_player.dart';

import 'widgets/interview_question_card_UI.dart';

class InterviewPlayer extends StatefulWidget {
  final String? prj_id;
  final String? interview_id;
  final String? interview_title;
  final String? recording;
  final String? questionsJson;

  InterviewPlayer({
    Key? key,
    required String this.prj_id,
    required String this.interview_id,
    required String this.interview_title,
    required String this.recording,
    required String this.questionsJson,
  });

  @override
  State<InterviewPlayer> createState() => _InterviewPlayerState();
}

class _InterviewPlayerState extends State<InterviewPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  late List<Map<String, dynamic>> questions = [];
  int _selectedCardIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.questionsJson != null && !(widget.questionsJson == '')) {
      var decoded = jsonDecode(widget.questionsJson!);
      questions =
          decoded is List ? List<Map<String, dynamic>>.from(decoded) : [];
    }
    _controller = VideoPlayerController.network(widget.recording!);
    _initializeVideoPlayerFuture = _controller.initialize();
    _initializeVideoPlayerFuture.then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var interview_title = widget.interview_title;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(interview_title!),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return buildMainWidget(); //SingleChildScrollView(child: _videoView());
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget buildMainWidget() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth > constraints.maxHeight) {
        // Screen width > height, use landscape layout (side by side)
        return Row(
          children: [
            Flexible(child: _videoVideFlex(verticalLayout: true)),
            Flexible(child: _questionView()),
          ],
        );
      } else {
        return Column(
          children: [
            Flexible(child: _videoVideFlex()),
            Flexible(child: _questionView()),
          ],
        );
      }
    });
  }

  Widget _questionView() {
    return QuestionsList(
      questions: questions,
      controller: _controller,
    );
  }

  Widget _videoVideFlex({bool verticalLayout = false}) {
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment:
              verticalLayout ? Alignment.bottomLeft : Alignment.bottomCenter,
          children: <Widget>[
            VideoPlayer(_controller),
            _ControlsOverlay(controller: _controller),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            verticalLayout
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _buildControlWidgets(),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _buildControlWidgets(),
                  ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildControlWidgets() {
    return [
      ReflectionButton(
        prj_id: widget.prj_id!,
        interviewId: widget.interview_id,
      ),
      VideoElapsedTime(controller: _controller),
      ElevatedButton(
        onPressed: _playPauseVideo,
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    ];
  }

  void _playPauseVideo() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    setState(() {});
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 50),
        reverseDuration: const Duration(milliseconds: 200),
      )
    ]);
  }
}

class QuestionsList extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final VideoPlayerController controller;

  QuestionsList({required this.questions, required this.controller});

  @override
  _QuestionsListState createState() => _QuestionsListState();
}

class _QuestionsListState extends State<QuestionsList> {
  int? _selectedCardIndex;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.questions.length,
      itemBuilder: (BuildContext context, int index) {
        final String? tt = widget.questions[index]['timestamp'];

        return GestureDetector(
          onTap: () => _handleCardTap(index, tt),
          child: DisplayQuestionCard(
            questionText: widget.questions[index]['text'],
            imageUrl: widget.questions[index]['img'],
            timestamp: tt,
            accent: index == _selectedCardIndex,
          ),
        );
      },
    );
  }

  void _handleCardTap(int index, String? timestamp) {
    setState(() {
      _selectedCardIndex = index;
      if (timestamp == null ||
          timestamp.isEmpty ||
          timestamp.startsWith(RegExp(r'^[A-Za-z]'))) {
        return;
      } else {
        final time = _parseOriTimeFormat(timestamp);
        widget.controller.seekTo(time);
        if (!widget.controller.value.isPlaying) {
          widget.controller.play();
        }
      }
    });
  }

  Duration _parseOriTimeFormat(String timestamp) {
    Duration gotoTime;
    List<String> parts = timestamp.split(':');
    if (parts.length == 2 && parts[0].contains('m') && parts[1].contains('s')) {
      int minutes = int.parse(parts[0].replaceAll('m', ''));
      int seconds = int.parse(parts[1].replaceAll('s', ''));
      gotoTime = Duration(minutes: minutes, seconds: seconds);
    } else if (timestamp.contains(':')) {
      gotoTime = Duration(
        hours: int.parse(timestamp.split(':')[0]),
        minutes: int.parse(timestamp.split(':')[1]),
        seconds: int.parse(timestamp.split(':')[2]),
      );
    } else if (timestamp.contains(':')) {
      gotoTime = Duration(
        hours: int.parse(timestamp.split(':')[0]),
        minutes: int.parse(timestamp.split(':')[1]),
        seconds: int.parse(timestamp.split(':')[2]),
      );
    } else if (timestamp.contains('h') &&
        timestamp.contains('m') &&
        timestamp.contains('s')) {
      List<String> parts = timestamp.split(' ');

      int hours = int.parse(parts[0].replaceAll('h', ''));
      int minutes = int.parse(parts[1].replaceAll('m', ''));
      int seconds = int.parse(parts[2].replaceAll('s', ''));

      gotoTime = Duration(hours: hours, minutes: minutes, seconds: seconds);
    } else if (timestamp.contains('h') && timestamp.contains('m')) {
      List<String> parts = timestamp.split(' ');

      int hours = int.parse(parts[0].replaceAll('h', ''));
      int minutes = int.parse(parts[1].replaceAll('m', ''));

      gotoTime = Duration(hours: hours, minutes: minutes);
    } else if (timestamp.contains('h') && timestamp.contains('s')) {
      List<String> parts = timestamp.split(' ');

      int hours = int.parse(parts[0].replaceAll('h', ''));
      int seconds = int.parse(parts[1].replaceAll('s', ''));

      gotoTime = Duration(hours: hours, seconds: seconds);
    } else if (timestamp.contains('h')) {
      int hours = int.parse(timestamp.replaceAll('h', ''));
      gotoTime = Duration(hours: hours);
    } else if (timestamp.contains('m') && timestamp.contains('s')) {
      List<String> parts = timestamp.split(' ');

      int minutes = int.parse(parts[0].replaceAll('m', ''));
      int seconds = int.parse(parts[1].replaceAll('s', ''));

      gotoTime = Duration(minutes: minutes, seconds: seconds);
    } else if (timestamp.contains('m')) {
      int minutes = int.parse(timestamp.replaceAll('m', ''));
      gotoTime = Duration(minutes: minutes);
    } else {
      int seconds = int.parse(timestamp.replaceAll('s', ''));
      gotoTime = Duration(seconds: seconds);
    } //final duration =
    return gotoTime;
  }
}

class VideoElapsedTime extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoElapsedTime({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, VideoPlayerValue value, _) {
        final String hours =
            (value.position.inHours).toString().padLeft(2, '0');
        final String minutes =
            (value.position.inMinutes % 60).toString().padLeft(2, '0');
        final String seconds =
            (value.position.inSeconds % 60).toString().padLeft(2, '0');
        return elapsedTimeInScreen('$hours:$minutes:$seconds');
      },
    );
  }
}
