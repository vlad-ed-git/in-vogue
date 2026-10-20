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

  /// Asks the signed-in person to confirm with their provider again. Throws
  /// [SignInException] or [NetworkException].
  Future<void> reauthenticate();

  /// Deletes the signed-in account, then signs out of Google. Throws
  /// [SignInException] or [NetworkException].
  Future<void> deleteUser();
}

/// Firebase Auth, with credentials from Sign in with Apple and Google Sign-In.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({this._googleClientId});

  /// The iOS OAuth client; Android reads its client from google-services.json.
  final String? _googleClientId;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Google Sign-In is initialized once, before its first use; a failed
  /// start is tried again at the next use.
  Future<void>? _googleStarted;

  Future<void> get _googleReady => _googleStarted ??= GoogleSignIn.instance
      .initialize(clientId: _googleClientId)
      .catchError((Object error, StackTrace stack) {
        _googleStarted = null;
        Error.throwWithStackTrace(error, stack);
      });

  @override
  Future<Account> signIn(SignInMethod method) => _translate(() async {
    final user = switch (method) {
      SignInMethod.apple => await _signInWithApple(),
      SignInMethod.google => await _signInWithGoogle(),
    };
    return _account(user);
  });

  /// Runs [call], translating the providers' errors.
  static Future<T> _translate<T>(Future<T> Function() call) async {
    try {
      return await call();
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

  /// Apple's credential for Firebase, with the name Apple shared.
  Future<({AuthCredential credential, String? name, String? appleCode})>
  _appleCredential() async {
    final rawNonce = _nonce();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.fullName],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final name = [
      apple.givenName,
      apple.familyName,
    ].whereType<String>().join(' ').trim();
    return (
      credential: AppleAuthProvider.credentialWithIDToken(
        apple.identityToken!,
        rawNonce,
        AppleFullPersonName(
          givenName: apple.givenName,
          familyName: apple.familyName,
        ),
      ),
      name: name.isEmpty ? null : name,
      appleCode: apple.authorizationCode,
    );
  }

  /// Google's credential for Firebase.
  Future<({AuthCredential credential, String? name, String? appleCode})>
  _googleCredential() async {
    await _googleReady;
    final google = await GoogleSignIn.instance.authenticate();
    return (
      credential: GoogleAuthProvider.credential(
        idToken: google.authentication.idToken,
      ),
      name: null,
      appleCode: null,
    );
  }

  Future<User> _signInWithApple() async {
    final apple = await _appleCredential();
    final result = await _auth.signInWithCredential(apple.credential);
    final user = result.user!;
    // Apple shares the name only on the first sign-in; keep it on the account.
    final name = apple.name;
    if (name != null && (user.displayName ?? '').trim().isEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
      return _auth.currentUser ?? user;
    }
    return user;
  }

  Future<User> _signInWithGoogle() async {
    final google = await _googleCredential();
    final result = await _auth.signInWithCredential(google.credential);
    return result.user!;
  }

  @override
  Future<void> reauthenticate() => _translate(() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw SignInException(
        SignInProblem.failed,
        StateError('Nobody is signed in'),
        StackTrace.current,
      );
    }
    final credential = switch (_account(user).method) {
      SignInMethod.apple => await _appleCredential(),
      _ => await _googleCredential(),
    };
    await user.reauthenticateWithCredential(credential.credential);
    _appleCode = credential.appleCode;
  });

  /// Apple's authorization code from the last confirmation, to revoke the
  /// person's Apple token when the account is deleted.
  String? _appleCode;

  @override
  Future<void> deleteUser() => _translate(() async {
    final appleCode = _appleCode;
    if (appleCode != null) {
      // Apple asks apps to revoke the person's token with the account.
      await _auth.revokeTokenWithAuthorizationCode(appleCode);
      _appleCode = null;
    }
    await _auth.currentUser?.delete();
    await _googleReady;
    await GoogleSignIn.instance.signOut();
  });

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
    final providers = {for (final info in user.providerData) info.providerId};
    return Account(
      id: user.uid,
      name: name == null || name.isEmpty ? null : name,
      method: providers.contains('apple.com')
          ? SignInMethod.apple
          : providers.contains('google.com')
          ? SignInMethod.google
          : null,
    );
  }

  /// A random nonce; Apple receives its SHA-256 and Firebase checks it.
  static String _nonce() {
    final random = Random.secure();
    return base64Url.encode(List.generate(32, (_) => random.nextInt(256)));
  }
}
