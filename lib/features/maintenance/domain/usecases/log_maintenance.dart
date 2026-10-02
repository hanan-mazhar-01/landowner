import '../../../../core/data/repository.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/clock.dart';
import '../../../finance/domain/ledger_entry.dart';
import '../../../finance/domain/usecases/record_entry.dart';
import '../maintenance_ticket.dart';

/// Property → Maintenance → Cost → Expense → Analytics.
/// A reminder is derived automatically by the reminder engine when
/// [MaintenanceTicket.remindBefore] is on.
class LogMaintenance {
  LogMaintenance(this._tickets, this._record, this._clock, [this._cloudinary]);

  final Repository<MaintenanceTicket> _tickets;
  final RecordEntry _record;
  final Clock _clock;
  final CloudinaryService? _cloudinary;

  Future<MaintenanceTicket> call({
    required String propertyId,
    required String title,
    String description = '',
    required MaintenanceCategory category,
    required MaintenancePriority priority,
    required DateTime scheduledFor,
    required int estimatedCost,
    int? actualCost,
    required MaintenanceStatus status,
    bool remindBefore = true,
    String notes = '',
    List<String> photoUrls = const [],
    String? receiptUrl,
  }) async {
    var uploadedPhotos = photoUrls;
    var uploadedReceipt = receiptUrl;
    if (_cloudinary != null) {
      if (uploadedPhotos.isNotEmpty) {
        uploadedPhotos = await _cloudinary.uploadMultipleIfLocal(uploadedPhotos, CloudinaryFolder.tickets);
      }
      if (uploadedReceipt != null && uploadedReceipt.isNotEmpty) {
        uploadedReceipt = await _cloudinary.uploadMediaIfLocal(uploadedReceipt, CloudinaryFolder.receipts);
      }
    }

    final t = MaintenanceTicket(
      id: newId('m'),
      propertyId: propertyId,
      title: title.trim().isEmpty ? 'Maintenance' : title.trim(),
      description: description,
      category: category,
      priority: priority,
      scheduledFor: scheduledFor,
      estimatedCost: estimatedCost,
      actualCost: actualCost,
      status: status,
      remindBefore: remindBefore,
      notes: notes,
      photoUrls: uploadedPhotos,
      receiptUrl: uploadedReceipt,
      createdAt: _clock.now(),
    );
    await _tickets.upsert(t);
    if ((actualCost ?? 0) > 0) {
      await _record(
        kind: EntryKind.expense,
        propertyId: propertyId,
        amount: actualCost!,
        date: _clock.now(),
        category: ExpenseCategory.maintenance,
        title: t.title,
        sourceRef: t.id,
      );
    }
    return t;
  }
}

/// Moves a ticket through Open → In progress → Completed. Completing books
/// the actual (or estimated) cost as a maintenance expense, once.
class UpdateMaintenanceStatus {
  UpdateMaintenanceStatus(this._tickets, this._record, this._clock);

  final Repository<MaintenanceTicket> _tickets;
  final RecordEntry _record;
  final Clock _clock;

  Future<void> call(String id, MaintenanceStatus status, {int? actualCost}) async {
    final t = _tickets.byId(id);
    if (t == null || t.status == status) return;
    final cost = actualCost ?? t.actualCost ?? t.estimatedCost;
    await _tickets.upsert(t.copyWith(status: status, actualCost: status == MaintenanceStatus.completed ? cost : null));
    if (status == MaintenanceStatus.completed && t.actualCost == null && cost > 0) {
      await _record(
        kind: EntryKind.expense,
        propertyId: t.propertyId,
        amount: cost,
        date: _clock.now(),
        category: ExpenseCategory.maintenance,
        title: t.title,
        sourceRef: t.id,
      );
    }
  }
}
