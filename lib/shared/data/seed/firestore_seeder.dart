import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'demo_seed.dart';

class FirestoreSeeder {
  static bool _purged = false;

  static const _subcollections = [
    'properties',
    'tenants',
    'leases',
    'charges',
    'ledger',
    'maintenance',
    'documents',
    'reminders',
    'notifications',
  ];

  /// Completely wipes all portfolio collections for a user so they get a clean zero state.
  static Future<void> clearUserData(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);
      for (final col in _subcollections) {
        final snap = await userRef.collection(col).get();
        if (snap.docs.isEmpty) continue;
        final batch = firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      debugPrint('Firestore data cleared for user $uid');
    } catch (e) {
      debugPrint('FirestoreSeeder.clearUserData error: $e');
    }
  }

  /// Automatically purges demo seed documents if they were previously written.
  static Future<void> purgeSeedDataIfPresent(String uid) async {
    if (_purged) return;
    _purged = true;
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);
      final p1 = await userRef.collection('properties').doc('p1').get();
      if (!p1.exists) return;

      debugPrint('Demo seed detected for user $uid — purging hardcoded data from Firestore...');
      await clearUserData(uid);
      debugPrint('Demo seed successfully purged from Firestore.');
    } catch (e) {
      debugPrint('FirestoreSeeder.purgeSeedDataIfPresent error: $e');
    }
  }

  /// Seeds initial portfolio dataset into Firestore if the user's collection is empty.
  static Future<void> seedIfEmpty(String uid, DemoSeed seed) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);
      final propsSnap = await userRef.collection('properties').limit(1).get();
      if (propsSnap.docs.isNotEmpty) {
        return;
      }

      debugPrint('Seeding initial LandOwner portfolio into Cloud Firestore for user $uid...');
      final batch = firestore.batch();

      for (final p in seed.properties) {
        batch.set(userRef.collection('properties').doc(p.id), p.toMap(), SetOptions(merge: true));
      }
      for (final t in seed.tenants) {
        batch.set(userRef.collection('tenants').doc(t.id), t.toMap(), SetOptions(merge: true));
      }
      for (final l in seed.leases) {
        batch.set(userRef.collection('leases').doc(l.id), l.toMap(), SetOptions(merge: true));
      }
      for (final c in seed.charges) {
        batch.set(userRef.collection('charges').doc(c.id), c.toMap(), SetOptions(merge: true));
      }
      for (final e in seed.ledger) {
        batch.set(userRef.collection('ledger').doc(e.id), e.toMap(), SetOptions(merge: true));
      }
      for (final m in seed.maintenance) {
        batch.set(userRef.collection('maintenance').doc(m.id), m.toMap(), SetOptions(merge: true));
      }
      for (final d in seed.documents) {
        batch.set(userRef.collection('documents').doc(d.id), d.toMap(), SetOptions(merge: true));
      }
      for (final n in seed.notifications) {
        batch.set(userRef.collection('notifications').doc(n.id), n.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('Cloud Firestore initial seed completed successfully.');
    } catch (e) {
      debugPrint('FirestoreSeeder error: $e');
    }
  }

  /// Force reseeds demo data if user requests to reset.
  static Future<void> reseed(String uid, DemoSeed seed) async {
    await seedIfEmpty(uid, seed);
  }
}
