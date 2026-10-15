import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

abstract interface class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

class NoParams {
  const NoParams();
}
