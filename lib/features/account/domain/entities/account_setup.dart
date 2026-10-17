import 'package:equatable/equatable.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';

/// What setup keeps on the phone, to save on the person's account.
class AccountSetup extends Equatable {
  const AccountSetup({
    this.name,
    this.location,
    this.body,
    this.face,
    this.picks = const {},
    this.syncedPicks = const {},
  });

  /// Null before the person chooses one.
  final String? name;
  final UserLocation? location;
  final UserPhoto? body;
  final UserPhoto? face;

  /// Ids of the loved colourways.
  final Set<String> picks;

  /// The picks this phone last saved on the account: only these can be
  /// removed from it.
  final Set<String> syncedPicks;

  @override
  List<Object?> get props => [name, location, body, face, picks, syncedPicks];
}
