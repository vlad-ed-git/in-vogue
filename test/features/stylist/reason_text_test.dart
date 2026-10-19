import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/stylist/presentation/reason_text.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

final _day = DateTime.utc(2026, 9, 3);

OutfitReason _reason(
  ReasonKind kind, {
  DateTime? from,
  ColourSeason? season,
  double coldest = 13.1,
  double warmest = 31.4,
}) => OutfitReason(
  kind: kind,
  coldest: coldest,
  coldestAt: _day.add(const Duration(hours: 7)),
  warmest: warmest,
  warmestAt: _day.add(const Duration(hours: 14)),
  from: from,
  season: season,
);

void main() {
  setUpAll(initializeDateFormatting);

  final en = lookupAppLocalizations(const Locale('en'));
  final es = lookupAppLocalizations(const Locale('es'));
  final zh = lookupAppLocalizations(const Locale('zh'));
  String line(AppLocalizations l10n, OutfitReason reason, String language) =>
      reason.line(l10n, unit: TemperatureUnit.celsius, language: language);

  test('says why in English, from the day’s facts', () {
    expect(
      line(en, _reason(ReasonKind.layerOff), 'en'),
      '13° at 7 am, 31° by 2 pm: the layer comes off as it warms up.',
    );
    expect(
      line(
        en,
        _reason(ReasonKind.rain, from: _day.add(const Duration(hours: 16))),
        'en',
      ),
      'Rain from 4 pm: an outfit that takes the wet.',
    );
    expect(
      line(en, _reason(ReasonKind.rain), 'en'),
      'Rain today: an outfit that takes the wet.',
    );
    expect(
      line(en, _reason(ReasonKind.freezing, coldest: -21.6), 'en'),
      'Below freezing, -22° at the coldest: a warm coat on top.',
    );
    expect(
      line(en, _reason(ReasonKind.steady, coldest: 15, warmest: 15.2), 'en'),
      'Feels like 15° today: dressed for it.',
    );
    expect(
      line(
        en,
        _reason(ReasonKind.noSpan, season: ColourSeason.softAutumn),
        'en',
      ),
      'Nothing in the catalog spans 13° to 31°: dressed for the coldest hours. '
      'In your Soft Autumn colours.',
    );
  });

  test('in the place’s unit', () {
    expect(
      _reason(
        ReasonKind.layerOff,
      ).line(en, unit: TemperatureUnit.fahrenheit, language: 'en'),
      startsWith('56° at 7 am, 89° by 2 pm'),
    );
  });

  test(
    'every reason reads in Spanish and Chinese, with its numbers and times',
    () {
      for (final kind in ReasonKind.values) {
        for (final (l10n, language) in [(es, 'es'), (zh, 'zh')]) {
          final text = line(
            l10n,
            _reason(
              kind,
              from: _day.add(const Duration(hours: 16)),
              season: ColourSeason.trueWinter,
            ),
            language,
          );
          expect(text, isNot(contains('{')), reason: '$kind $language');
          expect(
            text,
            contains(l10n.seasonTrueWinter),
            reason: '$kind $language',
          );
          if (kind == ReasonKind.layerOff) {
            expect(
              text,
              allOf(
                contains('13°'),
                contains('31°'),
                contains('7:00'),
                contains('14:00'),
              ),
            );
          }
          if (kind == ReasonKind.rain) expect(text, contains('16:00'));
        }
      }
      expect(
        line(es, _reason(ReasonKind.home), 'es'),
        'Un día en casa: algo cómodo de llevar.',
      );
      expect(line(zh, _reason(ReasonKind.home), 'zh'), '在家的一天：穿得轻松舒服。');
    },
  );
}
