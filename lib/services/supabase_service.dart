import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetch all siswa records with specified fields, ordered by created_at
  Future<List<Map<String, dynamic>>> getSiswa({required List<String> fields}) async {
    try {
      final response = await supabase
          .from('siswa')
          .select(fields.join(','))
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch siswa: $e');
    }
  }

  // Add a new siswa record
  Future<void> addSiswa(Map<String, dynamic> data) async {
    try {
      await supabase.from('siswa').insert(data);
    } catch (e) {
      throw Exception('Failed to add siswa: $e');
    }
  }

  // Update an existing siswa record by id
  Future<void> updateSiswa(String id, Map<String, dynamic> data) async {
    try {
      await supabase.from('siswa').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update siswa: $e');
    }
  }

  // Delete a siswa record and its related orang_tua and alamat records
  Future<void> deleteSiswa(String id) async {
    try {
      // Fetch the siswa record to get alamat_id and orang_tua_id
      final siswaResponse = await supabase
          .from('siswa')
          .select('alamat_id, orang_tua_id')
          .eq('id', id)
          .single();

      final alamatId = siswaResponse['alamat_id'];
      final orangTuaId = siswaResponse['orang_tua_id'];

      // Delete siswa record
      await supabase.from('siswa').delete().eq('id', id);

      // Delete orang_tua record if exists
      if (orangTuaId != null) {
        await supabase.from('orang_tua').delete().eq('id', orangTuaId);
      }

      // Delete alamat record if exists and not referenced elsewhere
      if (alamatId != null) {
        final alamatUsage = await supabase
            .from('siswa')
            .select('id')
            .eq('alamat_id', alamatId);
        final orangTuaUsage = await supabase
            .from('orang_tua')
            .select('id')
            .eq('alamat_id', alamatId);

        if (alamatUsage.isEmpty && orangTuaUsage.isEmpty) {
          await supabase.from('alamat').delete().eq('id', alamatId);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete siswa: $e');
    }
  }

  // Fetch list of unique dusun values from alamat table
  Future<List<String>> fetchDusunList() async {
    try {
      final response = await supabase
          .from('alamat')
          .select('dusun')
          .not('dusun', 'is', null)
          .order('dusun', ascending: true);
      final dusunList = List<String>.from(response.map((item) => item['dusun']).toSet());
      return dusunList;
    } catch (e) {
      throw Exception('Failed to fetch dusun list: $e');
    }
  }

  // Fetch address details by dusun
  Future<List<Map<String, dynamic>>> fetchAddressByDusun(String dusun) async {
    try {
      final response = await supabase
          .from('alamat')
          .select('id, dusun, desa, kecamatan, kabupaten, provinsi, kode_pos')
          .eq('dusun', dusun);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch address by dusun: $e');
    }
  }

  // Fetch siswa details by id
  Future<Map<String, dynamic>> getSiswaById(String id) async {
    try {
      final response = await supabase
          .from('siswa')
          .select('id, nisn, nama, jenis_kelamin, agama, ttl, no_hp, nik, jalan, rt_rw, dusun, desa, kecamatan, kabupaten, provinsi, kode_pos, alamat_id, orang_tua_id')
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch siswa by id: $e');
    }
  }

  // Fetch orang_tua details by siswa's orang_tua_id
  Future<Map<String, dynamic>?> getOrangTuaById(String siswaId) async {
    try {
      // First, get the orang_tua_id from the siswa record
      final siswaResponse = await supabase
          .from('siswa')
          .select('orang_tua_id')
          .eq('id', siswaId)
          .single();

      final orangTuaId = siswaResponse['orang_tua_id'];

      if (orangTuaId == null) {
        return null; // No orang_tua associated with this siswa
      }

      // Fetch the orang_tua record
      final response = await supabase
          .from('orang_tua')
          .select('id, nama_ayah, nama_ibu, nama_wali, rt_rw, dusun, desa, kecamatan, kabupaten, provinsi, kode_pos, alamat_id, jalan')
          .eq('id', orangTuaId)
          .single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch orang_tua by siswa id: $e');
    }
  }
}