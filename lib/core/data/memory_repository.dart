import 'dart:async';

import 'repository.dart';

/// Reactive in-memory collection keyed by id.
class MemoryRepository<T> implements Repository<T> {
  MemoryRepository(Iterable<T> seed, this._idOf) {
    for (final item in seed) {
      _items[_idOf(item)] = item;
    }
    _list = List.unmodifiable(_items.values);
  }

  final String Function(T) _idOf;
  final Map<String, T> _items = {};
  final _changes = StreamController<List<T>>.broadcast();
  late List<T> _list;

  @override
  Stream<List<T>> watchAll() async* {
    yield _list;
    yield* _changes.stream;
  }

  @override
  List<T> get snapshot => _list;

  @override
  T? byId(String id) => _items[id];

  @override
  Future<void> upsert(T item) async {
    _items[_idOf(item)] = item;
    _emit();
  }

  @override
  Future<void> upsertAll(Iterable<T> items) async {
    for (final item in items) {
      _items[_idOf(item)] = item;
    }
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    if (_items.remove(id) != null) _emit();
  }

  void _emit() {
    _list = List.unmodifiable(_items.values);
    _changes.add(_list);
  }
}
