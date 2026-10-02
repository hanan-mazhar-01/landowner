import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'repository.dart';

/// Cloud Firestore implementation of [Repository].
///
/// Subscribes to collection snapshots for real-time sync with local cache
/// persistence, while maintaining the same synchronous snapshot interface.
class FirestoreRepository<T> implements Repository<T> {
  FirestoreRepository({
    required this.collection,
    required this.fromMap,
    required this.toMap,
    required this.idOf,
  }) {
    _subscription = collection.snapshots().listen(
      _onSnapshot,
      onError: (e) {
        // Log stream error gracefully, preserving current snapshot
      },
    );
  }

  final CollectionReference<Map<String, dynamic>> collection;
  final T Function(Map<String, dynamic> map, String id) fromMap;
  final Map<String, dynamic> Function(T item) toMap;
  final String Function(T item) idOf;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final Map<String, T> _items = {};
  List<T> _list = const [];
  bool _loaded = false;
  final _changes = StreamController<List<T>>.broadcast();

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> query) {
    _items.clear();
    for (final doc in query.docs) {
      try {
        final data = doc.data();
        final item = fromMap(data, doc.id);
        _items[doc.id] = item;
      } catch (_) {
        // Skip malformed items gracefully
      }
    }
    _list = List.unmodifiable(_items.values);
    _loaded = true;
    _emit();
  }

  @override
  Stream<List<T>> watchAll() async* {
    // Replay the last snapshot — including an empty one — so late listeners
    // never wait forever on a collection that has no documents.
    if (_loaded || _list.isNotEmpty) yield _list;
    yield* _changes.stream;
  }

  @override
  List<T> get snapshot => _list;

  @override
  T? byId(String id) => _items[id];

  @override
  Future<void> upsert(T item) async {
    final id = idOf(item);
    _items[id] = item;
    _list = List.unmodifiable(_items.values);
    _emit();

    final data = toMap(item);
    await collection.doc(id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> upsertAll(Iterable<T> items) async {
    if (items.isEmpty) return;
    for (final item in items) {
      _items[idOf(item)] = item;
    }
    _list = List.unmodifiable(_items.values);
    _emit();

    // Commit in Firestore batches (max 500 ops per batch)
    final chunks = <List<T>>[];
    var currentChunk = <T>[];
    for (final item in items) {
      currentChunk.add(item);
      if (currentChunk.length == 450) {
        chunks.add(currentChunk);
        currentChunk = <T>[];
      }
    }
    if (currentChunk.isNotEmpty) chunks.add(currentChunk);

    final firestore = collection.firestore;
    for (final chunk in chunks) {
      final batch = firestore.batch();
      for (final item in chunk) {
        final docRef = collection.doc(idOf(item));
        batch.set(docRef, toMap(item), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  @override
  Future<void> delete(String id) async {
    if (_items.remove(id) != null) {
      _list = List.unmodifiable(_items.values);
      _emit();
    }
    await collection.doc(id).delete();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(_list);
  }

  void dispose() {
    _subscription?.cancel();
    _changes.close();
  }
}
