import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/services/season_rules.dart';

/// The face's colours as the skin-tone analysis reports them
/// (`data.results`: `face_quality` and `color`) and as the account keeps
/// them.
abstract final class FaceColoursModel {
  static final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

  /// The colours in an analysis's [results]. Results without readable
  /// colours count as an unclear photo: neutral colours, not clear. The
  /// analysis refuses photos it can't read, so a success that reports no
  /// face quality is clear.
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
        _ => null,
      };
      final eye = switch (results) {
        {'color': {'eye_color': final String eye}} when _hex.hasMatch(eye) =>
          eye.toUpperCase(),
        _ => null,
      };
      return FaceColours(
        skin: skin.toUpperCase(),
        eyebrow: eyebrow.toUpperCase(),
        lip: lip.toUpperCase(),
        hair: hair.toUpperCase(),
        eye: eye,
        clear:
            quality == null ||
            quality['has_face'] == true &&
                const [
                  'frontal',
                  'lighting',
                  'faceangle',
                ].every((check) => quality[check] == 'good'),
      );
    }
    return SeasonRules.neutralColours;
  }

  static Map<String, Object?> toJson(FaceColours colours) => {
    'skin': colours.skin,
    'eyebrow': colours.eyebrow,
    'lip': colours.lip,
    'hair': colours.hair,
    'eye': ?colours.eye,
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
        eye: json['eye'] is String ? json['eye']! as String : null,
        clear: clear,
      ),
    _ => null,
  };
}
