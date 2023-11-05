// Copyright 2022-2023 Jose Berengeueres, Qualnotes AB.
// Adapted from livelocation tutorial

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:qualnotes/src/mapping/widgets.dart';
import '../pobs/pobs_widgets.dart';
import '../widgets/widgets.dart';
import 'audio_player.dart';
import 'geonote.dart';
import 'dart:async';
import './geo_note_service.dart';

class PlayMap extends StatefulWidget {
  final String prj_id;
  final String title;
  final String map_id;

  PlayMap({
    required this.title,
    required this.prj_id,
    required this.map_id,
    Key? key,
  }) : super(key: key);
  @override
  _PlayMapState createState() => _PlayMapState();
}

class _PlayMapState extends State<PlayMap> with TickerProviderStateMixin {
  Future<List<GeoNote>>? geoNotesFuture;
  late List<GeoNote> myGeoNotes;
  late List<GeoNote> myPlayableNotes;
  late final MapController _mapController;
  //MapController mapController = MapController();

  int currentNoteIndex = 0; // to keep track of current note

  final GeoNoteService geoNoteService = GeoNoteService();
  String? _serviceError = '';
  var interActiveFlags = InteractiveFlag.pinchZoom |
      InteractiveFlag.doubleTapZoom |
      InteractiveFlag.drag;

  @override
  void dispose() {
    // _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    geoNotesFuture = geoNoteService.fetchGeoNotes(widget.prj_id, widget.map_id);

    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GeoNote>>(
      future: geoNotesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While data is loading:
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // If something went wrong:
          return Center(child: Text('An error occurred!'));
        } else {
          // When data is loaded:
          myGeoNotes = snapshot.data!;
          myPlayableNotes =
              myGeoNotes.where((gn) => gn.note_type != "routepoint").toList();

          // _mapController = MapController();
          LatLng currentLatLng = LatLng(
              myGeoNotes.first.lat as double, myGeoNotes.first.lon as double);

          var markers = <Marker>[
            Marker(
              width: 80.0,
              height: 80.0,
              point: currentLatLng,
              // anchorPos: AnchorAlign.top as AnchorPos,
              builder: (ctx) => const Icon(
                Icons.circle_rounded,
                //Icons.boy
                //Icons.location_pin,
                color: Colors.blueAccent,
                size: 25.0,
              ),
            ),
          ];
          markers.addAll(_buildMarkersList(myGeoNotes));

          List<LatLng> routePoints = myGeoNotes
              .map(
                  (gNote) => LatLng(gNote.lat.toDouble(), gNote.lon.toDouble()))
              .toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onMarkerTap(myPlayableNotes.first);
          });

          return Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                children: [
                  Flexible(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: LatLng(
                            currentLatLng.latitude, currentLatLng.longitude),
                        zoom: 16.0,
                        interactiveFlags: interActiveFlags,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                          userAgentPackageName:
                              'dev.leaflet.flutter_map.example',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 4.0,
                              color: Colors.blue.withOpacity(0.7),
                            ),
                          ],
                        ),
                        MarkerLayer(markers: markers)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  void _goToNextNote() {
    if (currentNoteIndex < myPlayableNotes.length - 1) {
      currentNoteIndex++;
      final LatLng goto = LatLng(
          myPlayableNotes[currentNoteIndex].lat.toDouble(),
          myPlayableNotes[currentNoteIndex].lon.toDouble());
      _animatedMapMove(goto, _mapController.zoom);
      //_mapController.move(        goto, _mapController.zoom);
      Navigator.pop(context); // close the existing modal sheet
      _onMarkerTap(
          myPlayableNotes[currentNoteIndex]); // show details of the new note
    }
  }

  void _goToPrevNote() {
    if (currentNoteIndex > 0) {
      currentNoteIndex--;
      // LatLng(gNote.lat.toDouble(), gNote.lon.toDouble()))
      final LatLng goto = LatLng(
          myPlayableNotes[currentNoteIndex].lat.toDouble(),
          myPlayableNotes[currentNoteIndex].lon.toDouble());
      _animatedMapMove(goto, _mapController.zoom);
      Navigator.pop(context); // close the existing modal sheet
      _onMarkerTap(
          myPlayableNotes[currentNoteIndex]); // show details of the new note
    }
  }

  Widget goFwd() {
    return InkWell(
      onTap: _goToNextNote,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward,
          size: 42,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget goBack() {
    return InkWell(
      onTap: _goToPrevNote,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back,
          size: 42,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _displayField(String presetText) {
    return TextFormField(
      initialValue: presetText,
      autofocus: true,
      minLines: 3,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      readOnly: true,
      decoration: const InputDecoration(
        fillColor: Colors.white,
        filled: true,
        hintText: "note used",
        contentPadding: EdgeInsets.all(10.0),
        border: OutlineInputBorder(
          borderSide: BorderSide(),
        ),
      ),
    );
  }

  Widget content(GeoNote gn) {
    final bool hasImage = gn.imgPath != null && gn.imgPath!.isNotEmpty;
    final bool hasAudio = gn.audioPath != null && gn.audioPath!.isNotEmpty;
    final bool textAlone = !hasImage && !hasAudio;

    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasImage)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.60,
              ),
              child: GestureDetector(
                onTap: () {
                  showImageFullScreen(context, gn);
                },
                child: kIsWeb
                    ? buildHtmlImageView(gn.imgPath!)
                    : FadeInImage.assetNetwork(
                        placeholder: 'assets/images/loading.gif',
                        image: gn.imgPath!,
                        height: MediaQuery.of(context).size.height * 0.30 - 20,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          if (hasAudio)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 200, maxHeight: 220),
              child: OrioliAudioPlayer(
                source: gn.audioPath!,
                onDelete: () {
                  Navigator.pop(context);
                },
              ),
            ),
          Container(
              padding: const EdgeInsets.all(16.0),
              width: MediaQuery.of(context).size.width * 0.7,
              child: new Column(
                children: <Widget>[
                  (textAlone)
                      ? Text(cropTextToNCharacters(gn.text, 300))
                      : Text(cropTextToNCharacters(gn.text, 60))
                ],
              )),
        ],
      ),
    );
  }

  void _onMarkerTap(GeoNote gn) {
    debugPrint(gn.audioPath.toString());
    showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent, // set the barrier color to transparent

      isScrollControlled: true,
      backgroundColor: Colors.white, // Add this line

      builder: (BuildContext context) {
        return SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            goBack(),
                            content(gn),
                            goFwd(),
                          ],
                        )),
                  ],
                ),
              ),
            ));
      },
    );
  }

  List<Marker> _buildMarkersList(List<GeoNote> geoNotesList) {
    List<GeoNote> filtered =
        geoNotesList.where((gn) => gn.note_type != "routepoint").toList();

    var myMarkers = filtered.asMap().entries.map((entry) {
      GeoNote gn = entry.value;
      double h = (MediaQuery.of(context).size.height / 10);
      //double thumbnailHeight = h.floorToDouble();

      return Marker(
        //width: thumbnailHeight,
        //height: thumbnailHeight,
        width: 40, //thumbnailHeight,
        height: 40, //thumbnailHeight,

        point: gn.getLatLon(),
        anchorPos: AnchorPos.align(AnchorAlign.top),
        builder: (ctx) => GestureDetector(
          onTap: () {
            _onMarkerTap(gn);
          },
          child: note2Tumbnail(gn), // GoogleMapsMarker(index: index),
        ),
      );
    }).toList();
    return myMarkers;
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final latTween = Tween<double>(
        begin: _mapController.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.zoom, end: destZoom);
    // Initialize the _animationController with the correct duration and vsync

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
}
