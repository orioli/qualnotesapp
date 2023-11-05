import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qualnotes/src/widgets/app_sizes.dart';
import 'package:qualnotes/src/widgets/strings.dart';

import '../app_state.dart';

class ScheduleQuestionImageWidget extends StatefulWidget {
  ScheduleQuestionImageWidget({
    required this.questionList,
    required this.state,
    required this.index,
    required this.prj_id,
    required this.sch_id,
    Key? key,
  }) : super(key: key);

  final String prj_id;
  final String sch_id;
  final int index;
  final ApplicationState? state;
  final List? questionList;

  @override
  State<ScheduleQuestionImageWidget> createState() =>
      _ScheduleQuestionImageWidgetState();
}

class _ScheduleQuestionImageWidgetState
    extends State<ScheduleQuestionImageWidget> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return (isLoading)
        ? Center(
            child: CircularProgressIndicator(),
          )
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.prj_id)
                .collection('collected-data')
                .doc(widget.sch_id)
                .get()
                .asStream(),
            builder: (context, snapshot) {
              List data = [];
              String image = "";
              try {
                data = snapshot.data?.get('questions');
                image = data[widget.index]['image'];
              } catch (e) {
                data = [];
                image = "";
              }
              return image.isNotEmpty
                  ? GestureDetector(
                      onTap: () => context.pushNamed('imageViewer',
                          queryParams: {'image': image}),
                      child: Hero(
                        tag: image,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(5),
                            bottomRight: Radius.circular(0),
                          ),
                          child: Image.network(
                            image,
                            fit: BoxFit.cover,
                            width: AppSizes.thumbnailImgHeight,
                            height: AppSizes.thumbnailImgHeight,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _addImage(),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 9), // Set the desired padding value
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        ),
                      ));
            },
          );
  }

  _addImage() async {
    if (widget.questionList?.isNotEmpty ?? false) {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png'],
      );
      if (result != null) {
        setState(() {
          isLoading = true;
        });
        try {
          await widget.state
              ?.addScheduleImage(
                  widget.prj_id,
                  widget.sch_id,
                  widget.questionList ?? [],
                  widget.index,
                  File(result.paths.first ?? ""))
              .whenComplete(() {
            setState(() {
              isLoading = false;
            });
          });
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(Strings.failedToUpload)));
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }
}
