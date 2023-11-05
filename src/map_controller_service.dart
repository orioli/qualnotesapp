import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

class MapLocationService with ChangeNotifier {
  MapController? mapController;

  MapLocationService() {
    mapController = MapController();
  }
}
