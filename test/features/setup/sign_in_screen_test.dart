import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/setup/presentation/screens/sign_in_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockSignInBloc extends MockBloc<SignInEvent, SignInState>
    implements SignInBloc {}

class _MockPhotoBloc extends MockBloc<PhotoEvent, PhotoState>
    implements PhotoBloc {}

Finder _provider(SignInProvider provider) => find.byWidgetPredicate(
  (widget) => widget is SignInButton && widget.provider == provider,
);

void main() {
  late _MockSignInBloc signIn;
  late _MockPhotoBloc photo;
  late int backs;
  late List<Account> signedIn;

  setUp(() {
    signIn = _MockSignInBloc();
    photo = _MockPhotoBloc();
    backs = 0;
    signedIn = [];
    whenListen(
      photo,
      const Stream<PhotoState>.empty(),
      initialState: const PhotoState(
        status: PhotoStatus.chosen,
        path: '/app/body-1.jpg',
        isKept: true,
      ),
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    SignInState state = const SignInState(),
    Stream<SignInState> states = const Stream.empty(),
    TargetPlatform platform = TargetPlatform.iOS,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(signIn, states, initialState: state);
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<SignInBloc>.value(value: signIn),
          BlocProvider<PhotoBloc>.value(value: photo),
        ],
        child: SignInScreen(onBack: () => backs++, onSignedIn: signedIn.add),
      ),
      platform: platform,
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks to sign in at step 4 of 6, showing what is kept', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('4 / 6'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      find.text(
        'Your photo and picks come with you. '
        'Then we make your first outfit.',
      ),
      findsOneWidget,
    );
    expect(find.byType(PhotoSlot), findsOneWidget);
    expect(find.text('YOUR PHOTO'), findsOneWidget);
    expect(_provider(SignInProvider.apple), findsOneWidget);
    expect(_provider(SignInProvider.google), findsOneWidget);
    expect(find.byType(InVogueTextField), findsNothing);
  });

  testWidgets('signs in with Apple or Google', (tester) async {
    await pumpScreen(tester);
    await tester.tap(_provider(SignInProvider.apple));
    verify(
      () => signIn.add(const SignInRequested(SignInMethod.apple)),
    ).called(1);
    await tester.tap(_provider(SignInProvider.google));
    verify(
      () => signIn.add(const SignInRequested(SignInMethod.google)),
    ).called(1);
  });

  testWidgets('keeps both buttons still while signing in', (tester) async {
    await pumpScreen(
      tester,
      state: const SignInState(status: SignInStatus.signingIn),
    );
    for (final provider in SignInProvider.values) {
      expect(
        tester.widget<SignInButton>(_provider(provider)).onPressed,
        isNull,
      );
    }
  });

  testWidgets('says when sign-in failed', (tester) async {
    await pumpScreen(
      tester,
      state: const SignInState(failure: SignInFailure(SignInProblem.failed)),
    );
    expect(
      find.text('We couldn’t sign you in. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('offers only Google on Android', (tester) async {
    await pumpScreen(tester, platform: TargetPlatform.android);
    expect(_provider(SignInProvider.google), findsOneWidget);
    expect(_provider(SignInProvider.apple), findsNothing);
  });

  testWidgets('moves on once signed in', (tester) async {
    const maya = Account(id: 'uid-1', name: 'Maya');
    await pumpScreen(
      tester,
      states: Stream.value(
        const SignInState(status: SignInStatus.signedIn, account: maya),
      ),
    );
    expect(signedIn, [maya]);
  });

  testWidgets('goes back', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Back'));
    expect(backs, 1);
  });

  testWidgets('fits a small phone at 200% text', (tester) async {
    await pumpScreen(tester, size: const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(_provider(SignInProvider.google), findsOneWidget);
  });
}
