// Generates a square launcher icon with safe padding for circular masks.
// Run: dart run tool/generate_app_icon.dart
// Then: dart run flutter_launcher_icons

import 'dart:io';

import 'package:image/image.dart' as img;

const _size = 1024;
const _bg = img.ColorRgb8(245, 247, 242); // #F5F7F2
const _logoScale = 0.58; // keeps logo inside Android/iOS circular safe zone

void main() {
  final logoFile = File('assets/logo.png');
  if (!logoFile.existsSync()) {
    stderr.writeln('Missing assets/logo.png');
    exit(1);
  }

  final logo = img.decodeImage(logoFile.readAsBytesSync());
  if (logo == null) {
    stderr.writeln('Could not decode assets/logo.png');
    exit(1);
  }

  final maxLogoSide = (_size * _logoScale).round();
  final scale = maxLogoSide / (logo.width > logo.height ? logo.width : logo.height);
  final resized = img.copyResize(
    logo,
    width: (logo.width * scale).round(),
    height: (logo.height * scale).round(),
    interpolation: img.Interpolation.linear,
  );

  final canvas = img.Image(width: _size, height: _size);
  img.fill(canvas, color: _bg);
  img.compositeImage(
    canvas,
    resized,
    dstX: (_size - resized.width) ~/ 2,
    dstY: (_size - resized.height) ~/ 2,
  );

  final out = File('assets/app_icon.png');
  out.writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Wrote ${out.path} (${_size}x$_size, logo at ${(_logoScale * 100).round()}% scale)');
}
