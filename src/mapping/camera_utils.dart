import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
//import 'package:qualnotes/src/mapping/editor_screen.dart';
import 'package:qualnotes/src/widgets/strings.dart';
import 'geonote.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  //final firstCamera = cameras.first;
  final geoNote1 = GeoNote(99, "photo", 1, 1, Strings.defaultNoteText);

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
          // Pass the appropriate camera to the TakePictureScreen widget.
          //camera: firstCamera,
          ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  //final CameraDescription camera;
  // final GeoNote geoNote;
  // TakePictureScreen({Key? key, required this.camera, required this.geoNote,}) : super(key: key);
  const TakePictureScreen({
    super.key,
    //required this.camera,
    //required this.geoNote,
  });

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController? controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;
  CameraDescription? firstCamera;
  bool _isInitialized = false; // new flag
  bool _isButtonEnabled = true;
  bool _isSwitchingCameras = false; // flag to check if a switch is in progress
  int selectedCameraIndex = 0;

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller?.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    controller?.addListener(() {
      if (mounted) setState(() {});
      if (controller!.value.hasError) {
        debugPrint('Camera Error: ${controller!.value.errorDescription}');
      }
    });

    try {
      await controller?.initialize();
    } on CameraException catch (e) {
      debugPrint('Camera Error: ${e}');
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      cameras = await availableCameras();
      firstCamera = cameras?.first;
      onNewCameraSelected(cameras![selectedCameraIndex]);

      controller = CameraController(
        firstCamera!,
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = controller?.initialize();
      setState(() {
        _isInitialized =
            true; // set the flag to true after initialization is complete
      });
    });
  }

  @override
  void dispose() {
    if (!_isSwitchingCameras) {
      // only dispose if not switching cameras
      controller?.dispose();
    }
    super.dispose();
  }

  void switchCamera() async {
    if (cameras == null || cameras!.length < 2) {
      print('No alternate camera found.');
      return;
    }

    CameraDescription alternateCamera =
        (firstCamera == cameras![0]) ? cameras![1] : cameras![0];
    _isSwitchingCameras = true; // set the flag

    CameraController? newController = CameraController(
      alternateCamera,
      ResolutionPreset.medium,
    );

    if (newController != null) {
      // Wait until the controller is initialized before updating the state.
      _initializeControllerFuture = newController.initialize();
      await _initializeControllerFuture;
      _isSwitchingCameras = false; // reset the flag

      setState(() {
        firstCamera = alternateCamera;
        controller?.dispose();
        controller = newController;
      });
    } else {
      print('Could not switch cameras.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text(Strings.takeAPicture)),
        // You must wait until the controller is initialized before displaying the
        // camera preview. Use a FutureBuilder to display a loading spinner until the
        // controller has finished initializing.
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the Future is complete, display the preview.
              return CameraPreview(controller!);
            } else {
              // Otherwise, display a loading indicator.
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              heroTag: 'switchCameraButton',
              onPressed: () {
                selectedCameraIndex =
                    (selectedCameraIndex + 1) % cameras!.length;
                onNewCameraSelected(cameras![selectedCameraIndex]);
              },
              child: const Icon(Icons.switch_camera),
            ),
            FloatingActionButton(
              heroTag: 'captureButton',
// callback.
              onPressed: _isButtonEnabled
                  ? () async {
                      try {
                        setState(() {
                          _isButtonEnabled = false; // disable button
                        });
                        await _initializeControllerFuture;
                        final image = await controller?.takePicture();

                        debugPrint(image.toString());
                        debugPrint("mounteed is " + mounted.toString());

                        if (!mounted) return;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (image != null) {
                            // check that image and image.path are not null
                            Navigator.pop(context, image.path);
                          } else {
                            print('Image path is null');
                          }
                        });
                      } catch (e) {
                        print(e);
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isButtonEnabled = true; // enable button
                          });
                        }
                      }
                    }
                  : null,
              child: const Icon(Icons.camera_alt),
            ),
          ],
        ));
  }
}

// WILL BE USED TO VIEW THE PHOTONOTE.
// A widget that displays the picture taken by the user.
class EditPhotoGeoNote extends StatelessWidget {
  ///final String imagePath;
  final GeoNote geoNote; // the geonote to edit
  EditPhotoGeoNote({
    Key? key,
    required this.geoNote,
  }) : super(key: key);
  // old const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //appBar: AppBar(title: Text(imagePath,maxLines: 6, textScaleFactor: .4, )),
        appBar: AppBar(title: Text(Strings.editPhotoNote)),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        //body: Image.file(File(imagePath)),
        body: Column(
          children: <Widget>[
            Center(
              child: Container(
                child: Image.file(File(geoNote.imgPath!), height: 350),
              ),
            ),
            Center(
              child: Container(
                child: geoNote.text.isNotEmpty
                    ? Text(geoNote.text)
                    : const Text(Strings.addCaption),
              ),
            ),
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Close the screen and return "Yep!" as the result.
                      Navigator.pop(context);

                      // call Edit text with id of this note.
                    },
                    child: geoNote.text.isNotEmpty
                        ? Text(Strings.editCaption)
                        : const Text(Strings.addCaption),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Close the screen and return "Yep!" as the result.
                      geoNote.deleteMe = true;
                      Navigator.pop(context, geoNote);
                    },
                    child: const Text(Strings.delete),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Close the screen and return "Yep!" as the result.
                      Navigator.pop(context);
                    },
                    child: const Text(Strings.back),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Close the screen and return "Nope." as the result.
                      // go to map Navigator.pop(context, '');
                    },
                    child: const Text(Strings.delete),
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}
