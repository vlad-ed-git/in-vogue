import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';

abstract interface class PhotoPickerDataSource {
  /// A copy of the chosen photo; null when the person cancels. Throws
  /// [PhotoException].
  Future<String?> choose();
}

/// The system photo picker: Photos on iOS, the photo picker or gallery on
/// Android. The app receives only the chosen photo and never the camera.
class PhotoPickerDataSourceImpl implements PhotoPickerDataSource {
  final _picker = ImagePicker();

  /// Longest side, in pixels: enough for a try-on, well under 10 MB.
  static const maxSide = 2048.0;

  /// JPEG quality of the copy.
  static const quality = 90;

  @override
  Future<String?> choose() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
        // Without full metadata iOS needs no photo library permission.
        requestFullMetadata: false,
      );
      return photo?.path;
    } on PlatformException catch (error, stack) {
      throw PhotoException(error, stack);
    }
  }
}
