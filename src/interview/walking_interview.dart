// Copyright 2023 Jose Berengueres. Qualnotes AB
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:qualnotes/src/interview/widgets/interview_body.dart';
import 'package:qualnotes/src/interview/widgets/interview_question_card_UI.dart';
import 'package:qualnotes/src/interview/widgets/recording_widget.dart';
import 'package:record/record.dart';

import '../map_controller_service.dart';
import '../mapping/geonote.dart';
import '../widgets/add_title_dialouge.dart';
import '../app_state.dart';
import '../widgets/strings.dart';
import '../widgets/widgets.dart';

import './recording_sate.dart';

class WalkingInterview extends StatefulWidget {
  final String? prj_id;
  final String? sch_id;
  WalkingInterview({super.key, this.prj_id, this.sch_id});

  @override
  _WalkingInterviewState createState() => _WalkingInterviewState();
}

class _WalkingInterviewState extends State<WalkingInterview>
    with TickerProviderStateMixin {
  LocationData? _currentLocation;
  MapController? _mapController;
  final Location _locationService = Location();
  late CameraController controller;
  late String videoPath;
  late CustomTimerController _controller;
  late List<CameraDescription> cameras;
  late int selectedCameraIdx;
  bool _permission = false;
  StreamSubscription<LocationData>? _locationSubscription;
  String? _serviceError = '';

  List<GeoNote> myGeoNotes = []; // anotated - only these are saved
  List<LatLng> _myRoutePoint = []; // sampled every5 s

  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;

  bool _isLoading = false;
  bool _showSwitchCamFOB = true;
  bool _hasTapedOnRecordAtLeastOnce = false;

  String? _prj_id;
  String? _sch_id;
  String? question_list;

  int _selectedIndex = 0;
  int _selectedVideoState = 0;
  int _selectedCameraIndex =
      0; // 0 will be the default camera (usually the back one)
  // this moved to provider  int startOfRecording = -1; // -1 means has not started.
  Map<String, dynamic> _jsonQuestionsWithTimestamps = {};

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        _navigateToSelectSchedule();
        break;
      case 1:
        _handleVideoRecording();
        break;
      case 2:
        _handleSave();
        break;
    }
  }

  void _navigateToSelectSchedule() {
    context.pushNamed('select-schedule', queryParams: {
      'prj_id': widget.prj_id,
      'type': 'walkingmap',
    });
  }

  void _handleVideoRecording() {
    if (_selectedVideoState == 0 && _recordState == RecordState.stop) {
      // first time rec button is preset
      Provider.of<RecordingState>(context, listen: false)
          .setStartOfRecording(DateTime.now().toUtc().millisecondsSinceEpoch);

      setState(() {
        _hasTapedOnRecordAtLeastOnce = true;
        _showSwitchCamFOB = false;
        // we use prvder now ... startOfRecording = DateTime.now().toUtc().millisecondsSinceEpoch;
      });
      //_recVideoOrAudioPopUp();
      _onRecordButtonPressed();
    } else if (_selectedVideoState == 1) {
      _onPauseButtonPressed();
    } else if (_selectedVideoState == 2) {
      _resumeVideoRecording();
    } else if (_recordState == RecordState.record) {
      _pause();
    } else if (_recordState == RecordState.pause) {
      _resume();
    }
  }

  Future<void> _handleSave() async {
    debugPrint("not savinf becuase nothing to save");
    if (_hasTapedOnRecordAtLeastOnce == false) return;

    dataModel = [];

    if (widget.prj_id?.isNotEmpty == true &&
        widget.sch_id?.isNotEmpty == true) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.prj_id)
            .collection('collected-data')
            .doc(widget.sch_id)
            .get();

        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data.containsKey('questions')) {
            dataModel = data['questions'];
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    RecordingState recordingState =
        Provider.of<RecordingState>(context, listen: false);
    Map<int, int> timestamps = recordingState.timestamps;
    List<Map<String, dynamic>> dataModelWithTimestamps = List.from(dataModel);

    if (dataModelWithTimestamps.isNotEmpty) {
      for (var i = 0; i < dataModelWithTimestamps.length; i++) {
        int? cardtimestamp = timestamps[i];
        if (cardtimestamp != null) {
          dataModelWithTimestamps[i]['timestamp'] =
              timestamp2HHMMSS(cardtimestamp, recordingState.startOfRecording);
        }
      }
      _jsonQuestionsWithTimestamps = {"questions": dataModelWithTimestamps};
    }

    if (controller.value.isInitialized &&
        (controller.value.isRecordingVideo ||
            controller.value.isRecordingPaused)) {
      _onSaveButtonPressed(_prj_id, _sch_id);
    }

    if (_recordState != RecordState.stop) {
      _stop(_prj_id);
    }
  }

  Future<void> _stop(prj_id) async {
    _controller.reset();

    final path = await _audioRecorder.stop();

    if (path != null) {
      try {
        await _saveInterviewWithTitleDialog(prj_id, path);
      } on CameraException catch (e) {
        _showCameraException(e);
        return null;
      }
    }
  }

  List<AnimationController> _animationControllers = [];

  Future<void> _saveInterviewWithTitleDialog(String prj_id, String path) async {
    await showDialog(
      context: context,
      builder: (context) => Consumer<ApplicationState>(
        builder: (context, appState, _) => myTitleDialog(
          onPress: (val) async {
            //FocusManager.instance.primaryFocus?.unfocus();
            await appState.addInterview(
                prj_id, val, File(path), _jsonQuestionsWithTimestamps);
            context.pushNamed('project', queryParams: {
              'prj_id': widget.prj_id,
              'prj_title': appState.projectTitle,
              'active_tab': 'second',
            });
          },
          prj_id: prj_id,
          title: Strings.titleYourNewInterview,
          hint: Strings.myInterviewTitle,
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    Provider.of<RecordingState>(context, listen: false).setStartOfRecording(-1);

    controller.dispose();
    _controller.dispose();
    _recordSub?.cancel();
    _audioRecorder.dispose();

    _locationSubscription?.cancel();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _locationSubscription?.cancel();

    super.dispose();
  }

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

                if (true) {
                  _myRoutePoint.add(LatLng(_currentLocation!.latitude!,
                      _currentLocation!.longitude!));
                  if (true) {
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

  @override
  void initState() {
    super.initState();
    initializeVideo();
    initializeAudio();
    initLocationService();
    _prj_id = widget.prj_id!;
    _sch_id = widget.sch_id ?? "";
    //initLocationService();

    // _mapController = MapController();  // *** moved this to build look down
    if (_mapController == null) {
      _mapController = Provider.of<MapLocationService>(context, listen: false)
          .mapController!;
    }
  }

  var interActiveFlags =
      InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mapController == null) {
      _mapController = Provider.of<MapLocationService>(context, listen: false)
          .mapController!;
    }
  }

  initializeVideo() async {
    setState(() {
      _isLoading = true;
    });

    _controller = CustomTimerController(
        vsync: this,
        begin: Duration(seconds: 0),
        end: Duration(hours: 12), // TODO: check this.
        initialState: CustomTimerState.reset,
        interval: CustomTimerInterval.milliseconds);

    await availableCameras().then((availableCameras) {
      cameras = availableCameras;
      //controller = CameraController(cameras[0], ResolutionPreset.max);
      controller =
          CameraController(cameras[_selectedCameraIndex], ResolutionPreset.max);

      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
      }).catchError((Object e) {
        setState(() {
          _isLoading = false;
        });

        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              // Handle access errors here.

              break;
            default:
              // Handle other errors here.
              break;
          }
        }
      });
    });
  }

  initializeAudio() async {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });
  }

  Widget _listView() {
    return Center(
      child: _sch_id?.isEmpty ?? false
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Paragraph(Strings.selectAndLoadSchedulePrompt),
                ElevatedButton(
                    onPressed: () {
                      _navigateToSelectSchedule();
                    },
                    child: const Text('set schedule'))
              ],
            )
          : InterviewBody(
              prj_id: _prj_id, sch_id: _sch_id, controller: _controller),
    );
  }

  Widget _CamView() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        print('Max Height: ${constraints.maxHeight}');
        print('Max Width: ${constraints.maxWidth}');

        return RecordingWidget(
          maxh: constraints.maxHeight,
          controller: _controller,
          cameraView: cameraPreviewWidget(constraints.maxHeight),
          isCamera: true,
          isShow: !_isLoading && controller.value.isInitialized ? true : false,
        );
        // Return your widget here.
      },
    );
  }

  Widget _MapView(
    LatLng currentLatLng,
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
        MarkerLayer(markers: markers)
      ],
    );

    // your existing map code here
  }

  Widget _MapView2() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Image.asset('assets/images/samplemap.png', fit: BoxFit.cover);
      },
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
    if (_isLoading)
      Center(
        child: CircularProgressIndicator(),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.letsWalkMapInterview),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
          onPressed: () {
            Provider.of<RecordingState>(context, listen: false)
                .setStartOfRecording(-1);

            context.pop();
          },
        ),
      ),
      body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > constraints.maxHeight) {
          // Screen width > height, use landscape layout (side by side)
          return Row(
            children: [
              Expanded(child: _listView()),
              Expanded(child: _CamView()),
              Expanded(
                child: _MapView(currentLatLng),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _MapView(currentLatLng),
                    ),
                    Expanded(
                      child: _CamView(),
                    )
                  ],
                ),
              ),
              Expanded(child: _listView()),
            ],
          );
        }
      }),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(color: Colors.white12),
        backgroundColor: Colors.black,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.task_outlined,
              color:
                  _selectedVideoState != 0 || _recordState != RecordState.stop
                      ? Colors.white12
                      : Colors.white60,
            ),
            label: Strings.setSchedule,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedVideoState == 0 && _recordState == RecordState.stop
                  ? Icons.circle
                  : _selectedVideoState == 1 ||
                          _recordState == RecordState.record
                      ? Icons.pause_circle
                      : Icons.play_arrow,
              color: !_isLoading &&
                      (controller.value.isInitialized &&
                              controller.value.isRecordingVideo ||
                          _recordState != RecordState.stop)
                  ? Colors.red
                  : Colors.white60,
            ),
            label: Strings.rec,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined),
            label: Strings.save,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            _selectedVideoState != 0 || _recordState != RecordState.stop
                ? Colors.white12
                : Colors.white70,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }

  _recVideoOrAudioPopUp() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          10, MediaQuery.of(context).size.height * 0.9, 30, 0),
      constraints: BoxConstraints(
        minWidth: 150,
        maxWidth: 199,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        PopupMenuItem<int>(
          value: 0,
          onTap: () => _onRecordButtonPressed(),
          child: Center(
            child: Text(
              Strings.video,
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
        PopupMenuItem(child: Divider(), padding: EdgeInsets.zero, height: 1),
        PopupMenuItem<int>(
          value: 1,
          //onTap: () => _start(),
          child: Center(
            child: Text(
              Strings.audio,
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  /// Audio Recording
  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {}
        await _audioRecorder.start();
        _controller.start();
      }
    } catch (e) {
      if (kDebugMode) {}
    }
  }

  Future<void> _pause() async {
    _controller.pause();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _controller.start();
    await _audioRecorder.resume();
  }

  Widget cameraPreviewWidget(double maxh) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (!controller.value.isInitialized) {
      return const Text(
        'No camera available',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    double timerHeaderWidth = 30;
    return Container(
      height: (maxh - timerHeaderWidth),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: <Widget>[
          CameraPreview(controller),
          _showSwitchCamFOB == true
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    onPressed: _isLoading ? null : _switchCamera,
                    child: Icon(Icons.switch_camera),
                    backgroundColor:
                        Colors.grey.withOpacity(0.5), // semi-transparent grey
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  void _switchCamera() async {
    // Get the number of available cameras.
    int cameraCount = cameras.length;

    // If there's only one camera, no need to switch.
    if (cameraCount <= 1) return;

    // Turn off the camera.
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }

    // Always dispose of resources, such as the CameraController, when you're done using them.
    await controller.dispose();

    // Select the next camera.
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameraCount;

    // Start the new camera.
    controller = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
    );

    // Ensure the camera is properly initialized before updating the state.
    await controller.initialize();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

// AUDIO ----------------------------------
  void _onRecordButtonPressed() {
    _startVideoRecording().then((val) {
      _controller.start();
      setState(() {
        _selectedVideoState = 1;
      });
    });
  }

  void _onSaveButtonPressed(prj_id, sch_id) {
    _stopVideoRecording(prj_id: prj_id, schId: sch_id).then((_) {
      _controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Strings.videoRecordedTo} $videoPath')));
    });
  }

  void _onPauseButtonPressed() {
    _pauseVideoRecording().then((_) {
      _controller.pause();

      if (mounted)
        setState(() {
          _selectedVideoState = 2;
        });
    });
  }

// VIDEO ---------------------------------
  Future _startVideoRecording() async {
    if (!controller.value.isInitialized) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please wait')));

      return '';
    }

    // Do nothing if a recording is on progress
    if (controller.value.isRecordingVideo) {
      return '';
    }

    try {
      await controller.startVideoRecording();
    } on CameraException {
      // _showCameraException(e);
      return '';
    }
  }

  Future<void> _stopVideoRecording(
      {required String prj_id, required String schId}) async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    _selectedVideoState = 0;
    setState(() {});
    try {
      await controller.stopVideoRecording().then((value) {
        setState(() {
          videoPath = value.path;
        });
      });

      await _saveInterviewWithTitleDialog(prj_id, videoPath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<void> _pauseVideoRecording() async {
    if (controller.value.isRecordingPaused) {
      return null;
    }

    try {
      await controller.pauseVideoRecording();
      await controller.pausePreview();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<void> _resumeVideoRecording() async {
    if (!controller.value.isRecordingPaused) {
      return null;
    }

    try {
      await controller.resumeVideoRecording();
      await controller.resumePreview();
      _controller.start();

      setState(() {
        _selectedVideoState = 1;
      });
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.code}\n${e.description}')));
  }
}
