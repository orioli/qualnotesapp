// Copyright 2022-2023 Jose Berengeueres, Qualnotes AB.
// Adapted from livelocation tutorial
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/app_state.dart';
import 'package:qualnotes/src/mapping/widgets.dart';
import 'package:qualnotes/src/pobs/pobs_widgets.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import '../map_controller_service.dart';
import '../mapping/audio_recorder.dart';
import '../mapping/camera_utils.dart';
import '../mapping/geonote.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../mapping/audio_player.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as Path;
import '../mapping/geo_note_service.dart';
import '../widgets/rotate_alert.dart';
import '../widgets/widgets.dart';
import 'package:intl/intl.dart';

class MakeObs extends StatefulWidget {
  //static const String route = '/live_location';
  final String? prj_id;
  final String title;
  final String obs_id;
  final String editExistingPoints;
  final bool showMap;

  MakeObs({
    required this.title,
    required this.prj_id,
    required this.obs_id,
    this.editExistingPoints = 'false',
    this.showMap = false,
    Key? key,
  }) : super(key: key);

  @override
  _MakeObsState createState() => _MakeObsState(showMap: this.showMap);
}

class _MakeObsState extends State<MakeObs> with TickerProviderStateMixin {
  Future<List<GeoNote>>? geoNotesFuture;
  final GeoNoteService geoNoteService = GeoNoteService();

  List<GeoNote> myGeoNotes = []; // anotated - only these are saved
  List<LatLng> _myRoutePoint = []; // sampled every5 s

  LocationData? _currentLocation;
  MapController? _mapController;

  StreamSubscription<LocationData>? _locationSubscription;

  String? _serviceError = '';
  int _selectedMenuIndex = 0;
  bool playMode = false;
  bool _liveUpdate = true;
  bool _paused = false;
  bool _permission = false;
  double highPerc = 0.90;
  bool _showMap;
  bool changesPendingSave = false;
  int _selectedCardIndex = -1;

  _MakeObsState({bool showMap = false}) : _showMap = showMap;

// Create a DateFormat
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

// Use the format method to format the date

  var interActiveFlags =
      InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom;

  final Location _locationService = Location();

  @override
  void dispose() {
    _locationSubscription?.cancel();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mapController == null) {
      _mapController = Provider.of<MapLocationService>(context, listen: false)
          .mapController!;
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.editExistingPoints == 'true') {
      geoNotesFuture =
          geoNoteService.getNotesFromFirebase(widget.prj_id!, widget.obs_id);
      debugPrint("called fetchGeoNotesReplaceLinksByLocalPaths  with " +
          widget.prj_id.toString() +
          " and  " +
          widget.obs_id.toString() +
          " and returned " +
          geoNotesFuture.toString());
    }
    initLocationService();

    // _mapController = MapController();  // *** moved this to build look down
    if (_mapController == null) {
      _mapController = Provider.of<MapLocationService>(context, listen: false)
          .mapController!;
    }
  }

  int myNotesLength(List<GeoNote> geoNotesList) {
    // Use the 'where' method to filter the list
    List<GeoNote> filteredGeoNotesList =
        geoNotesList.where((gn) => gn.note_type != "routepoint").toList();

    return filteredGeoNotesList.length;
  }

  Future<void> _addAudioNote(BuildContext context) async {
    final audioPath = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AudioRecorder(
              onStop: (path) {})), // Passing an empty callback for onStop
    );

    final gn = GeoNote(
      myNotesLength(myGeoNotes),
      "audio",
      _myRoutePoint.last.latitude,
      _myRoutePoint.last.longitude,
      "",
      timestamp: DateTime.now(),
    );
    gn.audioPath = audioPath;
    setState(() {
      myGeoNotes.add(gn);
    });
  }

  Future<void> _editAudioNote(BuildContext context, GeoNote gn) async {
    debugPrint("audiopath = " + gn.audioPath.toString());
    TextEditingController _controller = TextEditingController(text: gn.text);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Add this line
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * highPerc,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align to the top
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    gn.audioPath!.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: OrioliAudioPlayer(
                              source: gn.audioPath!,
                              onDelete: () {
                                Navigator.pop(context);
                              },
                            ),
                          )
                        : const Text("cant find the audio!!"),
                    SizedBox(height: 5),
                    //SizedBox(height: 10),
                    _textEditorControlBar(context, gn, _controller,
                        withImageZoom: false),
                    _textEditorBox(_controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addPhotoNote(BuildContext context) async {
    final imgPath = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => TakePictureScreen()));

    final gn = GeoNote(
      myNotesLength(myGeoNotes),
      "photo",
      _myRoutePoint.last.latitude,
      _myRoutePoint.last.longitude,
      "",
      timestamp: DateTime.now(),
    );
    gn.imgPath = imgPath;
    setState(() {
      myGeoNotes.add(gn);
    });
  }

  Widget _textEditorControlBar(
      context, GeoNote gn, TextEditingController _controller,
      {bool withImageZoom = false}) {
    return Row(
      children: [
        ElevatedButton(
          child: const Icon(Icons.delete_outline),
          onPressed: () {
            setState(() {
              myGeoNotes.remove(gn);
            });
            Navigator.pop(context);
          },
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (withImageZoom) ...[
                ElevatedButton(
                  child: const Icon(Icons.zoom_in),
                  onPressed: () {
                    showImageFullScreen(context, gn);
                  },
                ),
                SizedBox(width: 16),
              ],
              ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () {
                  gn.text = _controller.text; // in dart by reference
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textEditorBox(TextEditingController _controller) {
    return TextFormField(
        controller: _controller,
        autofocus: true,
        minLines:
            3, // any number you need (It works as the rows for the textarea)
        keyboardType: TextInputType.multiline,
        maxLines: 3,
        decoration: const InputDecoration(
          fillColor: Colors.white,
          filled: true,
          hintText: Strings.enterSomething,
          contentPadding: EdgeInsets.all(10.0),
          border: OutlineInputBorder(
            borderSide: BorderSide(),
          ),
        ));
  }

  Future<void> _editPhotoNote(BuildContext context, GeoNote gn) async {
    TextEditingController _txtController = TextEditingController(text: gn.text);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Add this line

      builder: (BuildContext context) {
        return SizedBox(
            height: MediaQuery.of(context).size.height * highPerc,
            child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: localOrNetworkProvider(gn.imgPath!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Align to the top
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            //_imgThumb(gn),
                            SizedBox(height: 5),
                            _textEditorControlBar(context, gn, _txtController,
                                withImageZoom: true),
                            _textEditorBox(_txtController),
                          ],
                        ),
                      ),
                    ],
                  ),
                )));
      },
    );
  }

  Future<void> _addTextNote(BuildContext context) async {
    TextEditingController _txtController = TextEditingController(text: '');
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * highPerc,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align to the top
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          child: const Text('Save'),
                          onPressed: () {
                            GeoNote newNote = GeoNote(
                                myNotesLength(myGeoNotes),
                                "text",
                                _myRoutePoint.last.latitude,
                                _myRoutePoint.last.longitude,
                                _txtController.text,
                                timestamp: DateTime.now());
                            setState(() {
                              myGeoNotes.add(newNote);
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    _textEditorBox(_txtController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editTextNote(BuildContext context, GeoNote gn) async {
    TextEditingController _txtController = TextEditingController(text: gn.text);
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * highPerc,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align to the top
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    _textEditorControlBar(context, gn, _txtController,
                        withImageZoom: false),
                    _textEditorBox(_txtController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _downloadFile(String url, String fileName) async {
    final dio = Dio();
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    await dio.download(url, filePath);
    return filePath;
  }

  String _getBucketPath(GeoNote note) {
    String fileExtension = '';
    if (note.note_type == "image" && note.imgPath != null) {
      fileExtension = Path.extension(note.imgPath!);
    } else if (note.note_type == "audio" && note.audioPath != null) {
      fileExtension = Path.extension(note.audioPath!);
    }
    return 'projects/${widget.prj_id}/obs/${widget.obs_id}/${note.note_index}$fileExtension';
  }

  Future<void> downloadAllGeoNotesForEditting() async {
    DocumentReference ref = _getObsRef();
    DocumentSnapshot mapDocSnapshot = await ref.get();
    Map<String, dynamic>? data = mapDocSnapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('geoNotesList')) {
      List<dynamic> gNotesData = data['geoNotesList'];
      List<GeoNote> gNotes =
          gNotesData.map((noteData) => GeoNote.fromMap(noteData)).toList();

      debugPrint("yyy  note.audioPath.toString() " + gNotes.toString());

      // New: Download all images and audio for editing purposes... Nto very efficeint...
      final storage = FirebaseStorage.instance;
      for (var note in gNotes) {
        if (note.imgPath != null) {
          final imgRef = storage.ref().child(note.imgPath.toString());
          String url = await imgRef.getDownloadURL();
          Uri uri = Uri.parse(url);
          String path = uri.path;
          String fileName = Path.basename(path);
          note.imgPath = await _downloadFile(url, fileName);
        }
        // TODO FOR SOEM REASON THIS PART FOR AUDIO DOE SNOT WORK
        if (false || note.audioPath != null) {
          final audioRef = storage.ref().child(note.audioPath.toString());
          String url = await audioRef.getDownloadURL();
          Uri uri = Uri.parse(url);
          String path = uri.path;
          String fileName = Path.basename(path);
          note.audioPath = await _downloadFile(url, fileName);
        }
      }
      debugPrint("dddd mapData " + gNotes.toString());
      // make the routepoints...
      List<LatLng> routePoints = gNotes
          .map((gNote) => LatLng(gNote.lat.toDouble(), gNote.lon.toDouble()))
          .toList();
      setState(() {
        myGeoNotes = gNotes;
        _myRoutePoint = routePoints;
        debugPrint("zzzz mapData " + gNotes.toString());
      });
    } else {
      // Handle the case when the 'geoNotesList' field doesn't exist
    }
  }

  Future<void> _saveGeoNotesToFirebase(
      List<GeoNote> myGeoNotesForUpload) async {
    final storage = FirebaseStorage.instance;

    for (var note in myGeoNotesForUpload) {
      // first upload iamges or audios to storage and replace the deivice filepath by the newly obtiamed storage url
      if (note.imgPath != null &&
          !(note.imgPath!.startsWith('http://') ||
              note.imgPath!.startsWith('https://'))) {
        final imgRef = storage.ref().child(_getBucketPath(note));
        try {
          await imgRef.putFile(File(note.imgPath!));
          note.imgPath = await imgRef.getDownloadURL();
          debugPrint("xxxx  note. img path  " + note.imgPath.toString());
        } catch (e) {
          debugPrint("Failed to upload image: $e");
          // Handle the error...
        }
      }

      if (note.audioPath != null &&
          !(note.audioPath!.startsWith('http://') ||
              note.audioPath!.startsWith('https://'))) {
        try {
          final audioRef = storage.ref().child(_getBucketPath(note));
          Uri audioUri = Uri.parse(note.audioPath!);
          String audioPath = audioUri.toFilePath();
          File audioFile = File(audioPath);
          await audioRef.putFile(audioFile);
          note.audioPath = await audioRef.getDownloadURL();
        } catch (e) {
          debugPrint("Failed to upload audio: $e");
          debugPrint("5 note.audioPath " + note.audioPath.toString());
        }
      }
    }
    final mapData = {
      'geoNotesList': myGeoNotesForUpload.map((note) => note.toMap()).toList(),
    };

    debugPrint("xxx mapData " + mapData.toString());
    final ref = _getObsRef();
    try {
      await ref.set(mapData, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to update Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update Firestore: $e"),
        ),
      );
    }
  }

  Future<void> _saveObsToFirebase() async {
    //final delayTimer = Future.delayed(Duration(seconds: 2));
    try {
      // Save the map and wait for both the saving and the timer to complete.
      if (myGeoNotes.isNotEmpty) {
        ApplicationState appState =
            Provider.of<ApplicationState>(context, listen: false);
        if (!appState.isOnline) {
          debugPrint("No internet connection. Not attempting to save map.");
          // Optionally, you can show a SnackBar or Dialog here to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "No internet connection. Not attempting to save map. Try later with wifi?"),
            ),
          );
          return;
        }
        _showSavingDialog();
        // shallow copyyyy !! donot use! var myGeoNotesForUpload = List<GeoNote>.from(myGeoNotes);
        var myGeoNotesForUpload =
            myGeoNotes.map((note) => GeoNote.copy(note)).toList();
        await _saveGeoNotesToFirebase(myGeoNotesForUpload);
        Navigator.of(context).pop();
        _showTaskCompleted();
        changesPendingSave = false; //reset
        //_navigateBackToProjectFiles();
      } else {
//        ScaffoldMessenger.of(context).showSnackBar(
        //        SnackBar(
        //        content: Text("Empyt Obs. Not saving it."),
        //    ),
        //);
      }
    } catch (e) {
      debugPrint(e.toString());

      _handleSaveObsError();
    }
  }

  void _showTaskCompleted() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content:
              Text("Uploaded complete. You can now continue or exit safely."),
          actions: <Widget>[
            ElevatedButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSavingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // This right here
          ),
          child: Container(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20), // You can adjust this as needed
                  Text(
                      "Uploading your map contents to cloud, ☕ time for a coffe break ? \n (it might take up to 5 to 10 minutes... ) "),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DocumentReference _getObsRef() {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.prj_id)
        .collection('collected-data')
        .doc(widget.obs_id);
  }

  void _handleSaveObsError() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to save map."),
      ),
    );
  }

  Future<void> _AddNoteToObs(BuildContext context) async {
    changesPendingSave = true;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text(Strings.whatDoWeAdd),
        message: const Text(Strings.chooseOne),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addTextNote(context);
            },
            child: const Text(Strings.text),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addAudioNote(context); //createAudioNote(context);
            },
            child: Text(Strings.audio.toLowerCase()),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addPhotoNote(context);
            },
            child: const Text(Strings.photo),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(Strings.cancel.toLowerCase()),
          )
        ],
      ),
    );
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedMenuIndex = index;
    });
    if (_selectedMenuIndex == 0) {
      _paused = !_paused;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: _paused
            ? const Text(Strings.nowPausedPrompt)
            : const Text(Strings.nowRecordingPrompt),
      ));
      setState(() {});
    }
    if (_selectedMenuIndex == 1 && !_paused) {
      _AddNoteToObs(context);
    }
    if (!kIsWeb && _selectedMenuIndex == 2) {
      _saveObsToFirebase();
    }
    //}
  } // on item tapped

  void initLocationService() async {
    // var connectivityResult = await (Connectivity().checkConnectivity());
    if (_permission) {
      await _locationService.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 5000, // to save battery
      );
    }
    debugPrint("here");
    LocationData? location;
    bool serviceEnabled;
    bool serviceRequestResult;

    try {
      serviceEnabled = await _locationService.serviceEnabled();
      debugPrint("here1");
      if (serviceEnabled) {
        final permission = await _locationService.requestPermission();
        //debugPrint("here2");
        setState(() {
          _permission = permission == PermissionStatus.granted;
          //debugPrint("here3");
        });

        if (_permission) {
          location = await _locationService.getLocation();
          _currentLocation = location;

          //_locationService.onLocationChanged
          //  .listen((LocationData result) async {

          _locationSubscription = _locationService.onLocationChanged
              .listen((LocationData result) async {
            if (mounted) {
              setState(() {
                _currentLocation = result;
                //debugPrint( _myRoutePoint.toString());
                // If Live Update is enabled, move map center

                if (!_paused) {
                  // ##1
                  double? lat = _currentLocation!.latitude!;
                  double? lon = _currentLocation!.longitude!;

                  // this to display route now
                  _myRoutePoint.add(LatLng(lat, lon));

                  // this to save routepoint as dummy geonote
                  final routeNote = GeoNote(
                    myGeoNotes
                        .length, // this will not be used fro routepont type points
                    "routepoint",
                    lat,
                    lon,
                    "",
                    timestamp: DateTime.now(),
                  );
                  myGeoNotes.add(routeNote);

                  if (_liveUpdate) {
                    //_mapController.move(LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!), _mapController.zoom);
                    _animatedMapMove(
                        LatLng(_currentLocation!.latitude!,
                            _currentLocation!.longitude!),
                        _mapController!.zoom);
                  }
                }
              }); //setstate
            }
          });
        }
      } else {
        serviceRequestResult = await _locationService.requestService();
        if (serviceRequestResult) {
          initLocationService();
          return;
        }
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      if (e.code == 'PERMISSION_DENIED') {
        _serviceError = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        _serviceError = e.message;
      }
      location = null;
      debugPrint("_serviceError: " + _serviceError.toString());
    } catch (e) {
      debugPrint("An unexpected error occurred: $e");
    }
  }

  void _moveMapToCard(GeoNote gn) {
    if (_mapController != null) {
      // do this is we are showing both map and list...
      if (MediaQuery.of(context).size.width >
          MediaQuery.of(context).size.height) {
        // stop updating pos so user can see
        _liveUpdate = false;
        _animatedMapMove(gn.getLatLon(), _mapController!.zoom);
      }
    }
  }

  Widget _MapView(
    LatLng currentLatLng,
    List<GeoNote> myGeoNotes,
  ) {
    var markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: currentLatLng,
        // anchorPos: AnchorAlign.top as AnchorPos,
        builder: (ctx) => const Icon(
          Icons.circle_rounded,
          color: Colors.blueAccent,
          size: 25.0,
        ),
      ),
    ];
    markers.addAll(_buildMarkersList(myGeoNotes));

    List<LatLng> _myRoutePoint = myGeoNotes
        .map((gNote) => LatLng(gNote.lat.toDouble(), gNote.lon.toDouble()))
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(currentLatLng.latitude, currentLatLng.longitude),
        zoom: 16.0,
        interactiveFlags: interActiveFlags,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'dev.leaflet.flutter_map.example',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _myRoutePoint,
//              points: _myRoutePoint,
              strokeWidth: 4.0,
              color: Colors.blue.withOpacity(1),
            ),
          ],
        ),
        MarkerLayer(markers: markers)
      ],
    );

    // your existing map code here
  }

  Widget _listView(
    currentLatLng,
    List<GeoNote> gn2,
  ) {
    // place newest gn on top and only gn that are markers
    //
    List<GeoNote> gnMarkers =
        gn2.where((n) => n.note_type != "routepoint").toList();

    List<GeoNote> gn = List.from(gnMarkers);
    return gn.isEmpty
        ? Paragraph('\n${Strings.welcomeMakeObs}')
        : Align(
            alignment: Alignment.topCenter,
            child: ListView.builder(
              reverse: false,
              itemCount: gn.length,
              itemBuilder: (BuildContext context, int index) {
                bool accent = (_selectedCardIndex == index);
                return Card(
                    margin: EdgeInsets.fromLTRB(10, 12, 10, 0),
                    child: Padding(
                        padding: EdgeInsets.all(0),
                        child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: accent ? Colors.blue : Colors.white,
                                  width: 3.0,
                                ),
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  _selectedCardIndex =
                                      index; // as now cards are reversed...
                                });
                                //  cards in map has not been reversed
                                int rev_i = index;
                                //gn.length - index - 1;
                                _moveMapToCard(gn[rev_i]);
                                debugPrint("rev_i $rev_i");
                                debugPrint("rev_i $rev_i gn.index " +
                                    gn[rev_i].note_index.toString() +
                                    "  gn.text " +
                                    gn[rev_i].text);
                              },
                              title: ParagraphCard(gn[index].timestamp == null
                                  ? "no date"
                                  : this
                                      .dateFormat
                                      .format(gn[index].timestamp!)),
                              subtitle: ParagraphCard("(" +
                                  (index + 1).toString() +
                                  ") " +
                                  gn[index].text),
                              leading: CardThumbnail(gn: gn[index]),
                              trailing: InkWell(
                                // Add InkWell
                                onTap: () {
                                  // Move _editNote call here
                                  _editNote(gn[index]);
                                },
                                child: Icon(Icons.edit),
                              ),
                            ))));
              },
            ));
  }

  Widget buildMainWidget(LatLng currentLatLng, List<GeoNote> myGeoNotes) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(
                Icons.rotate_90_degrees_ccw), // Add your additional icon here
            onPressed: () {
              showRotateToDualScreenDialog(context);
            },
          ),
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
            onPressed: () {
              setState(() {
                _showMap = !_showMap; // switch the state
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > constraints.maxHeight) {
            // Screen width > height, use landscape layout (side by side)
            return Row(
              children: [
                Expanded(child: _MapView(currentLatLng, myGeoNotes)),
                Expanded(child: _listView(currentLatLng, myGeoNotes)),
              ],
            );
          } else {
            // Screen height >= width, use portrait layout
            return Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                children: [
                  Flexible(
                    child: Stack(
                      children: [
                        Offstage(
                          offstage: !_showMap,
                          child: _MapView(currentLatLng, myGeoNotes),
                        ),
                        Offstage(
                          offstage: _showMap,
                          child: _listView(currentLatLng, myGeoNotes),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: Builder(builder: (BuildContext context) {
        return myBottomNavigationBar();
      }),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 80, // Adjust the position of the second button
            right: 16,
            child: FloatingActionButton(
              heroTag: "unique_tag_1", // Provide a unique tag for thFAB

              backgroundColor: Colors.black26,
              elevation: 0,
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _liveUpdate = !_liveUpdate;

                    if (_liveUpdate) {
                      interActiveFlags = // InteractiveFlag.rotate |
                          InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom;
                    } else {
                      interActiveFlags = InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchMove;
                    }
                  });
                }
              },
              child: _liveUpdate
                  ? const Icon(Icons.navigation_rounded)
                  : const Icon(Icons.location_disabled_outlined),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "unique_tag_2", // Provide a unique tag for thFAB

              onPressed: () =>
                  _AddNoteToObs(context), //_showAddMediaModal(context),
              backgroundColor: Colors.blue,
              label: const Text('Note'),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng currentLatLng;
    if (_currentLocation != null) {
      currentLatLng =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    } else {
      currentLatLng = LatLng(59.35916523, 18.05499978);
    }

    return WillPopScope(
      onWillPop: () async {
        if (changesPendingSave) {
          return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Unsaved Changes'),
                  content: Text(
                      'You have unsaved changes, are you sure you want to leave?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Yes'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('No'),
                    ),
                  ],
                ),
              ) ??
              false; // If dialog is dismissed, don't pop
        } else {
          return true; // No pending changes, safe to leave
        }
      },
      child: widget.editExistingPoints == 'true'
          ? FutureBuilder<List<GeoNote>>(
              future: geoNotesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('An error occurred!'));
                } else {
                  // set state?
                  myGeoNotes = snapshot.data!;
                  return buildMainWidget(currentLatLng, myGeoNotes);
                }
              },
            )
          : buildMainWidget(currentLatLng, myGeoNotes),
    );
  }

  Widget myBottomNavigationBar() {
    if (playMode) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: Colors.black,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.chevron_left),
            label: Strings.prev,
            backgroundColor: Colors.black,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: Strings.edit,
            backgroundColor: Colors.black,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.not_started_outlined),
            label: Strings.next,
            backgroundColor: Colors.black,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chevron_right),
            label: Strings.start,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: Strings.myMaps,
          ),
        ],
        currentIndex: _selectedMenuIndex,
        selectedItemColor: Colors.white70,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      );
    } else {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: Colors.black,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: !_paused
                ? const Icon(Icons.local_cafe_rounded)
                : const Icon(Icons.fiber_manual_record_rounded,
                    color: Colors.redAccent),
            label: !_paused ? 'pause' : 'resume',
          ),
          /*const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'preview',
            backgroundColor: Colors.black,
          ),*/

          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outlined),
            label: Strings.add,
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined),
            label: Strings.save.toLowerCase(),
          ),
          /*const BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'my Maps',
          ),*/
        ],
        currentIndex: _selectedMenuIndex,
        selectedItemColor: Colors.white70,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      );
    }
  }

  List<Marker> _buildMarkersList(List<GeoNote> geoNotesList) {
    List<GeoNote> filtered =
        geoNotesList.where((gn) => gn.note_type != "routepoint").toList();

    var myThumnails = filtered.asMap().entries.map((entry) {
      GeoNote gn = entry.value;
      double h = (MediaQuery.of(context).size.height / 10);
      double thumbnailHeight = h.floorToDouble();

      return Marker(
        width: 40, //thumbnailHeight,
        height: 40, //thumbnailHeight,
        point: gn.getLatLon(),
        anchorPos: AnchorPos.align(AnchorAlign.top),
        builder: (ctx) => GestureDetector(
          onTap: () {
            //TODO myMarker s onTap shadows this for images with cardthumbnail
            _editNote(gn);
          },
          child: note2Tumbnail(gn), // GoogleMapsMarker(index: index),
        ),
      );
    }).toList();

    var myMarkersAndDots = filtered.asMap().entries.map((entry) {
      GeoNote gn = entry.value;
      bool accent = (_selectedCardIndex == gn.note_index);
      return Marker(
        width: 42.0,
        height: 42.0,
        point: gn.getLatLon(),
//        anchorPos: AnchorPos.align(AnchorAlign.top),
        builder: (ctx) => accent
            ? Icon(
                Icons.radio_button_checked,
                color: Colors.blue,
                size: 35.0,
              )
            : Icon(
                Icons.circle_rounded,
                color: Colors.blue,
                size: 15.0,
              ),
      );
    }).toList();

    myMarkersAndDots.addAll(myThumnails);
    return myMarkersAndDots;
  }

  void _editNote(GeoNote gn) {
    switch (gn.note_type) {
      case 'text':
        _editTextNote(context, gn);
        break;
      case 'photo':
        _editPhotoNote(context, gn);
        break;
      case 'audio':
        _editAudioNote(context, gn);
        break;
    }
  }

  List<AnimationController> _animationControllers = [];

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final latTween = Tween<double>(
        begin: _mapController!.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController!.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController!.zoom, end: destZoom);
    // Initialize the _animationController with the correct duration and vsync

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _animationControllers.add(controller);

    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController!.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        // And this line
        _animationControllers.remove(controller);
      }
    });

    controller.forward();
  }
}
