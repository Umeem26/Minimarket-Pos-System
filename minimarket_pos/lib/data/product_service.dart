import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_model.dart';

class ProductService {
  final supabase = Supabase.instance.client;

  // Mengambil daftar kategori untuk ditampilkan di Dropdown UI
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await supabase.from('categories').select();
    return List<Map<String, dynamic>>.from(response);
  }

  // Menyimpan Produk Baru dan Stok Awalnya
  Future<void> addProduct(ProductModel product, String floor, double initialQty, DateTime? expiry) async {
    // 1. Simpan ke tabel products
    await supabase.from('products').insert({
      'id': product.id,
      'brand_name': product.brandName,
      'category_id': product.categoryId,
      'unit_type': product.unitType,
      'min_stock': product.minStock,
    });

    // 2. Simpan stok awal ke tabel stocks
    await supabase.from('stocks').insert({
      'product_id': product.id,
      'floor_name': floor,
      'quantity': initialQty,
      'expiry_date': expiry?.toIso8601String(),
    });
  }
}