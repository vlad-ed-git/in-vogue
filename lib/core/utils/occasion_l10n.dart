import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// Localized names of an [Occasion].
extension OccasionL10n on Occasion {
  /// Name for a list of choices, such as "Work".
  String label(AppLocalizations l10n) => switch (this) {
    Occasion.work => l10n.occasionWork,
    Occasion.casual => l10n.occasionCasual,
    Occasion.goingOut => l10n.occasionGoingOut,
    Occasion.stayingIn => l10n.occasionStayingIn,
  };

  /// Name for a kicker, such as "Workday".
  String kicker(AppLocalizations l10n) => switch (this) {
    Occasion.work => l10n.occasionWorkKicker,
    Occasion.casual => l10n.occasionCasualKicker,
    Occasion.goingOut => l10n.occasionGoingOutKicker,
    Occasion.stayingIn => l10n.occasionStayingInKicker,
  };
}
