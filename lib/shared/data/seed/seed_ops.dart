import '../../../core/utils/formatters.dart';
import '../../../features/auth/domain/app_user.dart';
import '../../../features/documents/domain/document_item.dart';
import '../../../features/leases/domain/lease.dart';
import '../../../features/maintenance/domain/maintenance_ticket.dart';
import '../../../features/notifications/domain/app_notification.dart';
import 'seed_portfolio.dart';

const seedUser = AppUser(
  uid: 'demo',
  name: 'John Malik',
  email: 'john.malik@mail.com',
  city: 'Lahore',
  avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=200&auto=format&fit=crop',
);

List<MaintenanceTicket> seedMaintenance(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime d(int offset) => today.add(Duration(days: offset));
  MaintenanceTicket m(String id, String prop, String title, MaintenanceCategory c, MaintenancePriority p,
          int at, int est, MaintenanceStatus s, {int? actual, int created = -3}) =>
      MaintenanceTicket(
        id: id,
        propertyId: prop,
        title: title,
        category: c,
        priority: p,
        scheduledFor: d(at),
        estimatedCost: est,
        actualCost: actual,
        status: s,
        createdAt: d(created),
      );
  const open = MaintenanceStatus.open, done = MaintenanceStatus.completed;
  return [
    m('m1', 'p1', 'Pool pump service', MaintenanceCategory.appliance, MaintenancePriority.medium, 5, 12000, open),
    m('m2', 'p1', 'Garden irrigation repair', MaintenanceCategory.plumbing, MaintenancePriority.low, -12, 8500, done,
        actual: 8500, created: -16),
    m('m3', 'p2', 'Lift annual inspection', MaintenanceCategory.structural, MaintenancePriority.medium, -4, 18000,
        MaintenanceStatus.inProgress, created: -4),
    m('m4', 'p2', 'Unit 2 water heater', MaintenanceCategory.appliance, MaintenancePriority.high, -28, 14000, done,
        actual: 14000, created: -30),
    m('m5', 'p3', 'HVAC compressor service', MaintenanceCategory.hvac, MaintenancePriority.high, 1, 52000, open,
        created: -3),
    m('m6', 'p3', 'Lobby lighting', MaintenanceCategory.electrical, MaintenancePriority.low, -19, 9000, done,
        actual: 9000, created: -22),
    m('m7', 'p4', 'Repaint before listing', MaintenanceCategory.other, MaintenancePriority.medium, 7, 35000, open,
        created: -5),
    m('m8', 'p4', 'Deep clean', MaintenanceCategory.cleaning, MaintenancePriority.low, -10, 6000, done,
        actual: 6000, created: -12),
  ];
}

List<DocumentItem> seedDocuments(List<Lease> leases, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final out = <DocumentItem>[];
  const props = ['p1', 'p2', 'p3', 'p4'];
  final insuranceIn = {'p1': 150, 'p2': 14, 'p3': 210, 'p4': 95};
  for (final p in props) {
    final lease = leases.where((l) => l.propertyId == p && l.end.isAfter(today)).toList()
      ..sort((a, b) => a.end.compareTo(b.end));
    if (lease.isNotEmpty) {
      out.add(DocumentItem(
          id: 'd_${p}_lease', propertyId: p, type: DocumentType.lease, name: 'Lease agreement',
          date: lease.first.start, expiry: lease.first.end));
    }
    out.add(DocumentItem(
        id: 'd_${p}_deed', propertyId: p, type: DocumentType.ownership, name: 'Ownership deed',
        date: DateTime(2021), verified: true));
    out.add(DocumentItem(
        id: 'd_${p}_ins', propertyId: p, type: DocumentType.insurance, name: 'Insurance policy',
        date: today.subtract(Duration(days: 365 - insuranceIn[p]!)),
        expiry: today.add(Duration(days: insuranceIn[p]!))));
    out.add(DocumentItem(
        id: 'd_${p}_tax', propertyId: p, type: DocumentType.tax, name: 'Tax receipts',
        date: DateTime(today.year), fileCount: 6));
  }
  return out;
}

/// Historic notifications that aren't derived from current state.
List<AppNotification> seedNotifications(DateTime now) => [
      AppNotification(
        id: 'n_exp_elec',
        category: NotificationCategory.finance,
        title: 'Expense added',
        body: '${Money.full(31000)} · Electricity · LuxeApart',
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
        unread: false,
        target: '/finance',
        propertyId: 'p2',
      ),
      AppNotification(
        id: 'n_welcome',
        category: NotificationCategory.property,
        title: 'Portfolio synced',
        body: '4 properties · ${Money.m(124800000)}',
        createdAt: now.subtract(const Duration(days: 6)),
        unread: false,
        target: '/properties',
      ),
    ];

/// Default avatar used when a tenant has no photo.
final defaultTenantPhoto = unsplash('photo-1506794778202-cad84cf45f1d', w: 200);
