import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Interpolates map marker coordinates so pins move smoothly between GPS / Firestore updates.
class MapMarkerSmoother {
  MapMarkerSmoother(this.tickerProvider);

  final TickerProvider tickerProvider;
  static const Duration _duration = Duration(milliseconds: 420);

  AnimationController? _anim;
  LatLng? _start;
  LatLng? _end;
  LatLng? _current;

  LatLng? get current => _current;

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
    _anim = AnimationController(vsync: tickerProvider, duration: _duration)
      ..addListener(() {
        final t = Curves.easeOutCubic.transform(_anim!.value);
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
