/// Storage contract shared by every feature.
///
/// The in-memory implementation ([MemoryRepository]) powers the app until
/// Firebase is configured; a Firestore implementation plugs into the same
/// interface so no feature code changes.
abstract interface class Repository<T> {
  /// Emits the full collection immediately and on every change.
  Stream<List<T>> watchAll();

  /// Latest known snapshot (synchronous, for use-cases).
  List<T> get snapshot;

  T? byId(String id);

  Future<void> upsert(T item);

  Future<void> upsertAll(Iterable<T> items);

  Future<void> delete(String id);
}
