import '../../../../core/data/repository.dart';
import '../app_notification.dart';

class NotificationActions {
  NotificationActions(this._repo);
  final Repository<AppNotification> _repo;

  Future<void> markRead(String id) async {
    final n = _repo.byId(id);
    if (n != null && n.unread) await _repo.upsert(n.copyWith(unread: false));
  }

  Future<void> markAllRead() =>
      _repo.upsertAll(_repo.snapshot.where((n) => n.unread).map((n) => n.copyWith(unread: false)));
}
