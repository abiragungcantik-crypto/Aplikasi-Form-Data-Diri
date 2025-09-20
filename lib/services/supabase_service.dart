import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getSiswa() async {
    final response = await supabase.from('siswa').select().order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addSiswa(Map<String, dynamic> data) async {
    await supabase.from('siswa').insert(data);
  }

  Future<void> updateSiswa(String id, Map<String, dynamic> data) async {
    await supabase.from('siswa').update(data).eq('id', id);
  }

  Future<void> deleteSiswa(String id) async {
    await supabase.from('siswa').delete().eq('id', id);
  }

  Future fetchDusunList() async {}

  Future fetchAddressByDusun(String dusun) async {}
}
