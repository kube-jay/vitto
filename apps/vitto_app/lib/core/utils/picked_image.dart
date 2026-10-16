import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// An image chosen in the browser, resized/re-encoded by the picker (which
/// also drops EXIF metadata such as GPS location).
class PickedImage {
  const PickedImage(this.bytes, this.mime);

  final Uint8List bytes;
  final String mime;
}

const _allowed = {'image/jpeg', 'image/png', 'image/webp'};
const maxImageBytes = 5 * 1024 * 1024;

Future<List<PickedImage>> pickImages({required int max}) async {
  if (max <= 0) return const [];
  final files = await ImagePicker().pickMultiImage(
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
    limit: max > 1 ? max : null,
  );
  final result = <PickedImage>[];
  for (final f in files.take(max)) {
    final picked = await _read(f);
    if (picked != null) result.add(picked);
  }
  return result;
}

Future<PickedImage?> pickSingleImage() async {
  final f = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 85,
  );
  return f == null ? null : _read(f);
}

Future<PickedImage?> _read(XFile f) async {
  final bytes = await f.readAsBytes();
  final name = f.name.toLowerCase();
  final mime =
      f.mimeType ??
      (name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg');
  if (!_allowed.contains(mime) || bytes.lengthInBytes > maxImageBytes) {
    return null;
  }
  return PickedImage(bytes, mime);
}
