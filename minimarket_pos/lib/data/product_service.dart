import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_model.dart';

class ProductService {
  // Ini adalah "kunci" agar semua fungsi di bawah kenal 'supabase'
  final supabase = Supabase.instance.client;

  // 1. Ambil Daftar Kategori
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await supabase.from('categories').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Error Kategori: $e");
      return [];
    }
  }

  // 2. Ambil Daftar Stok (Real-time List)
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

  // 3. Tambah Produk Baru (LENGKAP DENGAN HARGA)
  Future<void> addProduct(ProductModel product, String floor, double initialQty, DateTime? expiry) async {
    try {
      // Simpan Data Produk Utama
      await supabase.from('products').insert({
        'id': product.id,
        'brand_name': product.brandName,
        'category_id': product.categoryId,
        'unit_type': product.unitType,
        'min_stock': product.minStock,
        // Data Harga (Baru)
        'price': product.price,
        'capital_price': product.capitalPrice,
      });

      // Simpan Stok Awal
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

  // 4. Mutasi Stok (Pindah Antar Lantai)
  Future<void> moveStock({
    required int sourceStockId,
    required String productId,
    required String targetFloor,
    required double qtyToMove,
    required double currentSourceQty,
    DateTime? expiryDate,
  }) async {
    try {
      // A. Cek apakah stok asal cukup?
      if (qtyToMove > currentSourceQty) {
        throw Exception("Stok tidak cukup! Cuma ada $currentSourceQty");
      }

      // B. Kurangi stok di lantai ASAL
      final sisa = currentSourceQty - qtyToMove;
      if (sisa == 0) {
        // Jika habis, hapus barisnya biar bersih
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
          .maybeSingle(); 

      if (checkDest != null) {
        // D1. Jika SUDAH ADA, tambahkan ke stok yang ada
        final double oldQty = (checkDest['quantity'] as num).toDouble();
        await supabase.from('stocks').update({
          'quantity': oldQty + qtyToMove
        }).eq('id', checkDest['id']);
      } else {
        // D2. Jika BELUM ADA, buat baris baru
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
// Pastikan kurung kurawal penutup class ada di paling bawah sini