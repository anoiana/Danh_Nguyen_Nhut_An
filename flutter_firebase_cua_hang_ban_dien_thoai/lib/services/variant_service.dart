import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/variant.dart';

class VariantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Variant?> getVariantById(String variantId) async {
    try {
      final doc = await _firestore.collection('variants').doc(variantId).get();
      if (doc.exists) {
        return Variant.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting variant: $e');
      return null;
    }
  }

  Future<List<Variant>> getVariantsByIds(List<String> variantIds) async {
    try {
      final variants = await Future.wait(
        variantIds.map((id) => getVariantById(id)),
      );
      return variants.whereType<Variant>().toList();
    } catch (e) {
      print('Error getting variants: $e');
      return [];
    }
  }
}
