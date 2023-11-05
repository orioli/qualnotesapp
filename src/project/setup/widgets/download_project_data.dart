import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

Future<String> uploadZipToStorage(String prj_id, File zipFile) async {
  FirebaseStorage storage = FirebaseStorage.instance;
  String filePath = 'project_data/$prj_id/${zipFile.path.split('/').last}';
  Reference ref = storage.ref().child(filePath);
  await ref.putFile(zipFile);
  String downloadUrl = await ref.getDownloadURL();
  return downloadUrl;
}

Future<String> downloadProjectData(BuildContext context, String prj_id,
    {String? map_id, String? interview_id, String? schedule_id}) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference colRef =
      firestore.collection('projects').doc(prj_id).collection('collected-data');

  QuerySnapshot<Map<String, dynamic>>? querySnapshot;

  if (map_id != null) {
    querySnapshot = (await colRef.where('map_id', isEqualTo: map_id).get())
        as QuerySnapshot<Map<String, dynamic>>?;
  } else if (interview_id != null) {
    querySnapshot = (await colRef
        .where('interview_id', isEqualTo: interview_id)
        .get()) as QuerySnapshot<Map<String, dynamic>>?;
  } else if (schedule_id != null) {
    querySnapshot = (await colRef
        .where('schedule_id', isEqualTo: schedule_id)
        .get()) as QuerySnapshot<Map<String, dynamic>>?;
  } else {
    querySnapshot =
        (await colRef.get()) as QuerySnapshot<Map<String, dynamic>>?;
  }

  Directory tempDir = await getTemporaryDirectory();
  Directory downloadDir = Directory('${tempDir.path}/project_data');

  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }

  // Download the sch maps and interviews....
  for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot!.docs) {
    JsonEncoder encoder = JsonEncoder.withIndent('  ', encodeJson);
    String jsonText = encoder.convert(doc.data());
    File jsonFile = File('${downloadDir.path}/${doc.id}.json');
    debugPrint("1. now writting... " + jsonFile.path.toLowerCase());
    await jsonFile.writeAsString(jsonText);
  }

  // Zip the files
  List<int>? zipBytes =
      await createUserFriendlyZipFromDirectory(downloadDir.path);

  // Save the zip file
  File zipFile = File('${downloadDir.path}/project_data2.zip');
  await zipFile.writeAsBytes(zipBytes!);

  // Upload the zip file to Firebase Storage and get the download URL
  String downloadUrl = await uploadZipToStorage(prj_id, zipFile);

  // Delete the temporary files
  await downloadDir.delete(recursive: true);

  return downloadUrl;
}

Future<List<int>?> createUserFriendlyZipFromDirectory(String dirPath) async {
  Directory dir = Directory(dirPath);
  List<FileSystemEntity> files = await dir.list(recursive: true).toList();
  Archive archive = Archive();
  String htmlBody = '<html><head><title>Project Data</title></head><body>';

  for (FileSystemEntity file in files) {
    if (file is File && file.path.endsWith('.json')) {
      String pathInZip = p.relative(file.path, from: dirPath);
      String fileTitle = '';
      try {
        String fileContent = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(fileContent);
        fileTitle = data['title'];
      } catch (e) {
        print('Error reading file ${file.path}: $e');
      }
      htmlBody += '<p><a href="${pathInZip}">${fileTitle}</a></p>';
      List<int> bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(pathInZip, bytes.length, bytes));
    }
  }
  htmlBody += '</body></html>';
  archive
      .addFile(ArchiveFile('index.html', htmlBody.length, htmlBody.codeUnits));
  return ZipEncoder().encode(archive);
}

Future<List<int>?> createZipFromDirectory(String dirPath) async {
  Directory dir = Directory(dirPath);
  List<FileSystemEntity> files = await dir.list(recursive: true).toList();
  Archive archive = Archive();
  for (FileSystemEntity file in files) {
    if (file is File) {
      String pathInZip = file.path.substring(dir.path.length + 1);
      List<int> bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(pathInZip, bytes.length, bytes));
    }
  }
  return ZipEncoder().encode(archive);
}

dynamic encodeJson(dynamic item) {
  if (item is Timestamp) {
    return item.toDate().toIso8601String();
  }
  return item;
}

void showDownloadUrlDialog(BuildContext context, String downloadUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Download URL (Do not share)'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              SelectableText(downloadUrl),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Copy URL'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: downloadUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('URL copied to clipboard'),
                ),
              );
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class DownloadButton extends StatefulWidget {
  final Future<String> Function() onPressed;
  final String buttonText;

  DownloadButton({required this.onPressed, required this.buttonText});

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool isButtonDisabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: isButtonDisabled
              ? null
              : () async {
                  setState(() {
                    isButtonDisabled = true;
                  });

                  try {
                    final result = await widget.onPressed();
                    showDownloadUrlDialog(context, result);
                  } catch (error) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Error'),
                          content: Text('An error occurred: $error'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } finally {
                    setState(() {
                      isButtonDisabled = false;
                    });
                  }
                },
          child: Text(widget.buttonText),
        ),
      ],
    );
  }
}
