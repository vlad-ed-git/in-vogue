import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Infrastructure error, translated to a [SignInFailure] at the repository.
class SignInException implements Exception {
  const SignInException(this.problem, this.cause, this.stackTrace);

  final SignInProblem problem;
  final Object cause;
  final StackTrace stackTrace;
}

abstract interface class AuthRemoteDataSource {
  /// Throws [SignInException] or [NetworkException].
  Future<Account> signIn(SignInMethod method);

  /// The signed-in account; null when nobody is signed in.
  Account? currentAccount();

  /// Signs out of Firebase, then of Google so it asks for an account again.
  Future<void> signOut();
}

/// Firebase Auth, with credentials from Sign in with Apple and Google Sign-In.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({this._googleClientId});

  /// The iOS OAuth client; Android reads its client from google-services.json.
  final String? _googleClientId;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Google Sign-In is initialized once, before its first use.
  late final Future<void> _googleReady = GoogleSignIn.instance.initialize(
    clientId: _googleClientId,
  );

  @override
  Future<Account> signIn(SignInMethod method) async {
    try {
      final user = switch (method) {
        SignInMethod.apple => await _signInWithApple(),
        SignInMethod.google => await _signInWithGoogle(),
      };
      return _account(user);
    } on SignInWithAppleAuthorizationException catch (error, stack) {
      throw SignInException(
        error.code == AuthorizationErrorCode.canceled
            ? SignInProblem.cancelled
            : SignInProblem.failed,
        error,
        stack,
      );
    } on GoogleSignInException catch (error, stack) {
      throw SignInException(
        error.code == GoogleSignInExceptionCode.canceled
            ? SignInProblem.cancelled
            : SignInProblem.failed,
        error,
        stack,
      );
    } on FirebaseAuthException catch (error, stack) {
      if (error.code == 'network-request-failed') {
        throw NetworkException(error, stack);
      }
      throw SignInException(SignInProblem.failed, error, stack);
    }
  }

  Future<User> _signInWithApple() async {
    final rawNonce = _nonce();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.fullName],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final result = await _auth.signInWithCredential(
      AppleAuthProvider.credentialWithIDToken(
        apple.identityToken!,
        rawNonce,
        AppleFullPersonName(
          givenName: apple.givenName,
          familyName: apple.familyName,
        ),
      ),
    );
    final user = result.user!;
    // Apple shares the name only on the first sign-in; keep it on the account.
    final name = [
      apple.givenName,
      apple.familyName,
    ].whereType<String>().join(' ').trim();
    if (name.isNotEmpty && (user.displayName ?? '').trim().isEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
      return _auth.currentUser ?? user;
    }
    return user;
  }

  Future<User> _signInWithGoogle() async {
    await _googleReady;
    final google = await GoogleSignIn.instance.authenticate();
    final result = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: google.authentication.idToken),
    );
    return result.user!;
  }

  @override
  Account? currentAccount() {
    final user = _auth.currentUser;
    return user == null ? null : _account(user);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleReady;
    await GoogleSignIn.instance.signOut();
  }

  static Account _account(User user) {
    final name = user.displayName?.trim();
    return Account(
      id: user.uid,
      name: name == null || name.isEmpty ? null : name,
    );
  }

  /// A random nonce; Apple receives its SHA-256 and Firebase checks it.
  static String _nonce() {
    final random = Random.secure();
    return base64Url.encode(List.generate(32, (_) => random.nextInt(256)));
  }
}
