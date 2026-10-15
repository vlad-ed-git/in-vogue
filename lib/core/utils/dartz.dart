import 'package:dartz/dartz.dart';

/// Only unwrap after checking the corresponding branch.
extension EitherX<L, R> on Either<L, R> {
  R asSuccess() => (this as Right<L, R>).value;
  L asFailure() => (this as Left<L, R>).value;
  bool get isError => isLeft();
  bool get isSuccess => isRight();
}
