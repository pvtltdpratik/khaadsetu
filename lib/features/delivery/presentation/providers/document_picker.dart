import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A photo the farmer chose or took (the licence, the RC).
class PickedDocument {
  const PickedDocument({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Where a document photo comes from. A seam so tests do not need a camera.
abstract class DocumentPicker {
  /// Opens the camera (or the gallery) and returns the photo, or null if the farmer backed out.
  Future<PickedDocument?> pick({required bool camera});
}

class ImagePickerDocumentPicker implements DocumentPicker {
  const ImagePickerDocumentPicker();

  @override
  Future<PickedDocument?> pick({required bool camera}) async {
    // Downscaled: a phone photo can be 10 MB, and the server accepts 5.
    final file = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, imageQuality: 80, maxWidth: 2000);
    if (file == null) return null;
    return PickedDocument(bytes: await file.readAsBytes(), filename: file.name);
  }
}

final documentPickerProvider = Provider<DocumentPicker>((ref) => const ImagePickerDocumentPicker());
