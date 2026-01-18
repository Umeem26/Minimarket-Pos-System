import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_model.dart';

class ProductService {
  final supabase = Supabase.instance.client;

  // 1. Ambil Kategori
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await supabase.from('categories').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Error Kategori: $e");
      return [];
    }
  }

  // 2. Ambil List Stok
  Future<List<Map<String, dynamic>>> getStockList() async {
    try {
      final response = await supabase
          .from('stocks')
          .select('*, products(*, categories(*))')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Error Stok: $e");
      return [];
    }
  }

  // 3. Tambah Produk Baru
  Future<void> addProduct(ProductModel product, String floor, double initialQty, DateTime? expiry) async {
    try {
      await supabase.from('products').insert({
        'id': product.id,
        'brand_name': product.brandName,
        'category_id': product.categoryId,
        'unit_type': product.unitType,
        'min_stock': product.minStock,
      });

      await supabase.from('stocks').insert({
        'product_id': product.id,
        'floor_name': floor,
        'quantity': initialQty,
        'expiry_date': expiry?.toIso8601String(),
      });
    } catch (e) {
      throw Exception("Gagal Tambah Produk: $e");
    }
  }

  // --- FITUR BARU: PINDAH STOK (MUTASI) ---
  Future<void> moveStock({
    required int sourceStockId,      // ID baris stok asal
    required String productId,       // ID Produk
    required String targetFloor,     // Mau dipindah ke lantai mana?
    required double qtyToMove,       // Berapa banyak?
    required double currentSourceQty,// Stok asal sekarang berapa?
    DateTime? expiryDate,            // Tanggal kadaluarsa (dibawa pindah)
  }) async {
    try {
      // A. Cek dulu, stok asal cukup gak?
      if (qtyToMove > currentSourceQty) {
        throw Exception("Stok tidak cukup! Cuma ada $currentSourceQty");
      }

      // B. Kurangi stok di lantai ASAL
      final sisa = currentSourceQty - qtyToMove;
      if (sisa == 0) {
        // Jika habis, hapus barisnya dari lantai asal (Opsional, tapi biar rapi)
        await supabase.from('stocks').delete().eq('id', sourceStockId);
      } else {
        // Jika sisa, update angkanya
        await supabase.from('stocks').update({'quantity': sisa}).eq('id', sourceStockId);
      }

      // C. Cek apakah di lantai TUJUAN barang ini sudah ada?
      final checkDest = await supabase
          .from('stocks')
          .select()
          .eq('product_id', productId)
          .eq('floor_name', targetFloor)
          .maybeSingle(); // Ambil 1 jika ada

      if (checkDest != null) {
        // D1. Jika SUDAH ADA, update (tambahkan)
        final double oldQty = (checkDest['quantity'] as num).toDouble();
        await supabase.from('stocks').update({
          'quantity': oldQty + qtyToMove
        }).eq('id', checkDest['id']);
      } else {
        // D2. Jika BELUM ADA, buat baris baru di lantai tujuan
        await supabase.from('stocks').insert({
          'product_id': productId,
          'floor_name': targetFloor,
          'quantity': qtyToMove,
          'expiry_date': expiryDate?.toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception("Gagal Mutasi: $e");
    }
  }
}