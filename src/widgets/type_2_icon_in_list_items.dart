import 'package:flutter/material.dart';

Icon type2Icon(String type) {
  switch (type) {
    case 'map':
      return const Icon(
        Icons.map_outlined,
        color: Colors.black,
      );
    case 'interview':
      return const Icon(
        //Icons.play_circle_outline,
        Icons.record_voice_over_outlined,
        color: Colors.black,
      );

    case 'participantobservation':
      return const Icon(
        //Icons.format_list_bulleted_add,
        Icons.description_outlined,
        color: Colors.black,
      );

    case 'consent':
      return const Icon(
        Icons.lock_person_outlined,
        color: Colors.black,
      );
    case 'schedule':
      return const Icon(
        Icons.pending_actions_outlined,
        color: Colors.black,
      );
    case 'walkingmap':
      return const Icon(
        Icons.directions_walk_outlined,
        color: Colors.brown,
      );
    default:
      debugPrint('W/ orioli: Unknown type: $type');
      return const Icon(
        Icons.error_outline,
        color: Colors.black,
      );
  }
}
