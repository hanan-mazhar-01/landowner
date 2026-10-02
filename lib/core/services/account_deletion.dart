/// Set while an account is being deleted. Background writers (reminder /
/// alert sync, push-token registration) stop immediately so they can't
/// recreate records the server is removing.
abstract final class AccountDeletion {
  static bool inProgress = false;
}
