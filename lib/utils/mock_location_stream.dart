import 'package:latlong2/latlong.dart';

/// Helpers for densifying coordinate paths (e.g. seller demo movement).
class MockLocationStream {
  MockLocationStream._();

  static const Duration stepInterval = Duration(milliseconds: 450);
  static const double stepMetres = 12;

  static List<LatLng> densifyPath(
    List<LatLng> waypoints, {
    double stepMetres = MockLocationStream.stepMetres,
  }) {
    if (waypoints.length < 2) return List<LatLng>.from(waypoints);

    const distance = Distance();
    final out = <LatLng>[waypoints.first];

    for (var i = 0; i < waypoints.length - 1; i++) {
      final from = waypoints[i];
      final to = waypoints[i + 1];
      final totalM = distance.as(LengthUnit.Meter, from, to);
      if (totalM <= stepMetres) {
        if (out.last != to) out.add(to);
        continue;
      }

      final steps = (totalM / stepMetres).ceil();
      for (var s = 1; s <= steps; s++) {
        final t = s / steps;
        out.add(
          LatLng(
            from.latitude + (to.latitude - from.latitude) * t,
            from.longitude + (to.longitude - from.longitude) * t,
          ),
        );
      }
    }

    return out;
  }
}
