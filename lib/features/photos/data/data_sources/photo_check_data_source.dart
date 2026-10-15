import 'package:flutter/services.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';

abstract interface class PhotoCheckDataSource {
  /// Whether the photo at [path] shows a person head to toe. Throws
  /// [PhotoException] when it cannot be read.
  Future<bool> isFullLength(String path);
}

/// The phone's own body-pose detection, on the device: Vision on iOS, ML Kit
/// on Android (see PhotoCheck.swift and PhotoCheck.kt).
class PhotoCheckDataSourceImpl implements PhotoCheckDataSource {
  PhotoCheckDataSourceImpl([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  final MethodChannel _channel;

  static const channelName = 'in_vogue/photo_check';

  @override
  Future<bool> isFullLength(String path) async {
    try {
      final fullLength = await _channel.invokeMethod<bool>('isFullLength', {
        'path': path,
      });
      if (fullLength == null) {
        throw PhotoException(
          const FormatException('The check gave no answer'),
          StackTrace.current,
        );
      }
      return fullLength;
    } on PlatformException catch (error, stack) {
      throw PhotoException(error, stack);
    } on MissingPluginException catch (error, stack) {
      throw PhotoException(error, stack);
    }
  }
}
