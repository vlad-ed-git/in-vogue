import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

void main() {
  test('six feels-like bands, the coldest split at 0 °C', () {
    expect(WarmthBand.forFeelsLike(26), WarmthBand.hot);
    expect(WarmthBand.forFeelsLike(25.9), WarmthBand.warm);
    expect(WarmthBand.forFeelsLike(20), WarmthBand.warm);
    expect(WarmthBand.forFeelsLike(19.9), WarmthBand.mild);
    expect(WarmthBand.forFeelsLike(14), WarmthBand.mild);
    expect(WarmthBand.forFeelsLike(13.9), WarmthBand.cool);
    expect(WarmthBand.forFeelsLike(8), WarmthBand.cool);
    expect(WarmthBand.forFeelsLike(7.9), WarmthBand.cold);
    expect(WarmthBand.forFeelsLike(0), WarmthBand.cold);
    expect(WarmthBand.forFeelsLike(-0.1), WarmthBand.freezing);
    expect(WarmthBand.forFeelsLike(-30), WarmthBand.freezing);
  });

  test('each band knows where it starts and ends', () {
    expect((WarmthBand.hot.from, WarmthBand.hot.below), (26, null));
    expect((WarmthBand.cool.from, WarmthBand.cool.below), (8, 14));
    expect((WarmthBand.cold.from, WarmthBand.cold.below), (0, 8));
    expect((WarmthBand.freezing.from, WarmthBand.freezing.below), (null, 0));
  });
}
