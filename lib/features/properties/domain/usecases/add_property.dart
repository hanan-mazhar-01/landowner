import '../../../../core/data/repository.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../notifications/domain/app_notification.dart';
import '../property.dart';

class PropertyDraft {
  const PropertyDraft({
    required this.name,
    required this.type,
    required this.status,
    required this.address,
    required this.city,
    required this.country,
    required this.postalCode,
    this.bedrooms,
    this.bathrooms,
    this.areaSqft,
    this.yearBuilt,
    this.furnished = false,
    required this.purchasePrice,
    required this.currentValue,
    this.mortgage = 0,
    this.monthlyExpenses = 0,
    this.photoUrls = const [],
    this.notes = '',
  });

  final String name, address, city, country, postalCode, notes;
  final PropertyType type;
  final PropertyStatus status;
  final int? bedrooms, bathrooms, areaSqft, yearBuilt;
  final bool furnished;
  final int purchasePrice, currentValue, mortgage, monthlyExpenses;
  final List<String> photoUrls;
}

class SaveProperty {
  SaveProperty(this._props, this._notifs, this._clock, [this._cloudinary]);

  final Repository<Property> _props;
  final Repository<AppNotification> _notifs;
  final Clock _clock;
  final CloudinaryService? _cloudinary;

  Future<Property> call(PropertyDraft d, {String? editingId}) async {
    final now = _clock.now();
    final existing = editingId == null ? null : _props.byId(editingId);

    var photos = d.photoUrls.isEmpty ? (existing?.photoUrls ?? const <String>[]) : d.photoUrls;
    if (_cloudinary != null && photos.isNotEmpty) {
      photos = await _cloudinary.uploadMultipleIfLocal(photos, CloudinaryFolder.properties);
    }
    final p = Property(
      id: existing?.id ?? newId('p'),
      name: d.name.trim().isEmpty ? 'New property' : d.name.trim(),
      type: d.type,
      status: d.status,
      address: d.address,
      area: '',
      city: d.city,
      country: d.country,
      postalCode: d.postalCode,
      bedrooms: d.bedrooms,
      bathrooms: d.bathrooms,
      areaSqft: d.areaSqft,
      yearBuilt: d.yearBuilt,
      furnished: d.furnished,
      purchasePrice: d.purchasePrice,
      currentValue: d.currentValue,
      mortgage: d.mortgage,
      monthlyExpenses: d.monthlyExpenses,
      photoUrls: photos,
      notes: d.notes,
      valueHistory: existing?.valueHistory ?? [ValuePoint(Dates.monthStart(now), d.currentValue)],
      createdAt: existing?.createdAt ?? now,
    );
    await _props.upsert(p);
    if (existing == null) {
      await _notifs.upsert(AppNotification(
        id: newId('n'),
        category: NotificationCategory.property,
        title: 'Property added',
        body: '${p.name} · ${Money.m(p.currentValue)}',
        createdAt: now,
        unread: false,
        target: '/properties/${p.id}',
        propertyId: p.id,
      ));
    }
    return p;
  }
}
