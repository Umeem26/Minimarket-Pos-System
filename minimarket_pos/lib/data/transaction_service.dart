import 'package:supabase_flutter/supabase_flutter.dart';
import 'transaction_model.dart';

class TransactionService {
  final supabase = Supabase.instance.client;

  // Simpan Transaksi & Potong Stok
  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      // 1. Simpan HEADER (Total, Bayar, Kembalian)
      final response = await supabase.from('transactions').insert({
        'total_amount': transaction.totalAmount,
        'paid_amount': transaction.paidAmount,
        'change_amount': transaction.changeAmount,
      }).select().single(); // select() agar kita dapat ID barunya

      final newTransactionId = response['id'];

      // 2. Simpan DETAIL BARANG (Isi Keranjang)
      final List<Map<String, dynamic>> itemsData = transaction.items.map((item) {
        return {
          'transaction_id': newTransactionId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price_at_purchase': item.price,
          'subtotal': item.subtotal,
        };
      }).toList();

      await supabase.from('transaction_items').insert(itemsData);

      // 3. --- LOGIKA BARU: POTONG STOK ---
      for (var item in transaction.items) {
        // A. Cari stok barang ini (ambil yang stoknya terbanyak dulu biar aman)
        final stockResponse = await supabase
            .from('stocks')
            .select()
            .eq('product_id', item.productId)
            .order('quantity', ascending: false) // Prioritaskan stok banyak
            .limit(1)
            .maybeSingle();

        if (stockResponse != null) {
          final stockId = stockResponse['id'];
          final currentQty = (stockResponse['quantity'] as num).toDouble();
          
          // B. Hitung sisa stok
          double newQty = currentQty - item.quantity;
          if (newQty < 0) newQty = 0; // Jaga-jaga biar gak minus

          // C. Update ke database
          await supabase
              .from('stocks')
              .update({'quantity': newQty})
              .eq('id', stockId);
        }
      }

    } catch (e) {
      throw Exception("Gagal Transaksi: $e");
    }
  }
}