import 'package:latlong2/latlong.dart';

// Every thing is a geonote

// TODO GeoMap.toMarkers()  GeoMap.toCards()
class GeoNote {
  int note_index;
  String note_type;
  num lat, lon;
  String text;
  bool deleteMe = false;
  String? imgPath;
  String? audioPath;
  DateTime? timestamp; // Add this line

  // Update the constructor to include the new fields
  GeoNote(
    this.note_index,
    this.note_type,
    this.lat,
    this.lon,
    this.text, {
    this.imgPath,
    this.audioPath,
    this.timestamp, // Add this line
  });

  // Add a method to convert the object to a map
  Map<String, dynamic> toMap() {
    return {
      'note_index': note_index,
      'note_type': note_type,
      'lat': lat,
      'lon': lon,
      'text': text,
      'deleteMe': deleteMe,
      'imgPath': imgPath,
      'audioPath': audioPath,
      'timestamp': timestamp?.millisecondsSinceEpoch, // Add this line
    };
  }

  LatLng getLatLon() {
    return LatLng(this.lat as double, this.lon as double);
  }

  @override
  String toString() {
    return "Text: $text Taken at lat: $lat , lon: $lon. Index: $note_index  audioPath $audioPath   imgPath $imgPath ";
  }

  Map<String, Object?> toMap3(String routeTitle) {
    var map = <String, Object?>{
      'note_index': note_index,
      'route_title': routeTitle,
      'note_type': note_type,
      'lat': lat,
      'lon': lon,
      'text': text,
      'img_path': imgPath,
      'timestamp': timestamp?.millisecondsSinceEpoch, // Add this line
    };
    return map;
  }

  Map<String, Object?> toMap2() {
    var map = <String, Object?>{
      'note_index': note_index,
      'note_type': note_type,
      'lat': lat,
      'lon': lon,
      'text': text,
      'img_path': imgPath,
      'timestamp': timestamp?.millisecondsSinceEpoch, // Add this line
    };
    return map;
  }

  // Add this method to your GeoNote class
  factory GeoNote.fromMap(Map<String, dynamic> noteData) {
    return GeoNote(
      noteData['note_index'],
      noteData['note_type'],
      noteData['lat'],
      noteData['lon'],
      noteData['text'],
      imgPath: noteData['imgPath'],
      audioPath: noteData['audioPath'],
      timestamp: noteData['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              noteData['timestamp']) // Add this line
          : null,
    );
  }

// New factory method for interviewNotes conversion
  factory GeoNote.fromInterviewNoteMap(Map<String, dynamic> noteData) {
    return GeoNote(
      noteData['note_index'],
      noteData['note_type'],
      noteData['lat'],
      noteData['lon'],
      noteData['text'],
      imgPath: noteData['img'], // Use 'img' here instead of 'imgPath'
      audioPath: noteData['audioPath'],
      timestamp: noteData['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(noteData['timestamp'])
          : null,
    );
  }
  GeoNote.copy(GeoNote other)
      : this(
          other.note_index,
          other.note_type,
          other.lat,
          other.lon,
          other.text,
          imgPath: other.imgPath,
          audioPath: other.audioPath,
          timestamp: other.timestamp, // Add this line
        );
}
