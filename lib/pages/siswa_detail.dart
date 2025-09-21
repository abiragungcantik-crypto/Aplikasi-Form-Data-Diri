import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class SiswaDetailPage extends StatelessWidget {
  final Map<String, dynamic> siswa;
  const SiswaDetailPage({super.key, required this.siswa});

  Widget _buildDetailRow(String label, dynamic value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 2),
              child: Icon(icon, size: 18, color: Colors.blueAccent.shade700),
            ),
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? "-",
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(thickness: 1.2),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          siswa['nama'] ?? 'Detail Siswa',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blueAccent.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<Map<String, dynamic>>(
          future: supabaseService.getSiswaById(siswa['id'].toString()),
          builder: (context, siswaSnapshot) {
            if (siswaSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              );
            }
            if (siswaSnapshot.hasError) {
              return Center(
                child: Text(
                  'Gagal memuat data siswa: ${siswaSnapshot.error}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.redAccent,
                  ),
                ),
              );
            }
            final siswaData = siswaSnapshot.data ?? siswa;

            return FutureBuilder<Map<String, dynamic>?>(
              future: supabaseService.getOrangTuaById(siswa['id'].toString()),
              builder: (context, orangTuaSnapshot) {
                if (orangTuaSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  );
                }
                if (orangTuaSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat data orang tua: ${orangTuaSnapshot.error}',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.redAccent,
                      ),
                    ),
                  );
                }
                final orangTuaData = orangTuaSnapshot.data;

                return ListView(
                  children: [
                    _buildSection("Data Siswa", [
                      _buildDetailRow('Nama', siswaData['nama'], icon: Icons.person),
                      _buildDetailRow('NISN', siswaData['nisn'], icon: Icons.badge),
                      _buildDetailRow('Jenis Kelamin', siswaData['jenis_kelamin'], icon: Icons.wc),
                      _buildDetailRow('Agama', siswaData['agama'], icon: Icons.account_balance),
                      _buildDetailRow('Tempat, Tanggal Lahir', siswaData['ttl'], icon: Icons.cake),
                      _buildDetailRow('No. HP', siswaData['no_hp'], icon: Icons.phone),
                      _buildDetailRow('NIK', siswaData['nik'], icon: Icons.credit_card),
                      _buildDetailRow('Jalan', siswaData['jalan'], icon: Icons.signpost),
                      _buildDetailRow('RT/RW', siswaData['rt_rw'], icon: Icons.home_work),
                      _buildDetailRow('Dusun', siswaData['dusun'], icon: Icons.maps_home_work),
                      _buildDetailRow('Desa', siswaData['desa'], icon: Icons.villa),
                      _buildDetailRow('Kecamatan', siswaData['kecamatan'], icon: Icons.location_city),
                      _buildDetailRow('Kabupaten', siswaData['kabupaten'], icon: Icons.apartment),
                      _buildDetailRow('Provinsi', siswaData['provinsi'], icon: Icons.public),
                      _buildDetailRow('Kode Pos', siswaData['kode_pos'], icon: Icons.markunread_mailbox),
                    ]),
                    _buildSection("Data Orang Tua", [
                      if (orangTuaData != null) ...[
                        _buildDetailRow('Nama Ayah', orangTuaData['nama_ayah'], icon: Icons.male),
                        _buildDetailRow('Nama Ibu', orangTuaData['nama_ibu'], icon: Icons.female),
                        _buildDetailRow('Nama Wali', orangTuaData['nama_wali'], icon: Icons.group),
                        _buildDetailRow('Jalan', orangTuaData['jalan'], icon: Icons.signpost),
                        _buildDetailRow('RT/RW', orangTuaData['rt_rw'], icon: Icons.home_work),
                        _buildDetailRow('Dusun', orangTuaData['dusun'], icon: Icons.maps_home_work),
                        _buildDetailRow('Desa', orangTuaData['desa'], icon: Icons.villa),
                        _buildDetailRow('Kecamatan', orangTuaData['kecamatan'], icon: Icons.location_city),
                        _buildDetailRow('Kabupaten', orangTuaData['kabupaten'], icon: Icons.apartment),
                        _buildDetailRow('Provinsi', orangTuaData['provinsi'], icon: Icons.public),
                        _buildDetailRow('Kode Pos', orangTuaData['kode_pos'], icon: Icons.markunread_mailbox),
                      ] else
                        _buildDetailRow('Data Orang Tua', 'Tidak tersedia', icon: Icons.info_outline),
                    ]),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
