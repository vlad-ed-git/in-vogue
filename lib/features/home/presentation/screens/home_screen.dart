import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/widgets/outfit_grid.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/stylist/presentation/reason_text.dart';
import 'package:in_vogue/features/wardrobe/presentation/widgets/wardrobe_outfit_tile.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/presentation/weather_text.dart';

/// Home's tabs: today, tomorrow and the catalog to pick from.
enum HomeTab { today, tomorrow, outfits }

/// The Home tab: for today and tomorrow, the day's weather and the person
/// in the day's outfit, with Shop, all in the first view (the photo shrinks
/// to fit, down to the stage's minimum); for Outfits, the whole catalog to
/// love, a page at a time, which the weather chips narrow. Swiping moves
/// between the tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onYourPicks,
    required this.onShop,
    this.imageFor = networkImage,
    super.key,
  });

  final VoidCallback onYourPicks;

  /// Opens the pieces of an outfit: the day's, or one of the catalog's.
  final ValueChanged<CatalogOutfit> onShop;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;

  /// A photo from the web, cached on the phone.
  static ImageProvider networkImage(String url) =>
      CachedNetworkImageProvider(url);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLifecycleListener _lifecycle;

  /// Heights of what shares the first view with the photo, once laid out.
  double? _headerHeight;
  double? _belowHeight;

  bool _outfits = false;
  bool _collectionRequested = false;

  /// The chosen weather chip; null shows every outfit.
  int? _group;

  /// The day the weather showed last, to shift towards the new one.
  ForecastDay? _shownDay;

  /// A fling faster than this, in logical pixels a second, switches tabs.
  static const _swipeSpeed = 300.0;

  /// The weather chips: each feels-like band, warmest first, then rain.
  static final _rain = WarmthBand.values.length;

  /// Asks for the next page this close to the end, in logical pixels.
  static const _nextPageWithin = 800.0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<HomeBloc>().add(const HomeStarted()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  HomeBloc get _bloc => context.read<HomeBloc>();

  HomeTab _tab(HomeState state) => _outfits
      ? HomeTab.outfits
      : state.selected == ForecastDay.today
      ? HomeTab.today
      : HomeTab.tomorrow;

  void _select(HomeTab tab) {
    if (tab == HomeTab.outfits) {
      if (!_collectionRequested) {
        _collectionRequested = true;
        context.read<PicksBloc>().add(const PicksRequested.catalog());
      }
      return setState(() => _outfits = true);
    }
    setState(() => _outfits = false);
    _bloc.add(
      HomeDaySelected(
        tab == HomeTab.today ? ForecastDay.today : ForecastDay.tomorrow,
      ),
    );
  }

  void _swipe(DragEndDetails details, HomeState state) {
    final speed = details.primaryVelocity ?? 0;
    if (speed.abs() < _swipeSpeed) return;
    final index = _tab(state).index + (speed < 0 ? 1 : -1);
    if (index >= 0 && index < HomeTab.values.length) {
      _select(HomeTab.values[index]);
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<HomeBloc, HomeState>(
    builder: (context, state) => SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, viewport) => GestureDetector(
          onHorizontalDragEnd: (details) => _swipe(details, state),
          child: _outfits
              ? _collection(context, state)
              : _day(context, state, viewport),
        ),
      ),
    ),
  );

  Widget _switch(BuildContext context, HomeState state) {
    final l10n = context.translated;
    final language = Localizations.localeOf(context).languageCode;
    final date =
        state.shown.report?.weather.date ??
        state.selected.dateFrom(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(city: state.place?.city ?? '', onYourPicks: widget.onYourPicks),
        DaySwitch(
          labels: [l10n.today, l10n.tomorrow, l10n.outfitsTab],
          selectedIndex: _tab(state).index,
          onSelected: (index) => _select(HomeTab.values[index]),
          date: _outfits ? null : InVogueFormat.shortDate(date, language),
        ),
      ],
    );
  }

  Widget _day(BuildContext context, HomeState state, BoxConstraints viewport) {
    final day = state.selected;
    final direction = _shownDay == null || _shownDay == day
        ? 0
        : (day.index > _shownDay!.index ? 1 : -1);
    _shownDay = day;
    return SingleChildScrollView(
      child: PageMargin(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizeReporter(
              onSize: (size) => setState(() => _headerHeight = size.height),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _switch(context, state),
                  ShiftSwitcher(
                    direction: direction,
                    child: KeyedSubtree(
                      key: ValueKey((
                        day,
                        state.shown.report?.weather.occasion,
                        state.shown.weatherFailed,
                      )),
                      child: _weather(context, state),
                    ),
                  ),
                ],
              ),
            ),
            ..._stage(context, state, viewport),
            ..._about(context, state),
            ..._wardrobe(context, state),
            const SizedBox(height: InVogueSpace.s10),
          ],
        ),
      ),
    );
  }

  Widget _weather(BuildContext context, HomeState state) {
    final l10n = context.translated;
    final language = Localizations.localeOf(context).languageCode;
    final report = state.shown.report;
    if (report == null) {
      if (!state.shown.weatherFailed && state.status != HomeStatus.failed) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: InVogueSpace.s4),
        child: Notice(
          icon: InVogueIcons.warning,
          alert: true,
          message: l10n.weatherUnavailable,
          action: InVogueButton.secondary(
            label: l10n.retry,
            icon: InVogueIcons.retry,
            onRose: true,
            onPressed: () => _bloc.add(const HomeRetried()),
          ),
        ),
      );
    }
    final weather = report.weather;
    final unit = TemperatureUnit.forCountry(state.place?.countryCode);
    final savedAt = report.fetchedAt.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.isSaved)
          Padding(
            padding: const EdgeInsets.only(top: InVogueSpace.s3),
            child: Notice(
              icon: InVogueIcons.offline,
              message: l10n.weatherSaved(
                l10n.savedAt(
                  InVogueFormat.shortDate(savedAt, language),
                  InVogueFormat.time(savedAt, language),
                ),
              ),
            ),
          ),
        WeatherLine(
          temperature: unit.degrees(weather.temperature),
          feelsLike: unit.degrees(weather.feelsLike),
          condition: weather.condition(l10n, language),
          glyph: weather.sky.glyph,
          highlight: weather.highlight,
          dayLabel: report.day == ForecastDay.today
              ? l10n.today
              : l10n.tomorrow,
          playKey: report.day,
        ),
        OccasionLine(occasion: weather.occasion),
      ],
    );
  }

  List<Widget> _stage(
    BuildContext context,
    HomeState state,
    BoxConstraints viewport,
  ) {
    final l10n = context.translated;
    final outfit = state.shown.outfit;
    final photo = state.photo == null ? null : FileImage(File(state.photo!));
    final width = viewport.maxWidth - context.pageMargin * 2;
    final below =
        _belowHeight ??
        InVogueLayout.topBarHeight +
            InVogueSpace.s3 +
            InVogueLayout.controlHeight;
    final height = PhotoStage.heightFor(
      available:
          viewport.maxHeight - (_headerHeight ?? 0) - below - InVogueSpace.s3,
      width: width,
    );
    final notice = _notice(context, state);
    return [
      const SizedBox(height: InVogueSpace.s3),
      switch (outfit) {
        OutfitShown(:final outfit) => PhotoStage(
          state: PhotoStageState.ready,
          height: height,
          outfit: FileImage(File(outfit.picture)),
          photo: photo,
          outfitLabel: l10n.outfitPhotoSpoken(
            _reason(context, state, outfit.reason) ?? '',
          ),
        ),
        OutfitMaking(:final piece, :final pieces) => PhotoStage(
          state: PhotoStageState.waiting,
          height: height,
          photo: photo,
          progress: piece == 0 ? null : l10n.tryOnPiece(piece, pieces),
        ),
        // Home can look the outfit up only once it has the day's weather.
        OutfitLooking()
            when state.status == HomeStatus.loading ||
                (state.status == HomeStatus.ready &&
                    !state.shown.weatherFailed) =>
          PhotoStage(
            state: PhotoStageState.looking,
            height: height,
            photo: photo,
          ),
        _ => PhotoStage(
          state: PhotoStageState.idle,
          height: height,
          photo: photo,
        ),
      },
      SizeReporter(
        onSize: (size) {
          if (size.height > 0) setState(() => _belowHeight = size.height);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.shown.report case final report?)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: InVogueSpace.s3),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextLink(
                    label: l10n.changeOccasion,
                    onTap: () => _changeOccasion(context, report),
                  ),
                ),
              ),
            if (outfit case OutfitShown(outfit: DayOutfit(:final outfit?)))
              Padding(
                padding: const EdgeInsets.only(top: InVogueSpace.s2),
                child: InVogueButton.primary(
                  label: l10n.shop,
                  onPressed: () => widget.onShop(outfit),
                ),
              ),
          ],
        ),
      ),
      if (notice != null) ...[const SizedBox(height: InVogueSpace.s3), notice],
    ];
  }

  Future<void> _changeOccasion(
    BuildContext context,
    WeatherReport report,
  ) async {
    final chosen = await showOccasionSheet(
      context: context,
      current: report.weather.occasion,
      day: report.day,
      date: InVogueFormat.shortDate(
        report.weather.date,
        Localizations.localeOf(context).languageCode,
      ),
    );
    if (chosen != null) _bloc.add(HomeOccasionChanged(chosen));
  }

  /// What is said below the photo when there is no outfit to show.
  Widget? _notice(BuildContext context, HomeState state) {
    final l10n = context.translated;
    return switch (state.shown.outfit) {
      OutfitFailed(
        failure: TryOnFailure(
              problem: TryOnProblem.noCredit ||
                  TryOnProblem.unavailable ||
                  TryOnProblem.photo,
            ) &&
            final failure,
      ) =>
        Notice(
          icon: InVogueIcons.warning,
          alert: true,
          message: failure.uiFriendlyMessage(context),
        ),
      OutfitFailed(:final failure) => Notice(
        icon: InVogueIcons.warning,
        alert: true,
        message: failure.uiFriendlyMessage(context),
        action: InVogueButton.secondary(
          label: l10n.retry,
          icon: InVogueIcons.retry,
          onRose: true,
          onPressed: () => _bloc.add(const HomeRetried()),
        ),
      ),
      _ => null,
    };
  }

  /// Why the day's outfit was chosen, in the place's unit.
  String? _reason(
    BuildContext context,
    HomeState state,
    OutfitReason? reason,
  ) => reason?.line(
    context.translated,
    unit: TemperatureUnit.forCountry(state.place?.countryCode),
    language: Localizations.localeOf(context).languageCode,
  );

  List<Widget> _about(BuildContext context, HomeState state) {
    final reason = switch (state.shown.outfit) {
      OutfitShown(:final outfit) => _reason(context, state, outfit.reason),
      _ => null,
    };
    if (reason == null) return const [];
    return [
      SectionHeading(context.translated.aboutThisOutfit),
      Text(reason, style: InVogueType.body),
    ];
  }

  /// The person's own outfit for the day, when one suits it.
  List<Widget> _wardrobe(BuildContext context, HomeState state) {
    final outfit = state.wardrobeFor(state.selected);
    if (outfit == null) return const [];
    return [
      SectionHeading(context.translated.wardrobeTitle),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: WardrobeOutfitTile(
              outfit: outfit,
              imageFor: widget.imageFor,
            ),
          ),
          const SizedBox(width: InVogueLayout.gutter),
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
    ];
  }

  Widget _collection(BuildContext context, HomeState state) {
    final l10n = context.translated;
    final group = _group;
    return BlocBuilder<PicksBloc, PicksState>(
      builder: (context, picks) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (picks.hasMore &&
              notification.metrics.extentAfter < _nextPageWithin) {
            context.read<PicksBloc>().add(const PicksMoreRequested());
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageMargin(child: _switch(context, state)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: context.pageMargin,
                  top: InVogueSpace.s3,
                ),
                child: CategoryChips(
                  labels: [
                    l10n.weatherHot,
                    l10n.weatherWarm,
                    l10n.weatherMild,
                    l10n.weatherCool,
                    l10n.weatherCold,
                    l10n.weatherFreezing,
                    l10n.weatherRain,
                  ],
                  selectedIndex: group,
                  onSelected: (index) {
                    setState(() => _group = index);
                    context.read<PicksBloc>().add(
                      PicksRequested.catalog(_filter(index)),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: PageMargin(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: InVogueSpace.s2,
                    bottom: InVogueSpace.s4,
                  ),
                  child: group == null
                      ? null
                      : Text(
                          _groupLine(context, state, group),
                          style: InVogueType.meta.copyWith(
                            color: InVogueColors.graphite,
                          ),
                        ),
                ),
              ),
            ),
            if (picks.status == PicksStatus.loading)
              const SliverToBoxAdapter(
                child: PageMargin(child: RunningRule.content()),
              ),
            if (picks.status == PicksStatus.failed)
              SliverToBoxAdapter(
                child: PageMargin(
                  child: Notice(
                    icon: InVogueIcons.warning,
                    alert: true,
                    message: picks.loadFailure!.uiFriendlyMessage(context),
                    action: InVogueButton.secondary(
                      label: l10n.retry,
                      icon: InVogueIcons.retry,
                      onRose: true,
                      onPressed: () => context.read<PicksBloc>().add(
                        PicksRequested.catalog(_filter(group)),
                      ),
                    ),
                  ),
                ),
              ),
            SliverOutfitGrid(
              outfits: picks.outfits,
              picks: picks.picks,
              imageFor: widget.imageFor,
              onOpen: widget.onShop,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: InVogueSpace.s10)),
          ],
        ),
      ),
    );
  }

  /// The outfits a weather chip shows.
  static CatalogFilter _filter(int? group) => group == null
      ? const CatalogFilter.all()
      : group == _rain
      ? const CatalogFilter.rain()
      : CatalogFilter.weather(WarmthBand.values[group]);

  /// What the chosen weather chip means, in the place's unit.
  String _groupLine(BuildContext context, HomeState state, int group) {
    final l10n = context.translated;
    if (group == _rain) return l10n.rainOutfits;
    final band = WarmthBand.values[group];
    final unit = TemperatureUnit.forCountry(state.place?.countryCode);
    final from = band.from;
    final below = band.below;
    if (below == null) return l10n.feelsLikeFrom(unit.degrees(from!));
    if (from == null) return l10n.feelsLikeBelow(unit.degrees(below));
    return l10n.feelsLikeRange(unit.degrees(from), unit.degrees(below));
  }
}
