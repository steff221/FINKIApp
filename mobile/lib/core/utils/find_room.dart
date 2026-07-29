import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Takes the student from a class to the campus map, carrying the room with
/// them.
///
/// "Барака 3.2" on a card and "Барака 3.2" on the map are the same question
/// asked twice; this is the one tap between them. The map is somebody else's
/// web app and we have no room-to-coordinate table of our own, so it cannot
/// centre itself on the room — what it can do is keep the name in front of the
/// student while they look, instead of making them remember it across a tab
/// switch.
void findRoomOnMap(BuildContext context, String room) {
  final trimmed = room.trim();
  if (trimmed.isEmpty) return context.go('/map');
  context.go('/map?room=${Uri.encodeComponent(trimmed)}');
}
