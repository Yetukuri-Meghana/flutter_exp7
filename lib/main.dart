import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database_helper.dart';
import 'product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProductInventoryTracker());
}

class ProductInventoryTracker extends StatelessWidget {
  const ProductInventoryTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Cloud-Based Product Inventory Tracker',
      debugShowCheckedModeBanner: false,
      home: ProductScreen(),
    );
  }
}

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  late Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = DatabaseHelper().getAllProducts();
  }

  void _clearFields() {
    _nameController.clear();
    _quantityController.clear();
    _priceController.clear();
  }

  void _addProduct() async {
    if (_nameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }
    try {
      final newProduct = Product(
        name: _nameController.text.trim(),
        quantity: int.tryParse(_quantityController.text) ?? 0,
        price: double.tryParse(_priceController.text) ?? 0.0,
      );
      await DatabaseHelper().insertProduct(newProduct);
      if (!mounted) return;
      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Product added successfully!"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error adding product: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📦 Cloud-Based Product Inventory Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
              autocorrect: false,
              enableSuggestions: false,
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _addProduct, child: const Text("Save Product")),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _productsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = snapshot.data!;
                  double totalStockValue = 0.0;
                  if (products.isNotEmpty) {
                    totalStockValue = products.fold(0.0, (double sum, Product p) => sum + (p.quantity * p.price));
                  }
                  if (products.isEmpty) {
                    return const Center(child: Text("No products found"));
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            bool lowStock = product.quantity < 5;
                            return Card(
                              child: ListTile(
                                title: Text(product.name),
                                subtitle: Text(
                                    "Quantity: ${product.quantity} | Price: \$${product.price.toStringAsFixed(2)}"),
                                trailing: lowStock
                                    ? const Text(
                                        "Low Stock!",
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(thickness: 1),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "📊 Total Stock Value: \$${totalStockValue.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}