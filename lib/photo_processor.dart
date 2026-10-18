import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

// Decode with Flutter, inspect dimensions before allocating full image pixels,
// then rebuild a JPEG from raw pixels. EXIF/location metadata is not copied.
Future<Uint8List> prepareFramePhoto(Uint8List input) async {
  if (input.isEmpty || input.length > 12 * 1024 * 1024) {
    throw const FormatException('Choose a photo smaller than 12 MB.');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(input);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? decoded;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width * descriptor.height > 40000000) {
      throw const FormatException('Choose a photo smaller than 40 megapixels.');
    }
    final scale = math.min(
      1.0,
      1024 / math.max(descriptor.width, descriptor.height),
    );
    codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * scale).round()),
      targetHeight: math.max(1, (descriptor.height * scale).round()),
    );
    decoded = (await codec.getNextFrame()).image;
    final rgba = await decoded.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) throw const FormatException('Could not read this photo.');
    return await compute(_jpeg, {
      'pixels': rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
      'width': decoded.width,
      'height': decoded.height,
    });
  } finally {
    decoded?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

Uint8List _jpeg(Map<String, Object> data) {
  final pixels = data['pixels'] as Uint8List;
  final photo = img.Image.fromBytes(
    width: data['width'] as int,
    height: data['height'] as int,
    bytes: pixels.buffer,
    bytesOffset: pixels.offsetInBytes,
    numChannels: 4,
  );
  // Flatten transparency onto warm white before JPEG encoding.
  final flat = img.Image(width: photo.width, height: photo.height);
  img.fill(flat, color: img.ColorRgb8(255, 250, 243));
  img.compositeImage(flat, photo);
  final result = Uint8List.fromList(img.encodeJpg(flat, quality: 82));
  if (result.length > 1048576) {
    throw const FormatException(
      'Photo is too large. Choose a simpler or smaller image.',
    );
  }
  return result;
}
