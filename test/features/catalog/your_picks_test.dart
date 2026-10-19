import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/your_picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/screens/your_picks_screen.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/catalog_outfits.dart';
import '../../helpers/pump_in_vogue.dart';
import '../../helpers/taste.dart';

final _dress = outfit('o1', name: 'Black satin slip dress');
final _tee = outfit('o2', name: 'White organic tee, light jeans');

class _Catalog implements OutfitCatalogRepository {
  @override
  Future<Either<Failure, List<CatalogOutfit>>> outfits() async =>
      Right([_dress, _tee]);

  @override
  Future<Either<Failure, List<CatalogOutfit>>> sample() async =>
      const Right([]);
}

/// Picks in the order they were loved.
class _Picks implements PicksRepository {
  _Picks(this.loved);
  final List<String> loved;

  @override
  Future<Either<Failure, Set<String>>> picks() async => Right({...loved});

  @override
  Future<Either<Failure, Unit>> clear() async {
    loved.clear();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Set<String>>> setPick(
    String colourwayId, {
    required bool loved,
  }) async {
    loved ? this.loved.add(colourwayId) : this.loved.remove(colourwayId);
    return Right({...this.loved});
  }

  @override
  Future<Either<Failure, Set<String>>> addPicks(Set<String> colourwayIds) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Set<String>>> removePicks(Set<String> colourwayIds) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Set<String>>> synced(String accountId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> markSynced(
    String accountId,
    Set<String> picks,
  ) => throw UnimplementedError();
}

void main() {
  late MemoryTaste taste;
  late _Picks picks;

  YourPicksBloc buildBloc() => YourPicksBloc(
    getPicks: GetPicks(picks),
    getOutfits: GetOutfits(_Catalog()),
    setPick: SetPick(picks),
    recordSignal: recordSignalInto(taste),
  );

  // A piece loved before picks became outfits is left out.
  setUp(() {
    picks = _Picks(['o2', 'everlane:tee-white', 'o1']);
    taste = MemoryTaste();
  });

  blocTest<YourPicksBloc, YourPicksState>(
    'shows only the loved outfits, the latest first',
    build: buildBloc,
    act: (bloc) => bloc.add(const YourPicksLoaded()),
    expect: () => [
      YourPicksState(status: YourPicksStatus.ready, picks: [_dress, _tee]),
    ],
  );

  blocTest<YourPicksBloc, YourPicksState>(
    'removes a pick once it is confirmed',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const YourPicksLoaded());
      await bloc.stream.first;
      bloc.add(const YourPickRemoved('o1'));
    },
    skip: 1,
    expect: () => [
      YourPicksState(status: YourPicksStatus.ready, picks: [_tee]),
    ],
    verify: (_) {
      expect(picks.loved, ['o2', 'everlane:tee-white']);
      // The removal teaches the taste model.
      expect(taste.phone.single.kind, TasteSignalKind.unloved);
      expect(taste.phone.single.outfitId, 'o1');
    },
  );

  group('YourPicksScreen', () {
    late _MockYourPicksBloc bloc;

    setUpAll(() => registerFallbackValue(const YourPicksLoaded()));

    Future<void> pumpScreen(
      WidgetTester tester, {
      List<CatalogOutfit>? shown,
    }) async {
      bloc = _MockYourPicksBloc();
      whenListen(
        bloc,
        const Stream<YourPicksState>.empty(),
        initialState: YourPicksState(
          status: YourPicksStatus.ready,
          picks: shown ?? [_dress, _tee],
        ),
      );
      await pumpInVogue(
        tester,
        BlocProvider<YourPicksBloc>.value(
          value: bloc,
          child: YourPicksScreen(onBack: () {}, imageFor: (_) => testImage),
        ),
        scroll: false,
      );
      await tester.pump();
    }

    Future<void> openRemoval(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Love Black satin slip dress'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('shows the picks and nothing else', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Your picks'), findsOneWidget);
      expect(find.byType(ProductTile), findsNWidgets(2));
      expect(find.text('Black satin slip dress'), findsOneWidget);
      expect(find.text('White organic tee, light jeans'), findsOneWidget);
      expect(find.byType(WeatherLine), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    });

    testWidgets('asks before removing a pick, and keeps it on Keep', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openRemoval(tester);
      expect(find.text('Remove from your picks?'), findsOneWidget);
      await tester.tap(find.text('Keep'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Remove from your picks?'), findsNothing);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('removes a pick on Remove', (tester) async {
      await pumpScreen(tester);
      await openRemoval(tester);
      await tester.tap(find.text('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verify(() => bloc.add(const YourPickRemoved('o1'))).called(1);
    });

    testWidgets('says when nothing is picked yet', (tester) async {
      await pumpScreen(tester, shown: const []);
      expect(find.text('You haven’t picked anything yet.'), findsOneWidget);
      expect(find.byType(ProductTile), findsNothing);
    });
  });
}

class _MockYourPicksBloc extends MockBloc<YourPicksEvent, YourPicksState>
    implements YourPicksBloc {}
