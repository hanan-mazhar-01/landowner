import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable time source so date logic is testable.
class Clock {
  const Clock();
  DateTime now() => DateTime.now();
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

final clockProvider = Provider<Clock>((_) => const Clock());

/// Short unique ids for locally created records.
String newId(String prefix) =>
    '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
