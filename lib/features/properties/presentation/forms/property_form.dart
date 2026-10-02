import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/forms/form_spec.dart';
import '../../../../shared/forms/review_cards.dart';
import '../../../../shared/providers/usecases.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/property.dart';
import '../../domain/usecases/add_property.dart';

/// Country part of the signed-in user's "City, Country" location, if set.
String _userCountry(WidgetRef ref) {
  final city = ref.read(currentUserProvider)?.city ?? '';
  final i = city.lastIndexOf(',');
  return i < 0 ? '' : city.substring(i + 1).trim();
}

/// Add / edit property — 6 steps, exactly as the design sequences them.
///
/// [defaultCountry] pre-fills a new property's country (e.g. from the user's
/// location); when left empty the user's country is applied on save.
FormSpec propertyForm({Property? editing, String defaultCountry = ''}) {
  final e = editing;
  final initial = FormValues({
    'type': e?.type.label ?? 'House',
    'name': e?.name ?? '',
    'status': e?.status.label ?? 'Rented',
    'address': e?.address ?? '',
    'city': e?.city ?? '',
    'country': e?.country ?? defaultCountry,
    'postal': e?.postalCode ?? '',
    'beds': e?.bedrooms == null ? '3' : (e!.bedrooms! >= 5 ? '5+' : '${e.bedrooms}'),
    'baths': e?.bathrooms == null ? '2' : (e!.bathrooms! >= 4 ? '4+' : '${e.bathrooms}'),
    'area': e?.areaSqft == null ? '' : Money.digits(e!.areaSqft!),
    'year': e?.yearBuilt?.toString() ?? '',
    'furn': (e?.furnished ?? false) ? 'Furnished' : 'Unfurnished',
    'purchase': e == null ? '' : Money.digits(e.purchasePrice),
    'value': e == null ? '' : Money.digits(e.currentValue),
    'loan': e == null || e.mortgage == 0 ? '' : Money.digits(e.mortgage),
    'exp': e == null ? '' : Money.digits(e.monthlyExpenses),
    'photos': <String>[],
    'notes': e?.notes ?? '',
  });

  return FormSpec(
    title: e == null ? 'Add property' : 'Edit property',
    saveLabel: 'Save property',
    initial: initial,
    steps: [
      const StepSpec('What are you adding?', fields: [
        FieldSpec('type', 'Property type', FieldKind.seg, options: ['House', 'Apartment', 'Commercial', 'Land', 'Other']),
        FieldSpec('name', 'Property name', FieldKind.text, placeholder: 'e.g. Oak Apartment', required: true),
        FieldSpec('status', 'Current status', FieldKind.seg,
            options: ['Owner occupied', 'Rented', 'Vacant', 'Under maintenance']),
      ]),
      const StepSpec('Where is it?', fields: [
        FieldSpec('address', 'Address', FieldKind.text, placeholder: 'e.g. 12 Park Lane'),
        FieldSpec('city', 'City', FieldKind.text, placeholder: 'e.g. Lahore'),
        FieldSpec('country', 'Country', FieldKind.text, placeholder: 'Country'),
        FieldSpec('postal', 'Postal code', FieldKind.text, placeholder: 'Postal code', keyboard: TextInputType.number),
      ]),
      const StepSpec('Tell us about the space', fields: [
        FieldSpec('beds', 'Bedrooms', FieldKind.seg, options: ['1', '2', '3', '4', '5+']),
        FieldSpec('baths', 'Bathrooms', FieldKind.seg, options: ['1', '2', '3', '4+']),
        FieldSpec('area', 'Area (sq ft)', FieldKind.text, placeholder: '1,850', keyboard: TextInputType.number),
        FieldSpec('year', 'Year built', FieldKind.text, placeholder: '2018', keyboard: TextInputType.number),
        FieldSpec('furn', 'Furnishing', FieldKind.seg, options: ['Furnished', 'Unfurnished']),
      ]),
      const StepSpec('The numbers', fields: [
        FieldSpec('purchase', 'Purchase price', FieldKind.money),
        FieldSpec('value', 'Current value', FieldKind.money),
        FieldSpec('loan', 'Mortgage / loan (optional)', FieldKind.money),
        FieldSpec('exp', 'Monthly expenses', FieldKind.money),
      ]),
      const StepSpec('Add photos', fields: [
        FieldSpec('photos', 'Property photos', FieldKind.upload, multi: true),
        FieldSpec('notes', 'Notes / summary', FieldKind.note, placeholder: 'Anything worth remembering'),
      ]),
      StepSpec('Review', review: (v, ref) {
        final photos = v.files('photos');
        return PropertyReviewCard(
          name: v.str('name').isEmpty ? 'New property' : v.str('name'),
          location: [v.str('address'), v.str('city')].where((s) => s.isNotEmpty).join(', '),
          photo: photos.isNotEmpty ? photos.first : e?.coverUrl,
          rows: [
            ('Type', v.str('type')),
            ('Status', v.str('status')),
            ('Address', [v.str('address'), v.str('city')].where((s) => s.isNotEmpty).join(', ')),
            ('Country', '${v.str('country')} ${v.str('postal')}'.trim()),
            ('Layout', '${v.str('beds')} bed · ${v.str('baths')} bath${v.str('area').isEmpty ? '' : ' · ${v.str('area')} sq ft'}'),
            ('Built / furnishing', '${v.str('year').isEmpty ? '—' : v.str('year')} · ${v.str('furn')}'),
            ('Purchase price', Money.full(Money.parse(v.str('purchase')))),
            ('Current value', Money.full(Money.parse(v.str('value')))),
            ('Loan', v.str('loan').isEmpty ? 'None' : Money.full(Money.parse(v.str('loan')))),
            ('Monthly expenses', Money.full(Money.parse(v.str('exp')))),
            ('Photos', '${photos.length} added'),
          ],
        );
      }),
    ],
    onSave: (v, WidgetRef ref) async {
      int? n(String k) => int.tryParse(v.str(k).replaceAll(RegExp(r'[^0-9]'), ''));
      final purchase = Money.parse(v.str('purchase'));
      final value = Money.parse(v.str('value'));
      final p = await ref.read(savePropertyProvider)(
        PropertyDraft(
          name: v.str('name'),
          type: PropertyType.fromLabel(v.str('type')),
          status: PropertyStatus.fromLabel(v.str('status')),
          address: v.str('address'),
          city: v.str('city'),
          country: v.str('country').trim().isNotEmpty || e != null ? v.str('country') : _userCountry(ref),
          postalCode: v.str('postal'),
          bedrooms: n('beds'),
          bathrooms: n('baths'),
          areaSqft: n('area'),
          yearBuilt: n('year'),
          furnished: v.str('furn') == 'Furnished',
          purchasePrice: purchase,
          currentValue: value == 0 ? purchase : value,
          mortgage: Money.parse(v.str('loan')),
          monthlyExpenses: Money.parse(v.str('exp')),
          photoUrls: v.files('photos'),
          notes: v.str('notes'),
        ),
        editingId: e?.id,
      );
      if (e == null && p.status == PropertyStatus.rented) {
        return FormResult(toast: '${p.name} added · now add its lease', replaceWith: Routes.add('lease', propertyId: p.id));
      }
      return FormResult(
        toast: e == null ? '${p.name} added to your portfolio' : 'Changes saved',
        replaceWith: e == null ? Routes.property(p.id) : null,
      );
    },
  );
}
