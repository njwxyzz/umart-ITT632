import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Interpolates map marker coordinates so pins move smoothly between GPS / Firestore updates.
class MapMarkerSmoother {
  MapMarkerSmoother(this.tickerProvider);

  final TickerProvider tickerProvider;

  /// Visual travel speed between GPS / Firestore updates (~36 km/h cap).
  static const double _metresPerSecond = 10;
  static const Duration _minDuration = Duration(milliseconds: 380);
  static const Duration _maxDuration = Duration(milliseconds: 3200);

  AnimationController? _anim;
  LatLng? _start;
  LatLng? _end;
  LatLng? _current;

  LatLng? get current => _current;

  /// Drives [AnimatedBuilder] for marker layers without rebuilding the whole map.
  Listenable get repaintListenable =>
      _anim ?? const _AlwaysIdleListenable();

  void dispose() {
    _stopAnim();
    _current = null;
    _start = null;
    _end = null;
  }

  void _stopAnim() {
    _anim?.dispose();
    _anim = null;
  }

  void setTarget(LatLng? target, VoidCallback onTick) {
    if (target == null) {
      _stopAnim();
      _current = null;
      _start = null;
      _end = null;
      onTick();
      return;
    }

    if (_current == null) {
      _current = target;
      onTick();
      return;
    }

    const dCalc = Distance();
    final jumpM = dCalc.as(LengthUnit.Meter, _current!, target);
    if (jumpM < 0.75) {
      _current = target;
      onTick();
      return;
    }

    _stopAnim();
    _start = _current!;
    _end = target;
    final durationMs = (jumpM / _metresPerSecond * 1000).round();
    final duration = Duration(
      milliseconds: durationMs.clamp(
        _minDuration.inMilliseconds,
        _maxDuration.inMilliseconds,
      ),
    );
    _anim = AnimationController(vsync: tickerProvider, duration: duration)
      ..addListener(() {
        // Linear easing keeps motion continuous when updates arrive in a chain.
        final t = Curves.linear.transform(_anim!.value);
        _current = LatLng(
          _start!.latitude + (_end!.latitude - _start!.latitude) * t,
          _start!.longitude + (_end!.longitude - _start!.longitude) * t,
        );
        onTick();
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _current = _end;
          onTick();
        }
      })
      ..forward();
  }
}

class _AlwaysIdleListenable implements Listenable {
  const _AlwaysIdleListenable();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}
