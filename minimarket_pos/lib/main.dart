import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/stock_list_screen.dart'; // Import halaman utama

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Load File .env
  await dotenv.load(fileName: ".env");

  // --- DEBUGGING: Cek apakah kunci terbaca ---
  final url = dotenv.env['SUPABASE_URL'];
  final key = dotenv.env['SUPABASE_ANON_KEY'];

  print("------------------------------------------------");
  print("🔍 CEK KUNCI SUPABASE:");
  print("URL: ${url ?? 'KOSONG (Gagal Load)'}");
  // Kita hanya print 5 huruf awal key biar aman
  print("KEY: ${key != null ? '${key.substring(0, 5)}...' : 'KOSONG'}");
  print("------------------------------------------------");

  if (url == null || key == null) {
    print("❌ FATAL: File .env tidak terbaca atau kosong!");
    return; // Stop aplikasi jangan lanjut
  }

  // 2. Konek Supabase
  await Supabase.initialize(
    url: url,
    anonKey: key,
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFBB86FC),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1B24),
          elevation: 0,
          centerTitle: true,
        ),
        // Ubah warna dropdown biar kelihatan teksnya
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const StockListScreen(), // Langsung ke Daftar Stok
    );
  }
}