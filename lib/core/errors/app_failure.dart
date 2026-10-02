/// An error whose message is safe and useful to show the user.
class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
