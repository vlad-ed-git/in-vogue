import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/domain/entities/account_setup.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:path/path.dart' as p;

/// A photo kept on the account: its Storage path, revision and download
/// URL.
typedef AccountPhoto = ({String path, int revision, String? url});

/// The account document's fields and the account's Storage paths.
abstract final class AccountModel {
  /// The plan every new account gets in the demo.
  static const demoPlan = 'pro';

  /// Where [photo] is kept in Storage for the account [accountId].
  static String photoPath(String accountId, UserPhoto photo) =>
      'users/$accountId/photos/${p.basename(photo.path)}';

  /// The plan recorded in an account document; null when there is none.
  static AccountPlan? planFromJson(Object? json) => switch (json) {
    {'plan': final String plan} => AccountPlan.values.asNameMap()[plan],
    _ => null,
  };

  /// The photos recorded in an account document; unreadable ones are left
  /// out.
  static Map<PhotoRole, AccountPhoto> photosFromJson(Object? json) => {
    if (json case {'photos': final Map<Object?, Object?> photos})
      for (final role in PhotoRole.values)
        if (photos[role.name]
            case {'path': final String path, 'revision': final int revision} &&
                final Map<Object?, Object?> photo)
          role: (
            path: path,
            revision: revision,
            url: switch (photo['url']) {
              final String url => url,
              _ => null,
            },
          ),
  };

  /// The fields to merge into the account document. [created] adds the
  /// demo plan, which only a new account receives.
  static Map<String, Object?> toJson(
    AccountSetup setup, {
    required Map<PhotoRole, AccountPhoto> photos,
    required bool created,
  }) => {
    'name': ?setup.name,
    if (setup.location case final location?)
      'location': {
        'city': location.city,
        'countryCode': location.countryCode,
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
    if (photos.isNotEmpty)
      'photos': {
        for (final MapEntry(key: role, value: photo) in photos.entries)
          role.name: {
            'path': photo.path,
            'revision': photo.revision,
            'url': ?photo.url,
          },
      },
    if (created) 'plan': demoPlan,
  };
}
