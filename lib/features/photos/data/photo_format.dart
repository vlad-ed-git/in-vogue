/// An image file's format, read from its first bytes.
enum PhotoFormat {
  jpeg('jpg'),
  png('png'),

  /// Any format YouCam does not take, such as HEIC, WebP or GIF.
  other(null);

  const PhotoFormat(this.extension);

  /// The file extension, without the dot; null for [other].
  final String? extension;

  static const _jpeg = [0xFF, 0xD8, 0xFF];
  static const _png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  /// Bytes enough to tell the format.
  static const headerLength = 8;

  /// The format of a file that starts with [header].
  static PhotoFormat of(List<int> header) {
    if (_startsWith(header, _jpeg)) return jpeg;
    if (_startsWith(header, _png)) return png;
    return other;
  }

  static bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}
