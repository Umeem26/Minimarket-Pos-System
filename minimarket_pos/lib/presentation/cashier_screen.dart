import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/product_service.dart';
import '../data/transaction_model.dart';
import '../data/transaction_service.dart';
import 'add_product_screen.dart'; // Untuk pinjam formatter uang

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _productService = ProductService();
  final _transactionService = TransactionService();
  final _searchController = TextEditingController();
  final _payController = TextEditingController();

  // Data
  List<Map<String, dynamic>> _allProducts = []; // Semua barang
  List<Map<String, dynamic>> _filteredProducts = []; // Hasil pencarian
  List<CartItem> _cart = []; // Keranjang Belanja

  // Format Rupiah
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Ambil data produk untuk dipilih kasir
  void _loadProducts() async {
    final data = await _productService.getStockList();
    // Kita filter hanya ambil data produknya saja (unik berdasarkan ID produk)
    // Karena stok list menampilkan per lantai, kita ambil salah satu saja untuk master harga
    // (Logic sederhananya: ambil semua stok yang ada)
    setState(() {
      _allProducts = data;
      _filteredProducts = data;
    });
  }

  // Cari Barang
  void _runFilter(String keyword) {
    List<Map<String, dynamic>> results = [];
    if (keyword.isEmpty) {
      results = _allProducts;
    } else {
      results = _allProducts.where((item) {
        final name = item['products']['brand_name'].toString().toLowerCase();
        final code = item['products']['id'].toString().toLowerCase();
        return name.contains(keyword.toLowerCase()) || code.contains(keyword.toLowerCase());
      }).toList();
    }
    setState(() => _filteredProducts = results);
  }

  // Tambah ke Keranjang
  void _addToCart(Map<String, dynamic> stock) {
    final product = stock['products'];
    final id = product['id'];
    
    // Cek apakah barang sudah ada di keranjang?
    final existingIndex = _cart.indexWhere((item) => item.productId == id);

    setState(() {
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++; // Tambah jumlah
      } else {
        _cart.add(CartItem(
          productId: id,
          productName: product['brand_name'],
          price: (product['price'] as num).toDouble(),
          quantity: 1,
        ));
      }
    });
  }

  // Hitung Total Belanja
  double get _totalAmount => _cart.fold(0, (sum, item) => sum + item.subtotal);

  // Proses Bayar
  void _processPayment() async {
    if (_payController.text.isEmpty) return;
    
    // Bersihkan titik dari input uang (format rupiah)
    double paid = double.parse(_payController.text.replaceAll('.', ''));
    double total = _totalAmount;

    if (paid < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Uang Pembayaran Kurang!"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // 1. Buat Objek Transaksi
      final transaction = TransactionModel(
        totalAmount: total,
        paidAmount: paid,
        changeAmount: paid - total,
        items: _cart,
      );

      // 2. Simpan ke Database
      await _transactionService.saveTransaction(transaction);

      // 3. Tampilkan Sukses & Reset
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("✅ Transaksi Sukses"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Total: ${_currency.format(total)}"),
                Text("Bayar: ${_currency.format(paid)}"),
                const Divider(),
                Text("KEMBALI: ${_currency.format(paid - total)}", 
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup Dialog
                  setState(() { 
                    _cart.clear();
                    _payController.clear();
                    _loadProducts(); // TAMBAHAN: Refresh stok di halaman kasir juga
                  });
                }, 
                child: const Text("Tutup & Transaksi Baru")
              )
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kasir")),
      body: Column(
        children: [
          // 1. Area Pencarian Barang
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Cari Nama Barang / Scan Barcode",
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.qr_code_scanner),
              ),
              onChanged: _runFilter,
            ),
          ),

          // 2. Daftar Barang (Hasil Pencarian)
          Expanded(
            flex: 2,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredProducts.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _filteredProducts[index];
                final product = item['products'];
                final price = (product['price'] as num?)?.toDouble() ?? 0;

                return ListTile(
                  tileColor: Colors.white,
                  leading: const Icon(Icons.local_offer, color: Colors.blue),
                  title: Text(product['brand_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${item['floor_name']} - Stok: ${item['quantity']}"),
                  trailing: Text(_currency.format(price), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  onTap: () => _addToCart(item),
                );
              },
            ),
          ),

          const Divider(thickness: 5, color: Colors.grey),

          // 3. Keranjang Belanja (Cart)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("KERANJANG BELANJA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                  Expanded(
                    child: _cart.isEmpty 
                    ? const Center(child: Text("Keranjang Kosong", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final cartItem = _cart[index];
                          return ListTile(
                            dense: true,
                            title: Text(cartItem.productName),
                            subtitle: Text("${cartItem.quantity} x ${_currency.format(cartItem.price)}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_currency.format(cartItem.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      if (cartItem.quantity > 1) {
                                        cartItem.quantity--;
                                      } else {
                                        _cart.removeAt(index);
                                      }
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Panel Pembayaran
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_currency.format(_totalAmount), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _payController,
                  keyboardType: TextInputType.number,
                  // Menggunakan Formatter yang sama dengan AddProductScreen agar ada titik otomatis
                  inputFormatters: [CurrencyInputFormatter()], 
                  decoration: const InputDecoration(
                    labelText: "Uang Diterima (Tunai)",
                    prefixIcon: Icon(Icons.money),
                    suffixText: "IDR",
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF6C00)),
                    onPressed: _cart.isEmpty ? null : _processPayment,
                    child: const Text("BAYAR SEKARANG", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}