// lib/main.dart
import 'package:dakaizleme/views/auth_screen.dart';
import 'package:dakaizleme/views/testmap.dart';

import 'package:dakaizleme/views/home_screen.dart'; // HomeScreen yerine ana giriş noktası ProjectListScreen olacak
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'update_locations.dart'; // Bu satırı kaldırın

// Yeni eklenen ProjectListScreen importu
import 'package:dakaizleme/views/project_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Tarih formatlama verilerini başlat
  await initializeDateFormatting('tr', null);

  // Konum güncelleme scriptini çalıştırma satırını kaldırın veya yorum satırı yapın!
  // await updateAllDocumentLocations();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Proje Takip Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().userChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // Kullanıcı giriş yapmışsa ProjectListScreen'e yönlendir
            return  HomeScreen();
          }
          // Kullanıcı giriş yapmamışsa AuthScreen'e yönlendir
          return const AuthScreen();
        },
      ),
    );
  }
}