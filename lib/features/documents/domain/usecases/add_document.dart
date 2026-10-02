import '../../../../core/data/repository.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/clock.dart';
import '../../../notifications/domain/app_notification.dart';
import '../../../properties/domain/property.dart';
import '../document_item.dart';

/// Property → Document → Expiry → (reminder via engine) → Notification.
class AddDocument {
  AddDocument(this._docs, this._props, this._notifs, this._clock, [this._cloudinary]);

  final Repository<DocumentItem> _docs;
  final Repository<Property> _props;
  final Repository<AppNotification> _notifs;
  final Clock _clock;
  final CloudinaryService? _cloudinary;

  Future<DocumentItem> call({
    required String propertyId,
    required DocumentType type,
    required String name,
    required DateTime date,
    DateTime? expiry,
    String notes = '',
    String? fileUrl,
    int fileCount = 1,
  }) async {
    var finalUrl = fileUrl;
    if (_cloudinary != null && finalUrl != null && finalUrl.isNotEmpty) {
      finalUrl = await _cloudinary.uploadMediaIfLocal(finalUrl, CloudinaryFolder.documents);
    }
    final d = DocumentItem(
      id: newId('d'),
      propertyId: propertyId,
      type: type,
      name: name.trim().isEmpty ? type.label : name.trim(),
      fileUrl: finalUrl,
      date: date,
      expiry: expiry,
      notes: notes,
      fileCount: fileCount,
    );
    await _docs.upsert(d);
    await _notifs.upsert(AppNotification(
      id: newId('n'),
      category: NotificationCategory.documents,
      title: 'Document added',
      body: '${d.name} · ${_props.byId(propertyId)?.name ?? ''}',
      createdAt: _clock.now(),
      unread: false,
      target: '/properties/$propertyId',
      propertyId: propertyId,
    ));
    return d;
  }
}
