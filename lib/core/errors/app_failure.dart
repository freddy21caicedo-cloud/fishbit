/// Clase base inmutable para el manejo de fallos y excepciones en Clean Architecture
abstract class AppFailure {
  final String message;
  final String? code;

  const AppFailure(this.message, [this.code]);

  @override
  String toString() => 'AppFailure($code): $message';
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message, [super.code]);
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, [super.code]);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, [super.code]);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message, [super.code]);
}
