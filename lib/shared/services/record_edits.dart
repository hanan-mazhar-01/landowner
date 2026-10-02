import '../../core/data/repository.dart';
import '../../core/services/cloudinary_service.dart';
import '../../features/documents/domain/document_item.dart';
import '../../features/finance/domain/ledger_entry.dart';
import '../../features/maintenance/domain/maintenance_ticket.dart';
import '../../features/tenants/domain/tenant.dart';

/// Generic save/delete for records whose edits have no side-effects beyond
/// their own collection (the reminder engine re-derives automatically).
class RecordEdits {
  RecordEdits(this._tenants, this._ledger, this._maintenance, this._documents, [this._cloudinary]);

  final Repository<Tenant> _tenants;
  final Repository<LedgerEntry> _ledger;
  final Repository<MaintenanceTicket> _maintenance;
  final Repository<DocumentItem> _documents;
  final CloudinaryService? _cloudinary;

  Future<void> saveTenant(Tenant t) async {
    var tenant = t;
    if (_cloudinary != null && t.photoUrl != null && t.photoUrl!.isNotEmpty) {
      final url = await _cloudinary.uploadMediaIfLocal(t.photoUrl!, CloudinaryFolder.avatars);
      tenant = t.copyWith(photoUrl: url);
    }
    await _tenants.upsert(tenant);
  }

  Future<void> saveEntry(LedgerEntry e) async {
    var entry = e;
    if (_cloudinary != null && e.receiptUrl != null && e.receiptUrl!.isNotEmpty) {
      final url = await _cloudinary.uploadMediaIfLocal(e.receiptUrl!, CloudinaryFolder.receipts);
      entry = e.copyWith(receiptUrl: url);
    }
    await _ledger.upsert(entry);
  }

  Future<void> deleteEntry(String id) => _ledger.delete(id);

  Future<void> saveDocument(DocumentItem d) async {
    var doc = d;
    if (_cloudinary != null && d.fileUrl != null && d.fileUrl!.isNotEmpty) {
      final url = await _cloudinary.uploadMediaIfLocal(d.fileUrl!, CloudinaryFolder.documents);
      doc = d.copyWith(fileUrl: url);
    }
    await _documents.upsert(doc);
  }

  Future<void> deleteDocument(String id) => _documents.delete(id);

  /// Maintenance edits keep the linked expense (sourceRef = ticket id) in step
  /// with the actual cost.
  Future<void> saveMaintenance(MaintenanceTicket t) async {
    var ticket = t;
    if (_cloudinary != null) {
      var photos = t.photoUrls;
      var receipt = t.receiptUrl;
      if (photos.isNotEmpty) {
        photos = await _cloudinary.uploadMultipleIfLocal(photos, CloudinaryFolder.tickets);
      }
      if (receipt != null && receipt.isNotEmpty) {
        receipt = await _cloudinary.uploadMediaIfLocal(receipt, CloudinaryFolder.receipts);
      }
      ticket = t.copyWith(photoUrls: photos, receiptUrl: receipt);
    }
    await _maintenance.upsert(ticket);
    final linked = _ledger.snapshot.where((e) => e.sourceRef == ticket.id && !e.isIncome).toList();
    if (ticket.actualCost != null && linked.length == 1 && linked.first.amount != ticket.actualCost) {
      await _ledger.upsert(linked.first.copyWith(amount: ticket.actualCost));
    }
  }

  /// Deleting a ticket keeps its expense history — money already spent.
  Future<void> deleteMaintenance(String id) => _maintenance.delete(id);
}
