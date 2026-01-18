import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambahan untuk Input Formatter
import 'package:intl/intl.dart';
import '../data/product_model.dart';
import '../data/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductService();

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');
  
  // Controller Harga
  final _priceController = TextEditingController();
  final _capitalPriceController = TextEditingController();
  
  String? _selectedCategory;
  String _selectedUnit = 'pcs';
  String _selectedFloor = 'Lantai 1';
  DateTime? _selectedExpiry;

  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final data = await _service.getCategories();
    if (mounted) setState(() => _categories = data);
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      try {
        // --- PEMBERSIHAN DATA (PENTING) ---
        // Hapus titik (.) dari input harga sebelum disimpan ke database
        // Contoh: "3.000.000" -> "3000000"
        final cleanPrice = _priceController.text.replaceAll('.', '');
        final cleanCapital = _capitalPriceController.text.replaceAll('.', '');

        final product = ProductModel(
          id: _idController.text,
          brandName: _nameController.text,
          categoryId: int.parse(_selectedCategory!),
          unitType: _selectedUnit,
          minStock: double.parse(_minStockController.text),
          // Gunakan harga bersih
          price: double.parse(cleanPrice),
          capitalPrice: double.parse(cleanCapital),
        );

        await _service.addProduct(
          product, 
          _selectedFloor, 
          double.parse(_qtyController.text), 
          _selectedExpiry
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Barang & Harga Berhasil Disimpan!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Pilih Kategori dulu!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Barang & Harga")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informasi Dasar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),
                  _buildTextField(_idController, "Barcode / Kode", Icons.qr_code),
                  const SizedBox(height: 15),
                  _buildTextField(_nameController, "Nama Produk", Icons.label),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildCategoryDropdown()),
                      const SizedBox(width: 10),
                      Expanded(flex: 1, child: _buildUnitDropdown()),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),
                  
                  const Text("Harga (Rupiah)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // Input Harga Modal (Pakai Formatter Mata Uang)
                      Expanded(child: _buildTextField(_capitalPriceController, "Harga Modal", Icons.monetization_on_outlined, isCurrency: true)),
                      const SizedBox(width: 10),
                      // Input Harga Jual (Pakai Formatter Mata Uang)
                      Expanded(child: _buildTextField(_priceController, "Harga Jual", Icons.sell, isCurrency: true)),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),

                  const Text("Stok Awal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_qtyController, "Jumlah", Icons.inventory, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildFloorDropdown()),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(_minStockController, "Minimal Stok (Alert)", Icons.warning_amber, isNumber: true),
                  
                  const SizedBox(height: 15),
                  _buildDatePicker(),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _saveProduct,
                      child: const Text("SIMPAN DATA", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget TextField yang sudah di-upgrade
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool isCurrency = false}) {
    return TextFormField(
      controller: controller,
      // Jika Currency, pakai keyboard angka. Jika isNumber biasa, pakai angka desimal.
      keyboardType: isCurrency 
          ? TextInputType.number 
          : (isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
      
      // Pasang Formatter jika Currency
      inputFormatters: isCurrency 
          ? [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()] 
          : (isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null),

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        suffixText: isCurrency ? "IDR" : null,
      ),
      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: "Kategori"),
      value: _selectedCategory,
      items: _categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: "Satuan"),
      value: _selectedUnit,
      items: ['pcs', 'gram', 'liter', 'ml'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (v) => setState(() => _selectedUnit = v!),
    );
  }

  Widget _buildFloorDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: "Lokasi"),
      value: _selectedFloor,
      items: ['Lantai 1', 'Lantai 2'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
      onChanged: (v) => setState(() => _selectedFloor = v!),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => _selectedExpiry = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Tanggal Kadaluarsa (Opsional)",
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blue[700]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          _selectedExpiry == null ? "-" : DateFormat('dd MMM yyyy').format(_selectedExpiry!),
          style: TextStyle(color: _selectedExpiry == null ? Colors.grey : Colors.black87),
        ),
      ),
    );
  }
}

// --- CLASS FORMATTER RUPIAH (TITIK OTOMATIS) ---
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 1. Hapus karakter aneh (selain angka)
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 2. Format jadi Rupiah (pakai titik)
    final int value = int.parse(newText);
    final formatter = NumberFormat('#,###', 'id_ID');
    newText = formatter.format(value);

    // 3. Kembalikan teks baru dengan kursor di paling kanan
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}