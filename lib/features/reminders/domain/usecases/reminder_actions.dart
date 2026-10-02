import '../../../../core/data/repository.dart';
import '../../../../core/utils/clock.dart';
import '../reminder.dart';

/// Complete · Snooze · Mute · Delete · Create — the reminder detail actions.
class ReminderActions {
  ReminderActions(this._repo, this._clock);

  final Repository<Reminder> _repo;
  final Clock _clock;

  Future<Reminder> create({
    required String title,
    String? propertyId,
    required ReminderType type,
    required DateTime at,
    RepeatRule repeat = RepeatRule.none,
    bool notify = true,
    String notes = '',
    String? editingId,
  }) async {
    final existing = editingId == null ? null : _repo.byId(editingId);
    final r = existing?.copyWith(
          title: title,
          type: type,
          propertyId: propertyId,
          at: at,
          repeat: repeat,
          notify: notify,
          notes: notes,
        ) ??
        Reminder(
          id: newId('r'),
          type: type,
          title: title.trim().isEmpty ? 'Reminder' : title.trim(),
          propertyId: propertyId,
          at: at,
          repeat: repeat,
          notify: notify,
          notes: notes,
        );
    await _repo.upsert(r);
    return r;
  }

  Future<bool> toggleComplete(String id) async {
    final r = _repo.byId(id);
    if (r == null) return false;
    await _repo.upsert(r.copyWith(done: !r.done));
    return !r.done;
  }

  /// Pushes the reminder to later today (18:00) or tomorrow morning.
  Future<void> snooze(String id) async {
    final r = _repo.byId(id);
    if (r == null) return;
    final now = _clock.now();
    final evening = DateTime(now.year, now.month, now.day, 18);
    final next = now.isBefore(evening) ? evening : DateTime(now.year, now.month, now.day + 1, 9);
    final label = r.sourceLabel.replaceAll(' · snoozed', '');
    await _repo.upsert(r.copyWith(at: next, snoozed: true, sourceLabel: '$label · snoozed'));
  }

  Future<void> toggleNotify(String id) async {
    final r = _repo.byId(id);
    if (r != null) await _repo.upsert(r.copyWith(notify: !r.notify));
  }

  Future<void> delete(String id) => _repo.delete(id);
}
