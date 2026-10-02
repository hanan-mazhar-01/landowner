import '../../../../core/data/repository.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../notifications/domain/app_notification.dart';
import '../../../properties/domain/property.dart';
import '../ledger_entry.dart';

/// Manual income / expense. Analytics, property financials and cash flow are
/// all derived from the ledger, so they update the moment this is saved.
class RecordEntry {
  RecordEntry(this._ledger, this._props, this._notifs, this._clock, [this._cloudinary]);

  final Repository<LedgerEntry> _ledger;
  final Repository<Property> _props;
  final Repository<AppNotification> _notifs;
  final Clock _clock;
  final CloudinaryService? _cloudinary;

  Future<LedgerEntry> call({
    required EntryKind kind,
    required String propertyId,
    required int amount,
    required DateTime date,
    IncomeType? incomeType,
    ExpenseCategory? category,
    PaymentMethod method = PaymentMethod.bank,
    Recurrence recurrence = Recurrence.once,
    String notes = '',
    String? title,
    String? sourceRef,
    String? receiptUrl,
    bool notify = true,
  }) async {
    final now = _clock.now();
    var finalReceipt = receiptUrl;
    if (_cloudinary != null && finalReceipt != null && finalReceipt.isNotEmpty) {
      finalReceipt = await _cloudinary.uploadMediaIfLocal(finalReceipt, CloudinaryFolder.receipts);
    }
    final label = kind == EntryKind.income ? (incomeType ?? IncomeType.other).label : (category ?? ExpenseCategory.other).label;
    final e = LedgerEntry(
      id: newId('e'),
      kind: kind,
      propertyId: propertyId,
      title: title ?? label,
      amount: amount,
      date: date,
      incomeType: incomeType,
      expenseCategory: category,
      method: method,
      recurrence: recurrence,
      notes: notes,
      receiptUrl: finalReceipt,
      sourceRef: sourceRef,
    );
    await _ledger.upsert(e);
    if (notify) {
      await _notifs.upsert(AppNotification(
        id: newId('n'),
        category: NotificationCategory.finance,
        title: kind == EntryKind.income ? 'Income recorded' : 'Expense added',
        body: '${Money.full(amount)} · $label · ${_props.byId(propertyId)?.name ?? ''}',
        createdAt: now,
        unread: false,
        target: '/finance',
        propertyId: propertyId,
      ));
    }
    return e;
  }
}
