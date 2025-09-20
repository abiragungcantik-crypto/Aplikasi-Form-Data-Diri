import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/siswa_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ouvferynqpgfaiylnxex.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im91dmZlcnlucXBnZmFpeWxueGV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTM4NTQsImV4cCI6MjA3MzQ4OTg1NH0.Bdf1lN247jcJFRhpGegE8DVFc8dOo7cHKsamTRgoJFg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Data Siswa',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SiswaListPage(),
    );
  }
}
