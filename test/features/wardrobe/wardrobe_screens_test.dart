import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/add_outfit_bloc.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/wardrobe_bloc.dart';
import 'package:in_vogue/features/wardrobe/presentation/screens/add_outfit_screen.dart';
import 'package:in_vogue/features/wardrobe/presentation/widgets/wardrobe_section.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockWardrobeBloc extends MockBloc<WardrobeEvent, WardrobeState>
    implements WardrobeBloc {}

class _MockAddOutfitBloc extends MockBloc<AddOutfitEvent, AddOutfitState>
    implements AddOutfitBloc {}

final _suit = WardrobeOutfit(
  id: 'outfit-1',
  details: const OutfitDetails(
    name: 'Navy work suit',
    colour: OutfitColour.navy,
    bands: {WarmthBand.mild, WarmthBand.cool},
    rain: true,
    occasions: {Occasion.work},
  ),
  photoUrl: 'https://photos/outfit-1.jpg',
  createdAt: DateTime(2026, 10, 18, 9),
);

final _jeans = WardrobeOutfit(
  id: 'outfit-2',
  details: const OutfitDetails(
    name: 'Weekend jeans',
    colour: OutfitColour.blue,
    bands: {WarmthBand.warm},
    occasions: {Occasion.casual},
  ),
  photoUrl: 'https://photos/outfit-2.jpg',
  createdAt: DateTime(2026, 10, 18, 10),
);

void main() {
  setUpAll(() {
    registerFallbackValue(WardrobeOutfitRemoved(_suit));
    registerFallbackValue(const AddOutfitSaved());
  });

  group('WardrobeSection', () {
    late _MockWardrobeBloc wardrobe;
    late int adds;

    Future<void> pumpSection(WidgetTester tester, WardrobeState state) async {
      wardrobe = _MockWardrobeBloc();
      adds = 0;
      whenListen(
        wardrobe,
        const Stream<WardrobeState>.empty(),
        initialState: state,
      );
      await pumpInVogue(
        tester,
        BlocProvider<WardrobeBloc>.value(
          value: wardrobe,
          child: WardrobeSection(
            onAddOutfit: () => adds++,
            imageFor: (_) => testImage,
          ),
        ),
      );
      await pumpWhileLoading(tester);
    }

    testWidgets('asks for outfits while it is empty, and adds one', (
      tester,
    ) async {
      await pumpSection(
        tester,
        const WardrobeState(status: WardrobeStatus.ready),
      );
      expect(find.text('My wardrobe'), findsOneWidget);
      expect(find.text('Add photos of outfits you own.'), findsOneWidget);
      await tester.tap(find.text('Add an outfit'));
      expect(adds, 1);
    });

    testWidgets('shows the outfits in a grid, newest first', (tester) async {
      await pumpSection(
        tester,
        WardrobeState(status: WardrobeStatus.ready, outfits: [_jeans, _suit]),
      );
      expect(find.text('Add photos of outfits you own.'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Weekend jeans')).dx,
        lessThan(tester.getTopLeft(find.text('Navy work suit')).dx),
      );
      expect(find.byType(PhotoSlot), findsNWidgets(2));
    });

    testWidgets('a tile opens its details, and removing asks first', (
      tester,
    ) async {
      await pumpSection(
        tester,
        WardrobeState(status: WardrobeStatus.ready, outfits: [_suit]),
      );
      await tester.tap(find.text('Navy work suit'));
      await pumpWhileLoading(tester);
      expect(find.text('Navy'), findsOneWidget);
      expect(find.text('Mild · Cool · Rain'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      await tester.tap(findLink('Remove from my wardrobe'));
      await pumpWhileLoading(tester);
      expect(find.text('Remove this outfit?'), findsOneWidget);
      await tester.tap(find.text('Keep'));
      await pumpWhileLoading(tester);
      verifyNever(() => wardrobe.add(any()));
      await tester.tap(findLink('Remove from my wardrobe'));
      await pumpWhileLoading(tester);
      await tester.tap(find.widgetWithText(InVogueButton, 'Remove'));
      await pumpWhileLoading(tester);
      verify(() => wardrobe.add(WardrobeOutfitRemoved(_suit))).called(1);
      expect(find.text('Mild · Cool · Rain'), findsNothing);
    });

    testWidgets('runs the rule while the outfits load', (tester) async {
      await pumpSection(tester, const WardrobeState());
      expect(find.byType(RunningRule), findsOneWidget);
    });
  });

  group('AddOutfitScreen', () {
    late _MockAddOutfitBloc add;
    late int done;

    Future<void> pumpAdd(
      WidgetTester tester,
      AddOutfitState state, {
      Stream<AddOutfitState> states = const Stream.empty(),
      Size size = const Size(390, 844),
      double textScale = 1,
    }) async {
      add = _MockAddOutfitBloc();
      done = 0;
      whenListen(add, states, initialState: state);
      await pumpInVogue(
        tester,
        BlocProvider<AddOutfitBloc>.value(
          value: add,
          child: AddOutfitScreen(onDone: () => done++),
        ),
        scroll: false,
        size: size,
        textScale: textScale,
      );
      await pumpWhileLoading(tester);
    }

    InVogueButton save(WidgetTester tester) => tester.widget<InVogueButton>(
      find.widgetWithText(InVogueButton, 'Save to my wardrobe'),
    );

    testWidgets('asks for the photo, the name, the colour, the weather and '
        'the occasion; Save waits for all of them', (tester) async {
      await pumpAdd(tester, const AddOutfitState());
      expect(find.text('Add an outfit'), findsOneWidget);
      expect(find.text('NAME'), findsOneWidget);
      for (final heading in ['Colour', 'Weather', 'Occasion']) {
        expect(find.text(heading), findsOneWidget);
      }
      expect(save(tester).onPressed, isNull);
    });

    testWidgets('sends what is chosen to the bloc', (tester) async {
      await pumpAdd(tester, const AddOutfitState());
      await tester.tap(find.text('Choose from Gallery'));
      verify(() => add.add(const AddOutfitPhotoRequested())).called(1);
      await tester.enterText(find.byType(TextField), 'Navy work suit');
      verify(() => add.add(const AddOutfitNameChanged('Navy work suit')));
      await tester.ensureVisible(find.bySemanticsLabel('Navy'));
      await tester.tap(find.bySemanticsLabel('Navy'));
      verify(
        () => add.add(const AddOutfitColourChosen(OutfitColour.navy)),
      ).called(1);
      await tester.ensureVisible(find.text('Rain'));
      await tester.tap(find.text('Mild'));
      await tester.tap(find.text('Rain'));
      verify(
        () => add.add(const AddOutfitBandToggled(WarmthBand.mild)),
      ).called(1);
      verify(() => add.add(const AddOutfitRainToggled())).called(1);
      await tester.ensureVisible(find.text('Work'));
      await tester.tap(find.text('Work'));
      verify(
        () => add.add(const AddOutfitOccasionToggled(Occasion.work)),
      ).called(1);
    });

    testWidgets('saves, then goes back', (tester) async {
      const ready = AddOutfitState(
        photo: '/cache/look.jpg',
        name: 'Navy work suit',
        colour: OutfitColour.navy,
        bands: {WarmthBand.mild},
        occasions: {Occasion.work},
      );
      await pumpAdd(
        tester,
        ready,
        states: Stream.value(ready.copyWith(saved: true)),
      );
      expect(done, 1);
    });

    testWidgets('Save is on once everything is chosen', (tester) async {
      await pumpAdd(
        tester,
        const AddOutfitState(
          photo: '/cache/look.jpg',
          name: 'Navy work suit',
          colour: OutfitColour.navy,
          bands: {WarmthBand.mild},
          occasions: {Occasion.work},
        ),
      );
      await tester.ensureVisible(
        find.widgetWithText(InVogueButton, 'Save to my wardrobe'),
      );
      await tester.tap(
        find.widgetWithText(InVogueButton, 'Save to my wardrobe'),
      );
      verify(() => add.add(const AddOutfitSaved())).called(1);
    });

    testWidgets('fits a 320-point phone at 200% text', (tester) async {
      await pumpAdd(
        tester,
        const AddOutfitState(),
        size: const Size(320, 640),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
