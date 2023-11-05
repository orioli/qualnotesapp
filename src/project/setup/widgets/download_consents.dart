import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import './download_project_data.dart';

Future<String> downloadConsents(
  BuildContext context,
  String prj_id,
) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference colRef =
      firestore.collection('projects').doc(prj_id).collection('collected-data');

  QuerySnapshot<Map<String, dynamic>>? querySnapshot;

  querySnapshot = (await colRef.get()) as QuerySnapshot<Map<String, dynamic>>?;

  Directory tempDir = await getTemporaryDirectory();
  Directory downloadDir = Directory('${tempDir.path}/consent_data');

  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }

  // Download obtained_consents collection
  CollectionReference conRef = firestore
      .collection('projects')
      .doc(prj_id)
      .collection('obtained_consents');

  QuerySnapshot<Map<String, dynamic>>? conSnapshot =
      (await conRef.get()) as QuerySnapshot<Map<String, dynamic>>?;

  if (conSnapshot != null) {
    for (QueryDocumentSnapshot<Map<String, dynamic>> doc in conSnapshot.docs) {
      // Convert consent data to JSON and save it to a file
      JsonEncoder encoder = JsonEncoder.withIndent('  ', (dynamic item) {
        if (item is String) {
          return item;
        } else if (item == null) {
          return 'it was empty'; // Or any other default value
        } else {
          return item.toJson();
        }
      });

      String jsonText = encoder.convert(doc.data());
      File jsonFile = File('${downloadDir.path}/${doc.id}.json');
      debugPrint("2. now writting... " + jsonFile.path.toLowerCase());

      await jsonFile.writeAsString(jsonText);
    }
  }

  // Zip the files
  List<int>? zipBytes =
      await createUserFriendlyZipFromDirectory(downloadDir.path);

  // Save the zip file
  File zipFile = File('${downloadDir.path}/cosents.zip');
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
  String htmlBody = '<html><head><title>Obtained Cosnents</title></head><body>';

  for (FileSystemEntity file in files) {
    if (file is File && file.path.endsWith('.json')) {
      String pathInZip = p.relative(file.path, from: dirPath);
      String fileTitle = '';
      try {
        String fileContent = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(fileContent);
        //fileTitle = data['email'];
        fileTitle = data['email'].replaceAll('.', '_');
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
