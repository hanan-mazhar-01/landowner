import 'dart:math' as math;

import '../../../core/utils/formatters.dart';
import '../../../features/leases/domain/lease.dart';
import '../../../features/properties/domain/property.dart';
import '../../../features/tenants/domain/tenant.dart';

String unsplash(String id, {int w = 800}) =>
    'https://images.unsplash.com/$id?q=80&w=$w&auto=format&fit=crop';

/// Monthly valuation curve from purchase to today (`pow(t, 1.3)` as in the design).
List<ValuePoint> _history(DateTime purchased, int purchase, int value, DateTime now) {
  final months = (now.year - purchased.year) * 12 + now.month - purchased.month;
  return List.generate(months + 1, (i) {
    final t = months == 0 ? 1.0 : i / months;
    final v = purchase + (value - purchase) * math.pow(t, 1.3);
    return ValuePoint(Dates.addMonths(Dates.monthStart(purchased), i), v.round());
  });
}

List<Property> seedProperties(DateTime now) {
  Property p(String id, String name, PropertyType t, PropertyStatus s, String addr, String area, String city,
          int year, int purchase, int value, int exp, int units, List<String> photos,
          {int? beds, int? baths, int? sqft}) =>
      Property(
        id: id,
        name: name,
        type: t,
        status: s,
        address: addr,
        area: area,
        city: city,
        country: 'Pakistan',
        yearBuilt: year,
        purchasePrice: purchase,
        currentValue: value,
        monthlyExpenses: exp,
        unitCount: units,
        bedrooms: beds,
        bathrooms: baths,
        areaSqft: sqft,
        photoUrls: photos.map(unsplash).toList(),
        valueHistory: _history(DateTime(year), purchase, value, now),
        createdAt: DateTime(year),
      );

  return [
    p('p1', 'Green Villa', PropertyType.house, PropertyStatus.rented, '416 Oak Street, Sector J · DHA Phase 6',
        'DHA Phase 6', 'Lahore', 2021, 38000000, 48500000, 28000, 1,
        ['photo-1600585154340-be6161a56a0c', 'photo-1600596542815-ffad4c1539a9', 'photo-1600607687939-ce8a6c25118c'],
        beds: 5, baths: 4, sqft: 4500),
    p('p2', 'LuxeApart Residencies', PropertyType.apartment, PropertyStatus.rented,
        'Tower B, Suite 804 · Main Boulevard', 'Gulberg III', 'Lahore', 2022, 25000000, 32000000, 42500, 4,
        ['photo-1545324418-cc1a3fa10c00', 'photo-1512917774080-9991f1c4c750']),
    p('p3', 'Downtown Commercial Plaza', PropertyType.commercial, PropertyStatus.rented,
        'Floor 3, Tech Hub Plaza · Jinnah Ave', 'Blue Area', 'Islamabad', 2020, 22000000, 28000000, 65000, 6,
        ['photo-1486406146926-c627a92ad1ab']),
    p('p4', 'Model Town Residence', PropertyType.house, PropertyStatus.vacant, '18 Garden Way · Model Town',
        'Model Town Block C', 'Lahore', 2023, 13500000, 16300000, 18000, 1,
        ['photo-1580587771525-78b9dba3b914', 'photo-1513694203232-719a280e022f'],
        beds: 4, baths: 3, sqft: 2800),
  ];
}

List<Tenant> seedTenants(DateTime now) {
  Tenant t(String id, String name, String phone, String email, int sinceMonthsAgo) => Tenant(
        id: id,
        name: name,
        phone: phone,
        email: email,
        createdAt: Dates.addMonths(now, -sinceMonthsAgo),
      );
  return [
    t('t1', 'Jane Doe', '+92 300 555 0101', 'jane.doe@mail.com', 9),
    t('t2', 'Ahmed Khan', '+92 300 555 0199', 'ahmed.khan@mail.com', 30),
    t('t3', 'Sara Iqbal', '+92 321 555 0112', 'sara.iqbal@mail.com', 22),
    t('t4', 'Bilal Aslam', '+92 333 555 0123', 'bilal.aslam@mail.com', 18),
    t('t5', 'Nadia Raza', '+92 345 555 0134', 'nadia.raza@mail.com', 14),
    t('t6', 'TechVentures Corp', '+92 51 555 0145', 'accounts@techventures.pk', 26),
    t('t7', 'Crescent Pharmacy', '+92 51 555 0156', 'crescent.rx@mail.com', 40),
    t('t8', 'Ali & Co. Chartered', '+92 51 555 0167', 'office@aliandco.pk', 34),
    t('t9', 'Bean There Café', '+92 51 555 0178', 'hello@beanthere.pk', 20),
    t('t10', 'Nova Fitness', '+92 51 555 0189', 'team@novafit.pk', 16),
    t('t11', 'Omar Farooq', '+92 300 555 0190', 'omar.farooq@mail.com', 36),
  ];
}

List<Lease> seedLeases(DateTime now) {
  final m0 = Dates.monthStart(now);
  Lease l(String id, String prop, String tenant, int rent, int startAgo, int endIn,
          {String? unit, int due = 1, int? endDay}) {
    final start = Dates.addMonths(m0, -startAgo);
    final end = endDay != null
        ? DateTime(now.year, now.month, now.day).subtract(Duration(days: endDay))
        : Dates.addMonths(m0, endIn).subtract(const Duration(days: 1));
    return Lease(
      id: id,
      propertyId: prop,
      tenantId: tenant,
      unitLabel: unit,
      monthlyRent: rent,
      deposit: rent * 2,
      start: start,
      end: end,
      dueDay: due,
      createdAt: start,
    );
  }

  return [
    l('l1', 'p1', 't1', 120000, 8, 4),
    l('l2', 'p2', 't2', 46000, 30, 6, unit: 'Unit 3', due: 26),
    l('l3', 'p2', 't3', 46000, 22, 8, unit: 'Unit 1'),
    l('l4', 'p2', 't4', 46500, 18, 12, unit: 'Unit 2'),
    l('l5', 'p2', 't5', 46500, 14, 16, unit: 'Unit 4'),
    l('l6', 'p3', 't6', 120000, 25, 11, unit: 'Floor 3'),
    l('l7', 'p3', 't7', 30000, 40, 8, unit: 'Shop 1'),
    l('l8', 'p3', 't8', 30000, 34, 14, unit: 'Office 2'),
    l('l9', 'p3', 't9', 30000, 20, 16, unit: 'Shop 2'),
    l('l10', 'p3', 't10', 30000, 16, 20, unit: 'Floor 1'),
    // Model Town's last lease ended 12 days ago — the property is vacant.
    l('l11', 'p4', 't11', 95000, 30, 0, endDay: 12),
  ];
}
