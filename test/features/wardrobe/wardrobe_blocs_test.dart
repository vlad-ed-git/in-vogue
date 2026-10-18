import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/usecases/choose_photo.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:in_vogue/features/wardrobe/domain/usecases/wardrobe_usecases.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/add_outfit_bloc.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/wardrobe_bloc.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'wardrobe_blocs_test.mocks.dart';

const _details = OutfitDetails(
  name: 'Navy work suit',
  colour: OutfitColour.navy,
  bands: {WarmthBand.mild},
  occasions: {Occasion.work},
);

final _outfit = WardrobeOutfit(
  id: 'outfit-1',
  details: _details,
  photoUrl: 'https://photos/outfit-1.jpg',
  createdAt: DateTime(2026, 10, 18),
);

@GenerateMocks([GetCurrentAccount, ChoosePhoto, WardrobeRepository])
void main() {
  late MockGetCurrentAccount account;
  late MockChoosePhoto choose;
  late MockWardrobeRepository wardrobe;

  setUp(() {
    provideDummy<Either<Failure, Account?>>(const Right(null));
    provideDummy<Either<Failure, ChosenPhoto?>>(const Right(null));
    provideDummy<Either<Failure, WardrobeOutfit>>(Right(_outfit));
    provideDummy<Either<Failure, Unit>>(const Right(unit));
    account = MockGetCurrentAccount();
    choose = MockChoosePhoto();
    wardrobe = MockWardrobeRepository();
    when(
      account(const NoParams()),
    ).thenAnswer((_) async => const Right(Account(id: 'uid-1')));
  });

  group('WardrobeBloc', () {
    WardrobeBloc build() => WardrobeBloc(
      getCurrentAccount: account,
      watchWardrobe: WatchWardrobe(wardrobe),
      removeFromWardrobe: RemoveFromWardrobe(wardrobe),
    );

    blocTest<WardrobeBloc, WardrobeState>(
      "follows the account's outfits",
      build: () {
        when(
          wardrobe.watch('uid-1'),
        ).thenAnswer((_) => Stream.value(Right([_outfit])));
        return build();
      },
      act: (bloc) => bloc.add(const WardrobeStarted()),
      expect: () => [
        WardrobeState(status: WardrobeStatus.ready, outfits: [_outfit]),
      ],
    );

    blocTest<WardrobeBloc, WardrobeState>(
      'says when the outfits cannot be read',
      build: () {
        when(
          wardrobe.watch('uid-1'),
        ).thenAnswer((_) => Stream.value(const Left(NetworkFailure())));
        return build();
      },
      act: (bloc) => bloc.add(const WardrobeStarted()),
      expect: () => const [
        WardrobeState(status: WardrobeStatus.failed, failure: NetworkFailure()),
      ],
    );

    blocTest<WardrobeBloc, WardrobeState>(
      'removes an outfit from the account',
      build: () {
        when(
          wardrobe.remove('uid-1', _outfit),
        ).thenAnswer((_) async => const Right(unit));
        return build();
      },
      seed: () =>
          WardrobeState(status: WardrobeStatus.ready, outfits: [_outfit]),
      act: (bloc) => bloc.add(WardrobeOutfitRemoved(_outfit)),
      verify: (_) => verify(wardrobe.remove('uid-1', _outfit)).called(1),
    );
  });

  group('AddOutfitBloc', () {
    AddOutfitBloc build() => AddOutfitBloc(
      getCurrentAccount: account,
      choosePhoto: choose,
      addToWardrobe: AddToWardrobe(wardrobe),
    );

    blocTest<AddOutfitBloc, AddOutfitState>(
      'chooses the photo from Photos or Gallery',
      build: () {
        when(choose(PhotoRole.body)).thenAnswer(
          (_) async => const Right(
            ChosenPhoto(path: '/cache/look.png', converted: true),
          ),
        );
        return build();
      },
      act: (bloc) => bloc.add(const AddOutfitPhotoRequested()),
      expect: () => const [
        AddOutfitState(choosing: true),
        AddOutfitState(photo: '/cache/look.png', converted: true),
      ],
    );

    blocTest<AddOutfitBloc, AddOutfitState>(
      'can save only with a photo, a name, a colour, some weather and an '
      'occasion',
      build: build,
      seed: () => const AddOutfitState(photo: '/cache/look.jpg'),
      act: (bloc) => bloc
        ..add(const AddOutfitNameChanged('Navy work suit'))
        ..add(const AddOutfitColourChosen(OutfitColour.navy))
        ..add(const AddOutfitBandToggled(WarmthBand.mild))
        ..add(const AddOutfitOccasionToggled(Occasion.work)),
      verify: (bloc) {
        expect(bloc.state.canSave, isTrue);
        expect(bloc.state.details, _details);
      },
    );

    test('a missing detail keeps Save off', () {
      const ready = AddOutfitState(
        photo: '/cache/look.jpg',
        name: 'Navy work suit',
        colour: OutfitColour.navy,
        bands: {WarmthBand.mild},
        occasions: {Occasion.work},
      );
      expect(ready.canSave, isTrue);
      for (final missing in [
        ready.copyWith(photo: () => null),
        ready.copyWith(name: ' '),
        ready.copyWith(colour: () => null),
        ready.copyWith(bands: const {}),
        ready.copyWith(occasions: const {}),
      ]) {
        expect(missing.canSave, isFalse);
      }
    });

    blocTest<AddOutfitBloc, AddOutfitState>(
      'toggles a band, rain and an occasion off again',
      build: build,
      act: (bloc) => bloc
        ..add(const AddOutfitBandToggled(WarmthBand.hot))
        ..add(const AddOutfitBandToggled(WarmthBand.hot))
        ..add(const AddOutfitRainToggled())
        ..add(const AddOutfitOccasionToggled(Occasion.casual))
        ..add(const AddOutfitOccasionToggled(Occasion.casual)),
      verify: (bloc) {
        expect(bloc.state.bands, isEmpty);
        expect(bloc.state.rain, isTrue);
        expect(bloc.state.occasions, isEmpty);
      },
    );

    blocTest<AddOutfitBloc, AddOutfitState>(
      'saves the outfit to the wardrobe',
      build: () {
        when(
          wardrobe.add('uid-1', photo: '/cache/look.jpg', details: _details),
        ).thenAnswer((_) async => Right(_outfit));
        return build();
      },
      seed: () => const AddOutfitState(
        photo: '/cache/look.jpg',
        name: 'Navy work suit',
        colour: OutfitColour.navy,
        bands: {WarmthBand.mild},
        occasions: {Occasion.work},
      ),
      act: (bloc) => bloc.add(const AddOutfitSaved()),
      expect: () => [
        isA<AddOutfitState>().having((state) => state.saving, 'saving', true),
        isA<AddOutfitState>().having((state) => state.saved, 'saved', true),
      ],
    );

    blocTest<AddOutfitBloc, AddOutfitState>(
      'says why it could not save, keeping what was entered',
      build: () {
        when(
          wardrobe.add('uid-1', photo: '/cache/look.jpg', details: _details),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return build();
      },
      seed: () => const AddOutfitState(
        photo: '/cache/look.jpg',
        name: 'Navy work suit',
        colour: OutfitColour.navy,
        bands: {WarmthBand.mild},
        occasions: {Occasion.work},
      ),
      act: (bloc) => bloc.add(const AddOutfitSaved()),
      verify: (bloc) {
        expect(bloc.state.failure, const NetworkFailure());
        expect(bloc.state.saved, isFalse);
        expect(bloc.state.details, _details);
      },
    );
  });
}
