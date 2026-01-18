import 'package:flutter/material.dart';
import '../data/product_service.dart';
import 'add_product_screen.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final _service = ProductService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stok Real-time")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.getStockList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada stok barang."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final stock = snapshot.data![index];
              final product = stock['products'];
              
              return Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFBB86FC), width: 0.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    product['brand_name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Lokasi: ${stock['floor_name']}"),
                      Text("Kategori: ${product['categories']['name']}"),
                      if (stock['expiry_date'] != null)
                        Text("Kadaluarsa: ${stock['expiry_date']}", 
                             style: const TextStyle(color: Color(0xFF03DAC6))),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${stock['quantity']}",
                        style: const TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFFBB86FC)
                        ),
                      ),
                      Text(product['unit_type']),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Tombol melayang untuk pindah ke halaman Tambah Barang
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB86FC),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((value) => setState(() {})); // Refresh saat kembali
        },
      ),
    );
  }
}