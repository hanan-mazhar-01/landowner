import '../../../features/documents/domain/document_item.dart';
import '../../../features/finance/domain/ledger_entry.dart';
import '../../../features/leases/domain/lease.dart';
import '../../../features/leases/domain/rent_charge.dart';
import '../../../features/maintenance/domain/maintenance_ticket.dart';
import '../../../features/notifications/domain/app_notification.dart';
import '../../../features/properties/domain/property.dart';
import '../../../features/tenants/domain/tenant.dart';
import 'seed_ledger.dart';
import 'seed_ops.dart';
import 'seed_portfolio.dart';

/// The design's demo portfolio, with every date expressed relative to [now].
class DemoSeed {
  DemoSeed._({
    required this.properties,
    required this.tenants,
    required this.leases,
    required this.charges,
    required this.ledger,
    required this.maintenance,
    required this.documents,
    required this.notifications,
  });

  factory DemoSeed.build(DateTime now) {
    final props = seedProperties(now);
    final leases = seedLeases(now);
    final charges = seedCharges(leases, now);
    return DemoSeed._(
      properties: props,
      tenants: seedTenants(now),
      leases: leases,
      charges: charges,
      ledger: [...seedIncome(charges), ...seedExpenses(props, now)],
      maintenance: seedMaintenance(now),
      documents: seedDocuments(leases, now),
      notifications: seedNotifications(now),
    );
  }

  final List<Property> properties;
  final List<Tenant> tenants;
  final List<Lease> leases;
  final List<RentCharge> charges;
  final List<LedgerEntry> ledger;
  final List<MaintenanceTicket> maintenance;
  final List<DocumentItem> documents;
  final List<AppNotification> notifications;
}
