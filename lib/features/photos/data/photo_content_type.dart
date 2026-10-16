import 'package:path/path.dart' as p;

/// The image type of the photo file at [path], from its extension.
String photoContentType(String path) =>
    switch (p.extension(path).toLowerCase()) {
      '.png' => 'image/png',
      '.heic' || '.heif' => 'image/heic',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
