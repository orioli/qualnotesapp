// Copyright 2023 Jose Berengueres. All rights reserved.
// ***
// ***
import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';
import 'package:qualnotes/src/project/setup/widgets/download_consents.dart';
import 'package:qualnotes/src/project/setup/widgets/download_project_data.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'package:qualnotes/src/widgets/widgets.dart';
import '../team/invite_widgets.dart';
import 'widgets/file_container_widget.dart';
import 'widgets/header_first_text.dart';
import 'widgets/reflection.dart';

class ProjectStepper extends StatefulWidget {
  const ProjectStepper({super.key, required this.prj_id});

  final String prj_id;

  @override
  State<ProjectStepper> createState() => _ProjectStepperState();
}

class _ProjectStepperState extends State<ProjectStepper> {
  int _index = 0;
  final Directories directories = Directories();
  final int _maxStep = 5 - 1;
  bool file1 = false;
  bool file2 = false;
  Future<String>? _downloadURLprojectDataFuture;
  Future<String>? _downloadURLConsentsFuture;

  @override
  void initState() {
    getValid();
    super.initState();
  }

  getValid() {
    FirebaseFirestore.instance
        .collection('/projects/')
        .doc(widget.prj_id)
        .snapshots()
        .listen((event) {
      String? fileInfo = event.data()?['info_statement'] ?? "";
      String? fileCons = event.data()?['consent_form'] ?? "";

      if (fileInfo!.isNotEmpty) {
        if (mounted)
          setState(() {
            file1 = true;
          });
      }
      if (fileCons!.isNotEmpty) {
        if (mounted)
          setState(() {
            file2 = true;
          });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(builder: (context, value, _) {
      return WillPopScope(
        onWillPop: () {
          return Future.value(value.isFileUploading != 0 ? false : true);
        },
        child: Theme(
          data: ThemeData(
              colorScheme: ColorScheme.light(
                  primary: Colors.blueAccent, secondary: Colors.green)),
          child: Align(
            alignment: Alignment.topLeft,
            child: Stepper(
              currentStep: _index,
              margin: const EdgeInsetsDirectional.only(
                start: 60.0,
                end: 14.0,
                bottom: 0.0,
                top: 0.0,
              ),
              onStepCancel: () {
                if (_index > 0) {
                  setState(() {
                    _index -= 1;
                  });
                }
              },
              onStepContinue: () {
                if (_index < (_maxStep)) {
                  setState(() {
                    _index += 1;
                  });
                }
              },
              onStepTapped: (int index) {
                setState(() {
                  _index = index;
                });
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Row(
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text(Strings.back.toUpperCase()),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(),
                      onPressed: details.onStepContinue,
                      child: const Text(Strings.nextStep),
                    ),
                  ],
                );
              },
              steps: mySteps,
            ),
          ),
        ),
      );
    });
  }

  List<Step> get mySteps {
    return <Step>[
      Step(
        title: IconAndDetailStepper(
            Icons.verified_user_outlined, Strings.ethicsPortal),
        content: Consumer<ApplicationState>(
          builder: (context, value, _) {
            return Container(
              alignment: Alignment.centerLeft,
              child: kIsWeb
                  ? onlyViaApp()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeaderText(
                          onTap: () => _pickFile(1, widget.prj_id, value),
                          id: widget.prj_id,
                          fieldKey: 'info_statement',
                          title: '${Strings.projectInfoStatement} (.pdf)',
                        ),
                        value.isFileUploading == 1
                            ? _circularIndicator()
                            : GetSingleFiles(1, file1),
                        HeaderText(
                          onTap: () => _pickFile(2, widget.prj_id, value),
                          id: widget.prj_id,
                          fieldKey: 'consent_form',
                          title: '${Strings.praticipantInfoStatement} (.pdf)',
                        ),
                        value.isFileUploading == 2
                            ? _circularIndicator()
                            : GetSingleFiles(2, file2),
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                    style: const TextStyle(fontSize: 16),
                                    Strings.consentForms)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: allowConsentSigning
                                      ? Colors.green
                                      : Colors.grey),
                              onPressed: () {
                                if (allowConsentSigning)
                                  context.pushNamed('consent',
                                      extra: widget.prj_id);
                              },
                              child: Text(
                                Strings.signForm,
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
      Step(
        title: IconAndDetailStepper(
            Icons.file_copy_outlined, Strings.additionalProjectDocuments),
        content: Consumer<ApplicationState>(
          builder: (context, value, _) {
            return Container(
              alignment: Alignment.centerLeft,
              child: kIsWeb
                  ? onlyViaApp()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _pickFile(3, widget.prj_id, value),
                          child: Text(
                            Strings.uploadAdditionalDocuments,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        value.isFileUploading == 3
                            ? _circularIndicator()
                            : GetMultiFiles(3),
                      ],
                    ),
            );
          },
        ),
      ),
      Step(
        title: IconAndDetailStepper(
            Icons.group_add_outlined, Strings.inviteByLink),
        content: Container(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Add this line

            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  final link = await generateInvitationLink(widget.prj_id);

                  await showCopyToClipboardDialog(context, link);
                  print(link);
                },
                child: Text('Web Link Invite'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  final link = await generateInvitationLink(widget.prj_id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRCodeScreen(link: link),
                    ),
                  );
                },
                child: Text('QR code Invite'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRInviteScanner(),
                    ),
                  );
                },
                child: Text('Scan a Code'),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
      Step(
        title: IconAndDetailStepper(
            Icons.library_books_outlined, Strings.dataCollectionPortal),
        content: Container(
            alignment: Alignment.centerLeft,
            child: const Paragraph(Strings.mansplain)),
      ),
      Step(
        title: IconAndDetailStepper(
            Icons.system_update_alt_outlined, Strings.postDataCollection),
        content: Container(
          alignment: Alignment.topLeft,
          child: kIsWeb
              ? onlyViaApp()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Add this line

                  children: [
                    DownloadButton(
                      onPressed: () => downloadConsents(context, widget.prj_id),
                      buttonText: 'Download consent forms',
                    ),
                    SizedBox(height: 10),
                    DownloadButton(
                      onPressed: () =>
                          downloadProjectData(context, widget.prj_id),
                      buttonText: 'Download collected data',
                    ),
                    SizedBox(height: 10),
                    ReflectionButton(
                      prj_id: widget.prj_id,
                    ),
                    SizedBox(height: 10),
                  ],
                ),
        ),
      ),
    ];
  }

  bool get allowConsentSigning => file2 && file2;

  Padding _circularIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircularProgressIndicator.adaptive(),
    );
  }

  void _pickFile(int ind, String id, ApplicationState value) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: ind == 3 ? true : false,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      if (value.isFileUploadingError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(Strings.pdfHasNotBeenSaved)));
      }

      setState(() {
        List<File>? files;

        // TODO: how to implement case upload file via web?
        if (kIsWeb) {
          //Uint8List? fileBytes = result.files.first.bytes;
          //String fileName = result.files.first.name;

          //files = result.files.map((file) {
          //  final blob = file.bytes;
          //  if (blob != null) {
          //  return File.fromBytes(blob);          } else {
          //    return File(''); // Empty file for handling the null case
          //  }
          // }).cast<File>().toList();
        } else {
          files = result.paths.map((path) => File(path ?? '')).toList();
          directories.filesMap[ind] = files;
          value.submitDataToFirebase(
            index: ind,
            docId: widget.prj_id,
            fileList: files,
          );
        }
      });
    }
  }

  // Upload file

  Widget GetSingleFiles(int ind, bool isUpload) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9 - 20,
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('/projects/')
                  .doc(widget.prj_id)
                  .snapshots()
                  .asBroadcastStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                List<Widget> widgetList = [];
                if (snapshot.data?.exists ?? false) {
                  try {
                    var docData2 = snapshot.data?.data() as Map?;
                    final String? file =
                        docData2?[ind == 1 ? "info_statement" : 'consent_form'];
                    if (file != null) {
                      widgetList.add(FileContainerWidget(
                        file: file,
                      ));
                    }
                  } catch (e) {
                    log(e.toString());
                  }
                }
                return Row(
                  children: widgetList,
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget GetMultiFiles(
    int ind,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9 - 20,
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('/projects/')
            .doc(widget.prj_id)
            .get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          List<Widget> widgetList = [];
          if (snapshot.data?.exists ?? false) {
            try {
              var docData2 = snapshot.data?.data() as Map?;
              final List info = docData2?['files'] ?? [];
              if (snapshot.data != null) {
                for (int i = 0; i < info.length; i++) {
                  widgetList.add(
                    FileContainerWidget(
                      file: info[i],
                    ),
                  );
                }
              }
            } catch (e) {
              log(e.toString());
            }
          }
          return Wrap(
            direction: Axis.vertical,
            alignment: WrapAlignment.spaceBetween,
            children: widgetList,
          );
        },
      ),
    );
  }
}

class onlyViaApp extends StatelessWidget {
  const onlyViaApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Paragraph(
      '⚠️ this content accessible only via App',
    );
  }
}

class Directories {
  Map<int, List<File>> filesMap = {};

  Directories({
    this.filesListFirst = const [],
    this.filesListThird = const [],
    this.filesListSec = const [],
  });

  List filesListFirst;
  List filesListSec;
  List filesListThird;
}
