import 'package:flutter/material.dart';
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
        final product = ProductModel(
          id: _idController.text,
          brandName: _nameController.text,
          categoryId: int.parse(_selectedCategory!),
          unitType: _selectedUnit,
          minStock: double.parse(_minStockController.text),
        );

        await _service.addProduct(
          product, 
          _selectedFloor, 
          double.parse(_qtyController.text), 
          _selectedExpiry
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Barang Berhasil Disimpan!")),
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
      appBar: AppBar(title: const Text("Input Barang Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card( // Bungkus form pakai Card putih biar rapi
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informasi Utama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),
                  _buildTextField(_idController, "Barcode / ID Barang", Icons.qr_code),
                  const SizedBox(height: 15),
                  _buildTextField(_nameController, "Nama Merek / Barang", Icons.label),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildCategoryDropdown()),
                      const SizedBox(width: 10),
                      Expanded(flex: 1, child: _buildUnitDropdown()),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),
                  
                  const Text("Stok & Lokasi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_qtyController, "Jumlah Awal", Icons.inventory, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildFloorDropdown()),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(_minStockController, "Peringatan Stok Minim", Icons.warning_amber, isNumber: true),
                  
                  const SizedBox(height: 15),
                  _buildDatePicker(),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800], // Tombol Biru Tua
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

  // --- Widget Helper (Disederhanakan untuk Light Mode) ---
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
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