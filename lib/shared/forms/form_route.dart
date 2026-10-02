import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';

import '../../core/utils/clock.dart';
import '../../features/documents/presentation/forms/document_form.dart';
import '../../features/finance/presentation/forms/entry_forms.dart';
import '../../features/leases/presentation/forms/lease_form.dart';
import '../../features/maintenance/presentation/forms/maintenance_form.dart';
import '../../features/notifications/data/notification_settings_provider.dart';
import '../../features/properties/presentation/forms/property_form.dart';
import '../../features/reminders/presentation/forms/reminder_form.dart';
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../core/data/repository.dart';
import '../../features/finance/presentation/forms/payment_form.dart';
import '../providers/collections.dart';
import '../providers/repositories.dart';
import '../providers/portfolio.dart';
import 'form_screen.dart';
import 'form_spec.dart';

/// `/add/:form` — resolves the form spec once, then hosts it.
class FormRoute extends ConsumerStatefulWidget {
  const FormRoute({super.key, required this.form, this.propertyId, this.editId});
  final String form;
  final String? propertyId;
  final String? editId;

  @override
  ConsumerState<FormRoute> createState() => _FormRouteState();
}

class _FormRouteState extends ConsumerState<FormRoute> {
  late final _spec = _build();

  FormSpec _build() {
    final today = ref.read(clockProvider).today();
    final props = ref.read(propertiesProvider).value ?? const [];
    final pid = widget.propertyId ?? (props.isEmpty ? '' : props.first.id);
    final edit = widget.editId;
    T? find<T>(Repository<T> repo) => edit == null ? null : repo.byId(edit);

    switch (widget.form) {
      case 'lease':
        final l = find(ref.read(leaseRepoProvider));
        if (l != null) return leaseEditForm(l, ref.read(tenantRepoProvider).byId(l.tenantId));
        return leaseForm(_leaseInitial(pid, today));
      case 'tenant':
        final t = find(ref.read(tenantRepoProvider));
        if (t != null) return tenantEditForm(t);
        return tenantForm(_leaseInitial(pid, today));
      case 'income':
        return incomeForm(propertyId: pid, today: today, editing: find(ref.read(ledgerRepoProvider)));
      case 'expense':
        return expenseForm(propertyId: pid, today: today, editing: find(ref.read(ledgerRepoProvider)));
      case 'maintenance':
        return maintenanceForm(propertyId: pid, today: today, editing: find(ref.read(maintenanceRepoProvider)));
      case 'document':
        return documentForm(propertyId: pid, today: today, editing: find(ref.read(documentRepoProvider)));
      case 'payment':
        final c = find(ref.read(chargeRepoProvider));
        if (c != null) return paymentForm(c);
        return incomeForm(propertyId: pid, today: today);
      case 'reminder':
        final editing = edit == null ? null : ref.read(reminderByIdProvider(edit));
        return reminderForm(propertyId: pid, today: today, editing: editing);
      default:
        // Profile city is stored as "City, Country".
        final city = ref.read(currentUserProvider)?.city ?? '';
        return propertyForm(
          editing: find(ref.read(propertyRepoProvider)),
          defaultCountry: city.contains(',') ? city.split(',').last.trim() : '',
        );
    }
  }

  FormValues _leaseInitial(String pid, DateTime today) {
    final m = pid.isEmpty ? null : ref.read(metricsForProvider(pid));
    return leaseInitial(
      propertyId: pid,
      today: today,
      timing: ref.read(notificationSettingsProvider).defaultTiming,
      rent: m?.lastRent ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) => FormScreen(spec: _spec);
}
