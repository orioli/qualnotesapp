import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';

class RecordingWidget extends StatelessWidget {
  RecordingWidget({
    Key? key,
    required this.maxh,
    required this.cameraView,
    required this.controller,
    required this.isShow,
    required this.isCamera,
  }) : super(key: key);

  final Widget cameraView;
  double maxh;
  final bool isCamera;
  final bool isShow;
  final CustomTimerController controller;

  @override
  Widget build(BuildContext context) {
    return isShow
        ? Container(
            color: Colors.black,
            child: Column(
              children: [
                CustomTimer(
                  controller: controller,
                  builder: (state, remaining) {
                    return Container(
                      color: Colors.black,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 3, top: 4, bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.fiber_manual_record,
                                color: Colors.red, size: 17),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              "${remaining.hours}:${remaining.minutes}:${remaining.seconds}",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                isCamera ? cameraView : SizedBox.shrink(),
              ],
            ))
        : SizedBox.shrink();
  }
}
