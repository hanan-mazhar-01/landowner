import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/profile/delete_account_screen.dart';
import '../../features/auth/presentation/profile/profile_settings_screen.dart';
import '../../features/documents/presentation/document_detail_screen.dart';
import '../../features/documents/presentation/document_vault_screen.dart';
import '../../features/finance/domain/ledger_entry.dart';
import '../../features/finance/domain/report_builder.dart';
import '../../features/finance/presentation/cash_flow_screen.dart';
import '../../features/finance/presentation/ledger_list_screen.dart';
import '../../features/finance/presentation/payments/payment_detail_screen.dart';
import '../../features/finance/presentation/payments/payments_screen.dart';
import '../../features/finance/presentation/reports/report_detail_screen.dart';
import '../../features/finance/presentation/reports/reports_screen.dart';
import '../../features/maintenance/presentation/maintenance_detail_screen.dart';
import '../../features/maintenance/presentation/maintenance_list_screen.dart';
import '../../features/reminders/presentation/calendar_screen.dart';
import '../../features/tenants/presentation/tenant_detail_screen.dart';
import '../../features/tenants/presentation/tenant_list_screen.dart';
import '../../shared/forms/profile_form_route.dart';

typedef PageFn = GoRoute Function(String, Widget Function(GoRouterState));

/// Operations, finance sections and account routes.
List<RouteBase> opsRoutes(PageFn page) => [
      page('/tenants', (_) => const TenantListScreen()),
      page('/tenants/:leaseId', (s) => TenantDetailScreen(leaseId: s.pathParameters['leaseId']!)),
      page('/maintenance', (s) => MaintenanceListScreen(propertyId: s.uri.queryParameters['property'])),
      page('/maintenance/:id', (s) => MaintenanceDetailScreen(id: s.pathParameters['id']!)),
      page('/documents', (s) => DocumentVaultScreen(propertyId: s.uri.queryParameters['property'])),
      page('/documents/:id', (s) => DocumentDetailScreen(id: s.pathParameters['id']!)),
      page('/documents/:id/view', (s) => DocumentViewerScreen(id: s.pathParameters['id']!)),
      page('/calendar', (_) => const CalendarScreen()),
      page('/finance/payments', (s) => PaymentsScreen(propertyId: s.uri.queryParameters['property'])),
      page('/finance/payments/:id', (s) => PaymentDetailScreen(id: s.pathParameters['id']!)),
      page('/finance/income', (_) => const LedgerListScreen(kind: EntryKind.income)),
      page('/finance/expenses', (_) => const LedgerListScreen(kind: EntryKind.expense)),
      page('/finance/transactions', (_) => const LedgerListScreen()),
      page('/finance/cash-flow', (_) => const CashFlowScreen()),
      page('/finance/reports', (_) => const ReportsScreen()),
      page('/finance/reports/:type', (s) => ReportDetailScreen(
            type: ReportType.values.firstWhere((t) => t.name == s.pathParameters['type'], orElse: () => ReportType.portfolio),
          )),
      page('/profile', (_) => const ProfileSettingsScreen()),
      page('/profile/edit', (_) => const ProfileFormRoute(kind: ProfileFormKind.edit)),
      page('/profile/password', (_) => const ProfileFormRoute(kind: ProfileFormKind.password)),
      page('/profile/delete', (_) => const DeleteAccountScreen()),
    ];
