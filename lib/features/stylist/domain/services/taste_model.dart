import 'dart:math' as math;

import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';

/// An outfit's taste features (design Appendix D), standardised over the
/// catalog. Each group of them (colours, pattern, style, shape, fabric,
/// dressiness and warmth, lounge) weighs alike, so one shape counts as much
/// as a whole palette, and an outfit's features come to about unit length,
/// so a draw from the prior stays moderate. The last feature is the bias.
class TasteFeatures {
  TasteFeatures(List<CatalogOutfit> catalog) {
    final raws = [for (final outfit in catalog) _raw(outfit)];
    for (var i = 0; i < _count; i++) {
      final values = [for (final raw in raws) raw[i]];
      final mean = values.isEmpty
          ? 0.0
          : values.reduce((a, b) => a + b) / values.length;
      final variance = values.isEmpty
          ? 0.0
          : values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
                values.length;
      _mean[i] = mean;
      _spread[i] = variance > 0 ? math.sqrt(variance) : 1;
    }
  }

  /// The colour families, as the catalog names them.
  static const families = [
    'black',
    'white',
    'cream',
    'grey',
    'beige',
    'brown',
    'navy',
    'blue',
    'green',
    'olive',
    'yellow',
    'orange',
    'red',
    'pink',
    'purple',
  ];

  /// The catalog's nine styles.
  static const styles = [
    'minimal',
    'relaxed',
    'classic',
    'romantic',
    'sporty',
    'preppy',
    'utility',
    'boho',
    'edgy',
  ];

  static const _knitwear = {'sweater', 'cardigan', 'sweatervest'};

  /// How many features each group holds, in order.
  static const _groups = [15, 5, 9, 10, 2, 2, 1];

  /// Each feature's scale: every group's share of the length alike.
  static final List<double> _weights = [
    for (final size in _groups)
      for (var i = 0; i < size; i++) 1 / math.sqrt(size * _groups.length),
  ];

  /// Features before the bias.
  static const _count = 44;

  /// Every feature, the bias included.
  static const size = _count + 1;

  final _mean = List<double>.filled(_count, 0);
  final _spread = List<double>.filled(_count, 1);

  /// [outfit]'s features.
  List<double> of(CatalogOutfit outfit) => _scaled(_raw(outfit));

  /// The features of an outfit of the person's own, from its colour
  /// [families] only: every other feature, and the bias, says nothing.
  List<double> ofColours(Set<String> families) {
    final known = [
      for (final family in families)
        if (TasteFeatures.families.contains(family)) family,
    ];
    final x = List<double>.filled(size, 0);
    if (known.isEmpty) return x;
    for (var i = 0; i < TasteFeatures.families.length; i++) {
      final share = known.contains(TasteFeatures.families[i])
          ? 1 / known.length
          : 0.0;
      x[i] = (share - _mean[i]) / _spread[i] * _weights[i];
    }
    return x;
  }

  List<double> _scaled(List<double> raw) => [
    for (var i = 0; i < _count; i++)
      (raw[i] - _mean[i]) / _spread[i] * _weights[i],
    1 / math.sqrt(size),
  ];

  /// Appendix D, 1 to 44.
  static List<double> _raw(CatalogOutfit outfit) {
    final pieces = outfit.pieces;
    final count = pieces.isEmpty ? 1 : pieces.length;
    double has(bool Function(OutfitPiece piece) test) =>
        pieces.any(test) ? 1 : 0;
    double kind(Set<String> kinds) => outfit.kinds.any(kinds.contains) ? 1 : 0;
    return [
      for (final family in families)
        pieces.where((piece) => piece.family == family).length / count,
      pieces.isNotEmpty && pieces.every((piece) => piece.neutral) ? 1 : 0,
      {for (final piece in pieces) piece.family}.length == 1 ? 1 : 0,
      has((piece) => piece.pattern == ColourPattern.striped),
      has((piece) => piece.pattern == ColourPattern.checked),
      has((piece) => piece.pattern == ColourPattern.printed),
      for (final style in styles) outfit.styles.contains(style) ? 1 : 0,
      kind({'dress', 'jumpsuit'}),
      kind({'skirt'}),
      kind({'shorts'}),
      kind({'jeans'}),
      has((piece) => piece.shape == 'wide' || piece.shape == 'barrel'),
      has((piece) => piece.length == 'mini'),
      has((piece) => piece.role == PieceRole.top && piece.length == 'cropped'),
      has((piece) => piece.role == PieceRole.over),
      outfit.coat ? 1 : 0,
      kind(_knitwear),
      has((piece) => piece.fibre == 'silk'),
      has((piece) => piece.fibre == 'linen'),
      outfit.dressy,
      outfit.warmth.toDouble(),
      outfit.occasions.contains(Occasion.stayingIn) ? 1 : 0,
    ];
  }
}

/// The person's taste: a Bayesian linear model over [TasteFeatures]
/// (design §8.2). Each signal adds `ω·x·xᵀ` to the precision and `ω·y·x`
/// to `b`; the mean weights solve `Λ·μ = b`.
class TasteModel {
  TasteModel._(this._precision, this._b);

  /// Weights start near zero: the prior's precision is `I / 0.5²`.
  factory TasteModel.prior() => TasteModel._([
    for (var i = 0; i < TasteFeatures.size; i++)
      for (var j = 0; j < TasteFeatures.size; j++)
        i == j ? 1 / (priorScale * priorScale) : 0.0,
  ], List<double>.filled(TasteFeatures.size, 0));

  /// What [signals] teach, the outfits' features read from [features] and
  /// [catalog]; a signal about an outfit the catalog lacks is left out.
  factory TasteModel.learn(
    Iterable<TasteSignal> signals, {
    required TasteFeatures features,
    required Map<String, CatalogOutfit> catalog,
  }) {
    final model = TasteModel.prior();
    for (final signal in signals) {
      final outfit = catalog[signal.outfitId];
      final x = signal.kind == TasteSignalKind.wardrobe
          ? features.ofColours(signal.families)
          : outfit == null
          ? null
          : features.of(outfit);
      if (x != null) model._learn(x, signal.kind);
    }
    return model;
  }

  /// The prior's spread of each weight.
  static const priorScale = 0.5;

  static const _n = TasteFeatures.size;

  /// Row by row.
  final List<double> _precision;
  final List<double> _b;

  void _learn(List<double> x, TasteSignalKind kind) {
    final w = kind.weight;
    for (var i = 0; i < _n; i++) {
      if (x[i] == 0) continue;
      _b[i] += w * kind.label * x[i];
      for (var j = 0; j < _n; j++) {
        _precision[i * _n + j] += w * x[i] * x[j];
      }
    }
  }

  /// The mean weights.
  List<double> mean() {
    final lower = _cholesky();
    return _solveTransposed(lower, _solve(lower, _b));
  }

  /// Weights drawn from the posterior with [random], for exploring.
  List<double> draw(math.Random random) {
    final lower = _cholesky();
    final mean = _solveTransposed(lower, _solve(lower, _b));
    final z = [for (var i = 0; i < _n; i++) _gaussian(random)];
    // With Λ = L·Lᵀ, L⁻ᵀ·z has covariance Λ⁻¹.
    final spread = _solveTransposed(lower, z);
    return [for (var i = 0; i < _n; i++) mean[i] + spread[i]];
  }

  /// How much [weights] like features [x], 0 to 1.
  static double score(List<double> weights, List<double> x) {
    var sum = 0.0;
    for (var i = 0; i < x.length; i++) {
      sum += weights[i] * x[i];
    }
    return 1 / (1 + math.exp(-sum));
  }

  /// L with Λ = L·Lᵀ; Λ is positive definite, the prior making it so.
  List<double> _cholesky() {
    final lower = List<double>.filled(_n * _n, 0);
    for (var i = 0; i < _n; i++) {
      for (var j = 0; j <= i; j++) {
        var sum = _precision[i * _n + j];
        for (var k = 0; k < j; k++) {
          sum -= lower[i * _n + k] * lower[j * _n + k];
        }
        lower[i * _n + j] = i == j ? math.sqrt(sum) : sum / lower[j * _n + j];
      }
    }
    return lower;
  }

  /// y with L·y = v.
  static List<double> _solve(List<double> lower, List<double> v) {
    final y = List<double>.filled(_n, 0);
    for (var i = 0; i < _n; i++) {
      var sum = v[i];
      for (var k = 0; k < i; k++) {
        sum -= lower[i * _n + k] * y[k];
      }
      y[i] = sum / lower[i * _n + i];
    }
    return y;
  }

  /// x with Lᵀ·x = y.
  static List<double> _solveTransposed(List<double> lower, List<double> y) {
    final x = List<double>.filled(_n, 0);
    for (var i = _n - 1; i >= 0; i--) {
      var sum = y[i];
      for (var k = i + 1; k < _n; k++) {
        sum -= lower[k * _n + i] * x[k];
      }
      x[i] = sum / lower[i * _n + i];
    }
    return x;
  }

  static double _gaussian(math.Random random) {
    final u = 1 - random.nextDouble();
    final v = random.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }

  /// A seed every phone shares for [key], such as an account, a date and
  /// an occasion: so each makes the same draw.
  static int seed(String key) {
    // FNV-1a, 32 bits: the same on every platform.
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
