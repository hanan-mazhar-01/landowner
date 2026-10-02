import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/forms/form_spec.dart';
import '../../../../shared/forms/review_cards.dart';
import '../../../../shared/providers/collections.dart';
import '../../../../shared/providers/usecases.dart';
import '../../domain/lease.dart';
import '../../domain/rent_charge.dart';
import '../../domain/usecases/lease_usecases.dart';
import '../../../tenants/domain/tenant.dart';

const _dueOpts = ['1st', '5th', '10th', '15th'];

FormValues leaseInitial({required String propertyId, required DateTime today, required Set<String> timing, int rent = 0}) {
  final start = DateTime(today.year, today.month, today.day);
  return FormValues({
    'prop': propertyId,
    'tenant': '',
    'phone': '',
    'email': '',
    'emerg': '',
    'photo': <String>[],
    'rent': rent == 0 ? '' : Money.digits(rent),
    'deposit': rent == 0 ? '' : Money.digits(rent * 2),
    'start': start,
    'end': Dates.addMonths(start, 12).subtract(const Duration(days: 1)),
    'due': '1st',
    'freq': 'Monthly',
    'pstatus': 'Pending',
    'grace': '3 days',
    'remind': timing,
    'notes': '',
  });
}

Future<FormResult> saveLease(FormValues v, WidgetRef ref) async {
  final offsets = ReminderOffset.values.where((o) => v.set('remind').contains(o.key)).toSet();
  final lease = await ref.read(createLeaseProvider)(LeaseDraft(
    propertyId: v.str('prop'),
    tenantName: v.str('tenant'),
    phone: v.str('phone'),
    email: v.str('email'),
    emergencyContact: v.str('emerg'),
    rent: Money.parse(v.str('rent')),
    deposit: Money.parse(v.str('deposit')),
    start: v.date('start') ?? DateTime.now(),
    end: v.date('end') ?? Dates.addMonths(DateTime.now(), 12),
    dueDay: int.tryParse(v.str('due').replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
    frequency: PaymentFrequency.fromLabel(v.str('freq')),
    firstPayment: switch (v.str('pstatus')) { 'Paid' => RentStatus.paid, 'Overdue' => RentStatus.overdue, _ => RentStatus.pending },
    graceDays: int.tryParse(v.str('grace').split(' ').first) ?? 0,
    offsets: offsets,
    notes: v.str('notes'),
  ));
  // Opened from that property's detail ("Mark as rented"): just pop back to it.
  // Opened from property creation or elsewhere: replace the form with the detail.
  final detail = Routes.property(lease.propertyId);
  return FormResult(
    toast: 'Lease saved · rent reminders scheduled',
    replaceWith: _routeInStack(ref, detail) ? null : detail,
  );
}

/// Whether [location] is already on the navigation stack beneath the form.
bool _routeInStack(WidgetRef ref, String location) {
  bool visit(List<RouteMatchBase> matches) {
    for (final m in matches) {
      if (m.matchedLocation == location) return true;
      if (m is ImperativeRouteMatch && visit(m.matches.matches)) return true;
      if (m is ShellRouteMatch && visit(m.matches)) return true;
    }
    return false;
  }

  try {
    return visit(ref.read(routerProvider).routerDelegate.currentConfiguration.matches);
  } catch (_) {
    return false;
  }
}

StepSpec leaseReview() => StepSpec('Review', review: (v, ref) {
      final p = ref.read(propertyByIdProvider(v.str('prop')));
      final start = v.date('start'), end = v.date('end');
      return LeaseReviewCard(
        header: '${p?.name ?? ''} · ${v.str('tenant')}',
        rent: Money.full(Money.parse(v.str('rent'))),
        start: start == null ? '—' : Dates.dMy(start),
        due: '${v.str('due')} of every month',
        end: end == null ? '—' : Dates.dMy(end),
        rows: [
          ('Property', p?.name ?? ''),
          ('Tenant', v.str('tenant')),
          ('Contact', [v.str('phone'), v.str('email')].where((s) => s.isNotEmpty).join(' · ')),
          ('Monthly rent', Money.full(Money.parse(v.str('rent')))),
          ('Security deposit', Money.full(Money.parse(v.str('deposit')))),
          ('Frequency', v.str('freq')),
          ('First payment', v.str('pstatus')),
          ('Grace period', v.str('grace')),
        ],
      );
    });

/// Add rental / lease — 4 steps.
FormSpec leaseForm(FormValues initial) => FormSpec(
      title: 'Add rental / lease',
      saveLabel: 'Save lease',
      hint: 'Saving creates rent reminders automatically.',
      initial: initial,
      steps: [
        const StepSpec('Who is renting?', fields: [
          FieldSpec('prop', 'Property', FieldKind.property, required: true),
          FieldSpec('tenant', 'Tenant name', FieldKind.text, placeholder: 'Full name', required: true),
          FieldSpec('phone', 'Phone', FieldKind.text, placeholder: 'Phone number', keyboard: TextInputType.phone),
          FieldSpec('email', 'Email', FieldKind.text, placeholder: 'name@example.com', keyboard: TextInputType.emailAddress),
        ]),
        const StepSpec('Lease terms', fields: [
          FieldSpec('rent', 'Monthly rent', FieldKind.money, required: true),
          FieldSpec('deposit', 'Security deposit', FieldKind.money),
          FieldSpec('start', 'Lease start', FieldKind.date),
          FieldSpec('end', 'Lease end', FieldKind.date),
          FieldSpec('due', 'Rent due', FieldKind.seg, options: _dueOpts),
          FieldSpec('freq', 'Payment frequency', FieldKind.seg, options: ['Monthly', 'Quarterly', 'Yearly', 'Custom']),
          FieldSpec('pstatus', 'First payment', FieldKind.seg, options: ['Paid', 'Pending', 'Overdue']),
          FieldSpec('grace', 'Late grace period', FieldKind.seg, options: ['None', '3 days', '5 days', '7 days']),
        ]),
        const StepSpec('Rent reminders', fields: [
          FieldSpec('remind', 'Remind me', FieldKind.remind),
          FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Anything to remember about this lease'),
        ]),
        leaseReview(),
      ],
      onSave: saveLease,
    );

/// Add tenant — tenant details, then the tenancy (creates the lease too).
FormSpec tenantForm(FormValues initial) => FormSpec(
      title: 'Add tenant',
      saveLabel: 'Save lease',
      hint: 'Saving creates rent reminders automatically.',
      initial: initial,
      steps: const [
        StepSpec('Tenant', fields: [
          FieldSpec('photo', 'Photo (optional)', FieldKind.upload),
          FieldSpec('tenant', 'Full name', FieldKind.text, placeholder: 'Full name', required: true),
          FieldSpec('phone', 'Phone', FieldKind.text, placeholder: 'Phone number', keyboard: TextInputType.phone),
          FieldSpec('email', 'Email', FieldKind.text, placeholder: 'name@example.com', keyboard: TextInputType.emailAddress),
          FieldSpec('emerg', 'Emergency contact (optional)', FieldKind.text, placeholder: 'Name · phone'),
        ]),
        StepSpec('Tenancy', fields: [
          FieldSpec('prop', 'Property', FieldKind.property, required: true),
          FieldSpec('rent', 'Monthly rent', FieldKind.money, required: true),
          FieldSpec('deposit', 'Security deposit', FieldKind.money),
          FieldSpec('start', 'Lease start', FieldKind.date),
          FieldSpec('end', 'Lease end', FieldKind.date),
          FieldSpec('due', 'Rent due', FieldKind.seg, options: _dueOpts),
          FieldSpec('remind', 'Remind me', FieldKind.remind),
        ]),
      ],
      onSave: saveLease,
    );

/// Edit lease — the Add lease steps, pre-filled; saving rebuilds only future
/// unpaid rent so payment history is untouched.
FormSpec leaseEditForm(Lease l, Tenant? t) => FormSpec(
      title: 'Edit lease',
      saveLabel: 'Save lease',
      hint: 'Future rent reminders update when you save.',
      initial: FormValues({
        'prop': l.propertyId,
        'tenant': t?.name ?? '',
        'phone': t?.phone ?? '',
        'email': t?.email ?? '',
        'rent': Money.digits(l.monthlyRent),
        'deposit': Money.digits(l.deposit),
        'start': l.start,
        'end': l.end,
        'due': _dueOpts.contains(Dates.ordinal(l.dueDay)) ? Dates.ordinal(l.dueDay) : '1st',
        'freq': l.frequency.label,
        'grace': l.graceDays == 0 ? 'None' : '${l.graceDays} days',
        'remind': {for (final o in l.reminderOffsets) o.key},
        'notes': l.notes,
      }),
      steps: const [
        StepSpec('Who is renting?', fields: [
          FieldSpec('tenant', 'Tenant name', FieldKind.text, required: true),
          FieldSpec('phone', 'Phone', FieldKind.text, keyboard: TextInputType.phone),
          FieldSpec('email', 'Email', FieldKind.text, keyboard: TextInputType.emailAddress),
        ]),
        StepSpec('Lease terms', fields: [
          FieldSpec('rent', 'Monthly rent', FieldKind.money, required: true),
          FieldSpec('deposit', 'Security deposit', FieldKind.money),
          FieldSpec('start', 'Lease start', FieldKind.date),
          FieldSpec('end', 'Lease end', FieldKind.date),
          FieldSpec('due', 'Rent due', FieldKind.seg, options: _dueOpts),
          FieldSpec('freq', 'Payment frequency', FieldKind.seg, options: ['Monthly', 'Quarterly', 'Yearly', 'Custom']),
          FieldSpec('grace', 'Late grace period', FieldKind.seg, options: ['None', '3 days', '5 days', '7 days']),
        ]),
        StepSpec('Rent reminders', fields: [
          FieldSpec('remind', 'Remind me', FieldKind.remind),
          FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Anything to remember about this lease'),
        ]),
      ],
      onSave: (v, WidgetRef ref) async {
        await ref.read(updateLeaseProvider)(
          l.copyWith(
            monthlyRent: Money.parse(v.str('rent')),
            deposit: Money.parse(v.str('deposit')),
            start: v.date('start'),
            end: v.date('end'),
            dueDay: int.tryParse(v.str('due').replaceAll(RegExp(r'[^0-9]'), '')) ?? l.dueDay,
            frequency: PaymentFrequency.fromLabel(v.str('freq')),
            graceDays: int.tryParse(v.str('grace').split(' ').first) ?? 0,
            reminderOffsets: ReminderOffset.values.where((o) => v.set('remind').contains(o.key)).toSet(),
            notes: v.str('notes'),
          ),
          tenant: t?.copyWith(name: v.str('tenant'), phone: v.str('phone'), email: v.str('email')),
        );
        return const FormResult(toast: 'Lease updated · rent schedule refreshed');
      },
    );

/// Edit tenant — the Add tenant "Tenant" step, pre-filled.
FormSpec tenantEditForm(Tenant t) => FormSpec(
      title: 'Edit tenant',
      initial: FormValues({
        'photo': <String>[?t.photoUrl],
        'tenant': t.name,
        'phone': t.phone,
        'email': t.email,
        'emerg': t.emergencyContact,
        'notes': t.notes,
      }),
      steps: const [
        StepSpec('Tenant', fields: [
          FieldSpec('photo', 'Photo (optional)', FieldKind.upload),
          FieldSpec('tenant', 'Full name', FieldKind.text, required: true),
          FieldSpec('phone', 'Phone', FieldKind.text, keyboard: TextInputType.phone),
          FieldSpec('email', 'Email', FieldKind.text, keyboard: TextInputType.emailAddress),
          FieldSpec('emerg', 'Emergency contact (optional)', FieldKind.text, placeholder: 'Name · phone'),
          FieldSpec('notes', 'Notes', FieldKind.note, placeholder: 'Anything to remember'),
        ]),
      ],
      onSave: (v, WidgetRef ref) async {
        await ref.read(recordEditsProvider).saveTenant(t.copyWith(
              name: v.str('tenant'),
              phone: v.str('phone'),
              email: v.str('email'),
              emergencyContact: v.str('emerg'),
              notes: v.str('notes'),
              photoUrl: v.files('photo').firstOrNull,
            ));
        return const FormResult(toast: 'Tenant updated');
      },
    );
