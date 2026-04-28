/// Tipo de retorno padrão da borda Repository → ViewModel.
///
/// Em vez de exceções vazadas, repositories devolvem [Ok] em sucesso
/// ou [Error] em falha. ViewModels fazem `switch` no resultado.
sealed class Result<T> {
  const Result();
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.error(Exception error) = Error<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error(this.error);
  final Exception error;
}
