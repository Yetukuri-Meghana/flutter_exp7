import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

class DatabaseHelper {
  static final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  Future<void> insertProduct(Product product) async {
    await products.add(product.toMap());
  }

  Stream<List<Product>> getAllProducts() {
    return products.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
}