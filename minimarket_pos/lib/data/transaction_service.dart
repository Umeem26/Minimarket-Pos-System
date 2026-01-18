import 'package:supabase_flutter/supabase_flutter.dart';
import 'transaction_model.dart';

class TransactionService {
  final supabase = Supabase.instance.client;

  // Simpan Transaksi ke Database
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
      // Kita siapkan datanya dalam bentuk List biar sekali kirim langsung masuk semua
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

      // 3. (Opsional) POTONG STOK
      // Di tahap awal ini kita simpan data penjualannya dulu agar aman.
      // Nanti kita bisa tambahkan logika potong stok di sini.

    } catch (e) {
      throw Exception("Gagal Transaksi: $e");
    }
  }
}