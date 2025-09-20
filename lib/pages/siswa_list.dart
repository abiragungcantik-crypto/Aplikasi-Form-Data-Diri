import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import 'siswa_form.dart';

class SiswaListPage extends StatefulWidget {
  const SiswaListPage({super.key});

  @override
  State<SiswaListPage> createState() => _SiswaListPageState();
}

class _SiswaListPageState extends State<SiswaListPage> {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> siswa = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getSiswa();
      setState(() {
        siswa = data;
      });
    } catch (e) {
      debugPrint("Error load data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat data siswa")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(dynamic id) async {
    try {
      await _service.deleteSiswa(id);
      _loadData();
    } catch (e) {
      debugPrint("Error delete: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus data siswa")),
      );
    }
  }

  void _showSiswaDetails(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          item['nama_lengkap'] ?? "-",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.blueAccent.shade700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("NISN", item['nisn']),
              _buildDetailRow("Jenis Kelamin", item['jenis_kelamin']),
              _buildDetailRow("Agama", item['agama']),
              _buildDetailRow("Tempat, Tanggal Lahir", item['tempat_tanggal_lahir']),
              _buildDetailRow("No. Telp/HP", item['no_telp']),
              _buildDetailRow("NIK", item['nik']),
              const Divider(color: Colors.grey),
              Text(
                "Alamat",
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueAccent.shade700,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow("Jalan", item['alamat_jalan']),
              _buildDetailRow("RT/RW", item['alamat_rt_rw']),
              _buildDetailRow("Dusun", item['alamat_dusun']),
              _buildDetailRow("Desa", item['alamat_desa']),
              _buildDetailRow("Kecamatan", item['alamat_kecamatan']),
              _buildDetailRow("Kabupaten", item['alamat_kabupaten']),
              _buildDetailRow("Provinsi", item['alamat_provinsi']),
              _buildDetailRow("Kode Pos", item['alamat_kode_pos']),
              const Divider(color: Colors.grey),
              Text(
                "Orang Tua / Wali",
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueAccent.shade700,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow("Nama Ayah", item['nama_ayah']),
              _buildDetailRow("Nama Ibu", item['nama_ibu']),
              _buildDetailRow("Nama Wali", item['nama_wali']),
              _buildDetailRow("Alamat Wali", item['alamat_wali']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Tutup",
              style: GoogleFonts.roboto(
                color: Colors.blueAccent.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Data Siswa",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.shade700, Colors.blueAccent.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.blueAccent.withOpacity(0.4),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              )
            : siswa.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada data siswa",
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: siswa.length,
                    itemBuilder: (context, index) {
                      final item = siswa[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Dismissible(
                          key: ValueKey(item['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Konfirmasi Hapus',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Apakah Anda yakin ingin menghapus ${item['nama_lengkap'] ?? "-"}?',
                                  style: GoogleFonts.roboto(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Batal', style: GoogleFonts.roboto(color: Colors.grey.shade700)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Hapus', style: GoogleFonts.roboto(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                            return confirm ?? false;
                          },
                          onDismissed: (_) => _delete(item['id']),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.blueAccent.shade100,
                                child: Text(
                                  (item['nama_lengkap']?.toString()[0] ?? "?").toUpperCase(),
                                  style: GoogleFonts.roboto(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent.shade700,
                                  ),
                                ),
                              ),
                              title: Text(
                                item['nama_lengkap'] ?? "-",
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  "NISN: ${item['nisn'] ?? "-"}",
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              onTap: () => _showSiswaDetails(context, item),
                              trailing: IconButton(
                                icon: Icon(Icons.edit, color: Colors.blueAccent.shade700),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SiswaFormPage(siswa: item),
                                    ),
                                  );
                                  _loadData();
                                },
                                tooltip: 'Edit',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SiswaFormPage()),
          );
          _loadData();
        },
        backgroundColor: Colors.blueAccent.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
        tooltip: 'Tambah Siswa',
      ),
    );
  }
}
