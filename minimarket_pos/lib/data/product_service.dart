import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_model.dart';

class ProductService {
  final supabase = Supabase.instance.client;

  // Mengambil daftar kategori dengan Debugging
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      print("🔍 Sedang mengambil data kategori dari Supabase...");
      
      final response = await supabase
          .from('categories')
          .select()
          .order('name', ascending: true); // Urutkan abjad

      print("✅ Berhasil! Data diterima: $response");
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      print("❌ ERROR Gagal ambil kategori: $e");
      return []; // Kembalikan list kosong jika error biar gak crash
    }
  }

  // Mengambil daftar stok
  Future<List<Map<String, dynamic>>> getStockList() async {
    try {
      final response = await supabase
          .from('stocks')
          .select('*, products(*, categories(*))')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ ERROR Gagal ambil stok: $e");
      return [];
    }
  }

  // Menyimpan Produk Baru
  Future<void> addProduct(ProductModel product, String floor, double initialQty, DateTime? expiry) async {
    try {
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
      print("✅ Produk berhasil disimpan!");
    } catch (e) {
      print("❌ ERROR Gagal simpan produk: $e");
      throw Exception(e); // Lempar error ke UI biar muncul SnackBar merah
    }
  }
}