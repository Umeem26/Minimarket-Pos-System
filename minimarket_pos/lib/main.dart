import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

// Import halaman
import 'presentation/stock_list_screen.dart';
import 'presentation/add_product_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimarket POS',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        useMaterial3: true, // Desain Modern Otomatis
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1565C0), // Biru Profesional
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Putih Tulang (Lebih lembut dari putih biasa)
        
        // Skema Warna Utama
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
          secondary: const Color(0xFFEF6C00), // Aksen Oranye
        ),

        // --- UPGRADE FONT DISINI (POPINS) ---
        textTheme: GoogleFonts.poppinsTextTheme(),

        // Style Judul Atas
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle( // Memaksa judul pakai Poppins Bold
            fontFamily: 'Poppins', 
            fontSize: 20, 
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
        ),

        // Style Kotak Input (Form)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Lebih bulat dikit biar friendly
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: borderSide(Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
        ),
      ),

      home: const StockListScreen(),
    );
  }

  // Helper simpel untuk border
  BorderSide borderSide(Color color) => BorderSide(color: color);
}