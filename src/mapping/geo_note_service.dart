import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'geonote.dart';

class GeoNoteService {
  String getFirebasePath(
      String prj_id, String map_id, String fileType, String noteIndex) {
    return 'projects/${prj_id}/maps/${map_id}/$fileType/$noteIndex';
  }

  DocumentReference getRef(String prj_id, String doc_id) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(prj_id)
        .collection('collected-data')
        .doc(doc_id);
  }

  Future<String> downloadFile(String url, String fileName) async {
    final dio = Dio();
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    await dio.download(url, filePath);
    return filePath;
  }

  Future<List<GeoNote>> fetchGeoNotes(String prj_id, String map_id) async {
    DocumentReference ref = getRef(prj_id, map_id);
    DocumentSnapshot mapDocSnapshot = await ref.get();
    Map<String, dynamic>? data = mapDocSnapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('geoNotesList')) {
      List<dynamic> gNotesData = data['geoNotesList'];
      List<GeoNote> gNotes =
          gNotesData.map((noteData) => GeoNote.fromMap(noteData)).toList();

      return gNotes;
    } else {
      return [];
    }
  }

  Future<String> downloadAndStoreFile(String fileUrl, String filename) async {
    final dio = Dio();
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    await dio.download(fileUrl, filePath);
    return filePath;
  }

  // THIS FUNCTION REPLACES FIREBASE FIRESTORAGE LINKS BY LOCAL FILEPATHS
  Future<List<GeoNote>> getNotesFromFirebase(
      String prj_id, String doc_id) async {
    DocumentReference ref = getRef(prj_id, doc_id);
    DocumentSnapshot mapDocSnapshot = await ref.get();
    Map<String, dynamic>? data = mapDocSnapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('geoNotesList')) {
      List<dynamic> gNotesData = data['geoNotesList'];
      List<GeoNote> gNotes =
          gNotesData.map((noteData) => GeoNote.fromMap(noteData)).toList();

      // Download the related files for each GeoNote
      /*
      for (int index = 0; index < gNotes.length; index++) {
        if (gNotes[index].imgPath != null) {
          String localImagePath = await downloadAndStoreFile(
              gNotes[index].imgPath!, 'image_$index');
          gNotes[index].imgPath = localImagePath;
        }
        if (gNotes[index].audioPath != null) {
          String localAudioPath = await downloadAndStoreFile(
              gNotes[index].audioPath!, 'audio_$index');
          gNotes[index].audioPath = localAudioPath;
        }
      }
      */
      return gNotes;
    } else {
      return [];
    }
  }
}
