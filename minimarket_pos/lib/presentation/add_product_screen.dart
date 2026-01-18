import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Controller untuk Input
  final _idController = TextEditingController(); // Barcode
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');
  
  // State Dropdown
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
    setState(() => _categories = data);
  }

  // Fungsi Simpan
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Barang Berhasil Ditambahkan!")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Barang Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_idController, "Barcode / ID Barang", Icons.qr_code_scanner),
              const SizedBox(height: 15),
              _buildTextField(_nameController, "Nama Merek / Barang", Icons.shopping_bag),
              const SizedBox(height: 15),
              
              // Row untuk Kategori & Satuan
              Row(
                children: [
                  Expanded(child: _buildCategoryDropdown()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildUnitDropdown()),
                ],
              ),
              const SizedBox(height: 15),
              
              // Row untuk Stok & Lantai
              Row(
                children: [
                  Expanded(child: _buildTextField(_qtyController, "Jumlah Stok", Icons.inventory, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFloorDropdown()),
                ],
              ),
              const SizedBox(height: 15),

              _buildTextField(_minStockController, "Minimal Stok", Icons.warning_amber, isNumber: true),
              const SizedBox(height: 15),

              // Tanggal Kadaluarsa (Khusus Frozen/Obat)
              _buildDatePicker(),
              
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk UI yang Konsisten
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFBB86FC)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBB86FC), width: 2),
        ),
      ),
      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Kategori",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedCategory,
      items: _categories.map((c) => DropdownMenuItem(
        value: c['id'].toString(), 
        child: Text(c['name'])
      )).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Satuan",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedUnit,
      items: ['pcs', 'gram', 'liter', 'ml'].map((u) => DropdownMenuItem(
        value: u, 
        child: Text(u)
      )).toList(),
      onChanged: (v) => setState(() => _selectedUnit = v!),
    );
  }

  Widget _buildFloorDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Lokasi Lantai",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedFloor,
      items: ['Lantai 1', 'Lantai 2'].map((f) => DropdownMenuItem(
        value: f, 
        child: Text(f)
      )).toList(),
      onChanged: (v) => setState(() => _selectedFloor = v!),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      tileColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.date_range, color: Color(0xFF03DAC6)),
      title: Text(_selectedExpiry == null 
        ? "Set Tanggal Kadaluarsa" 
        : "Kadaluarsa: ${DateFormat('dd MMM yyyy').format(_selectedExpiry!)}"),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => _selectedExpiry = picked);
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFBB86FC), Color(0xFF03DAC6)],
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _saveProduct,
        child: const Text("SIMPAN BARANG", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }
}