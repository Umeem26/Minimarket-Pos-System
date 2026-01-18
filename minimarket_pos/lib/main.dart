import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/add_product_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- BAGIAN KONEKSI DATABASE ---
  // Ganti dengan URL dan Key asli dari dashboard Supabase Anda
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
      
      // --- BAGIAN TEMA (DITEMPATKAN DISINI AGAR RAPI) ---
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212), // Hitam Pekat
        primaryColor: const Color(0xFFBB86FC), // Ungu Utama
        
        // Mengatur standar warna komponen
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC),      // Ungu
          secondary: Color(0xFF03DAC6),    // Cyan (untuk aksen hologram)
          surface: Color(0xFF1E1E1E),      // Abu Gelap (untuk kartu/kotak)
        ),
        
        // Mengatur Font jadi modern
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        
        // Mengatur gaya AppBar (Judul Atas)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1B24), // Ungu-Hitam Gelap
          elevation: 0,
          centerTitle: true,
        ),
      ),

      // Layar Awal (Sementara untuk cek koneksi)
      home: const AddProductScreen(),
    );
  }
}

// Halaman sederhana untuk memastikan Database Konek
class TestConnectionPage extends StatelessWidget {
  const TestConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cek Koneksi")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, size: 80, color: Color(0xFFBB86FC)),
            const SizedBox(height: 20),
            const Text(
              "Sistem Siap!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBB86FC)),
              ),
              child: const Text(
                "Database Supabase Terhubung",
                style: TextStyle(color: Color(0xFF03DAC6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}