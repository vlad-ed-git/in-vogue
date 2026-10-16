import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/services/skin_rules.dart';

/// The face's colours as the skin-tone analysis reports them
/// (`data.results`: `face_quality` and `color`) and as the account keeps
/// them.
abstract final class FaceColoursModel {
  static final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

  /// The colours in an analysis's [results]. Results without readable
  /// colours count as an unclear photo: neutral colours, not clear.
  static FaceColours fromAnalysis(Object? results) {
    if (results case {
      'color': {
        'skin_color': final String skin,
        'eyebrow_color': final String eyebrow,
        'lip_color': final String lip,
        'hair_color': final String hair,
      },
    } when [skin, eyebrow, lip, hair].every(_hex.hasMatch)) {
      final quality = switch (results) {
        {'face_quality': final Map<String, Object?> quality} => quality,
        _ => const <String, Object?>{},
      };
      return FaceColours(
        skin: skin.toUpperCase(),
        eyebrow: eyebrow.toUpperCase(),
        lip: lip.toUpperCase(),
        hair: hair.toUpperCase(),
        clear:
            quality['has_face'] == true &&
            const [
              'frontal',
              'lighting',
              'faceangle',
            ].every((check) => quality[check] == 'good'),
      );
    }
    return SkinRules.neutralColours;
  }

  static Map<String, Object?> toJson(FaceColours colours) => {
    'skin': colours.skin,
    'eyebrow': colours.eyebrow,
    'lip': colours.lip,
    'hair': colours.hair,
    'clear': colours.clear,
  };

  /// Null when [json] is not readable colours.
  static FaceColours? fromJson(Map<String, Object?> json) => switch (json) {
    {
      'skin': final String skin,
      'eyebrow': final String eyebrow,
      'lip': final String lip,
      'hair': final String hair,
      'clear': final bool clear,
    } =>
      FaceColours(
        skin: skin,
        eyebrow: eyebrow,
        lip: lip,
        hair: hair,
        clear: clear,
      ),
    _ => null,
  };
}
