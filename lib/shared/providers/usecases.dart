import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/cloudinary_service.dart';
import '../../core/utils/clock.dart';
import '../../features/documents/domain/usecases/add_document.dart';
import '../../features/finance/domain/usecases/record_entry.dart';
import '../../features/leases/domain/usecases/lease_usecases.dart';
import '../../features/leases/domain/usecases/payment_usecases.dart';
import '../../features/maintenance/domain/usecases/log_maintenance.dart';
import '../../features/properties/domain/usecases/add_property.dart';
import '../../features/reminders/domain/usecases/reminder_actions.dart';
import '../services/record_edits.dart';
import 'repositories.dart';

// Use-case bindings. Screens call these via `ref.read(...)` — never watch.

final savePropertyProvider = Provider((ref) => SaveProperty(
      ref.read(propertyRepoProvider),
      ref.read(notificationRepoProvider),
      ref.read(clockProvider),
      ref.read(cloudinaryServiceProvider),
    ));

final createLeaseProvider = Provider((ref) => CreateLease(
      ref.read(propertyRepoProvider),
      ref.read(tenantRepoProvider),
      ref.read(leaseRepoProvider),
      ref.read(chargeRepoProvider),
      ref.read(ledgerRepoProvider),
      ref.read(notificationRepoProvider),
      ref.read(clockProvider),
    ));

final recordRentPaymentProvider = Provider((ref) => RecordRentPayment(
      ref.read(chargeRepoProvider),
      ref.read(ledgerRepoProvider),
      ref.read(propertyRepoProvider),
      ref.read(notificationRepoProvider),
      ref.read(clockProvider),
    ));

final recordEntryProvider = Provider((ref) => RecordEntry(
      ref.read(ledgerRepoProvider),
      ref.read(propertyRepoProvider),
      ref.read(notificationRepoProvider),
      ref.read(clockProvider),
      ref.read(cloudinaryServiceProvider),
    ));

final logMaintenanceProvider = Provider((ref) => LogMaintenance(
      ref.read(maintenanceRepoProvider),
      ref.read(recordEntryProvider),
      ref.read(clockProvider),
      ref.read(cloudinaryServiceProvider),
    ));

final addDocumentProvider = Provider((ref) => AddDocument(
      ref.read(documentRepoProvider),
      ref.read(propertyRepoProvider),
      ref.read(notificationRepoProvider),
      ref.read(clockProvider),
      ref.read(cloudinaryServiceProvider),
    ));

final reminderActionsProvider = Provider((ref) => ReminderActions(
      ref.read(reminderRepoProvider),
      ref.read(clockProvider),
    ));

final updateMaintenanceStatusProvider = Provider((ref) => UpdateMaintenanceStatus(
      ref.read(maintenanceRepoProvider),
      ref.read(recordEntryProvider),
      ref.read(clockProvider),
    ));

final paymentActionsProvider = Provider((ref) => PaymentActions(ref.read(chargeRepoProvider), ref.read(ledgerRepoProvider)));

final updateLeaseProvider = Provider((ref) => UpdateLease(
      ref.read(leaseRepoProvider),
      ref.read(tenantRepoProvider),
      ref.read(chargeRepoProvider),
      ref.read(clockProvider),
    ));

final recordEditsProvider = Provider((ref) => RecordEdits(
      ref.read(tenantRepoProvider),
      ref.read(ledgerRepoProvider),
      ref.read(maintenanceRepoProvider),
      ref.read(documentRepoProvider),
      ref.read(cloudinaryServiceProvider),
    ));
