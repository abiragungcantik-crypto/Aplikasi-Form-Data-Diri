import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:aplikasi_form_data_diri_siswa/pages/siswa_detail.dart';
import 'package:aplikasi_form_data_diri_siswa/pages/siswa_edit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import 'siswa_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> siswa = [];
  bool _isLoading = false;
  bool _isDeleting = false;
  StreamSubscription<ConnectivityResult>? _connectionSubscription;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectionAndLoadData();

    _connectionSubscription = Connectivity().onConnectivityChanged
        .map(
          (event) => event.isNotEmpty ? event.first : ConnectivityResult.none,
        )
        .listen((result) {
          if (result == ConnectivityResult.none) {
            _showNoConnectionDialog();
          } else if (result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile) {
            if (!_isLoading && mounted) {
              _loadData(showSuccessMessage: true);
            }
          }
        });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectionAndLoadData() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await _showNoConnectionDialog();
    } else {
      await _loadData();
    }
  }

  Future<void> _showNoConnectionDialog() async {
    if (!mounted || _isDialogShowing) return;
    setState(() => _isDialogShowing = true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              "Tidak Ada Koneksi",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "Periksa koneksi internet Anda dan coba lagi.",
          style: GoogleFonts.roboto(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final connectivityResult = await Connectivity()
                  .checkConnectivity();
              if (connectivityResult != ConnectivityResult.none) {
                await _loadData(showSuccessMessage: true);
              } else {
                await _showNoConnectionDialog();
              }
            },
            child: Text(
              "Coba Lagi",
              style: GoogleFonts.roboto(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Tutup",
              style: GoogleFonts.roboto(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() => _isDialogShowing = false);
    }
  }

  Future<void> _loadData({bool showSuccessMessage = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        await _showNoConnectionDialog();
        return;
      }

      final data = await _service.getSiswa(
        fields: [
          'id',
          'nisn',
          'nama',
          'jenis_kelamin',
          'agama',
          'ttl',
          'no_hp',
          'nik',
          'jalan',
          'rt_rw',
          'dusun',
          'desa',
          'kecamatan',
          'kabupaten',
          'provinsi',
          'kode_pos',
          'alamat_id',
          'orang_tua_id',
        ],
      );

      if (mounted) {
        setState(() {
          siswa = data;
        });
        if (showSuccessMessage && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Data berhasil dimuat ulang"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } on SocketException {
      if (mounted) {
        await _showNoConnectionDialog();
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Gagal memuat data. Periksa koneksi internet anda.",
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete(String id, String nama, String nisn) async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        await _showNoConnectionDialog();
        return;
      }

      await _service.deleteSiswa(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Siswa '$nama' (NISN: $nisn) berhasil dihapus"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on SocketException {
      if (mounted) {
        await _showNoConnectionDialog();
      }
    } catch (e) {
      debugPrint("Error deleting data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus siswa: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _confirmDelete(String id, String nama, String nisn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              "Konfirmasi Hapus",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus data siswa '$nama' (NISN: $nisn)?",
          style: GoogleFonts.roboto(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: GoogleFonts.roboto(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Hapus",
              style: GoogleFonts.roboto(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _delete(id, nama, nisn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Data Siswa",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadData(showSuccessMessage: true),
          ),
        ],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : siswa.isEmpty
          ? Center(
              child: Text(
                "Belum ada data siswa",
                style: GoogleFonts.roboto(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: siswa.length,
              itemBuilder: (context, index) {
                final item = siswa[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        item['nama'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      item['nama'],
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text("NISN: ${item['nisn']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SiswaDetailPage(siswa: item),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SiswaEditPage(siswa: item),
                              ),
                            ).then((_) => _loadData());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _isDeleting
                              ? null
                              : () => _confirmDelete(
                                  item['id'].toString(),
                                  item['nama'],
                                  item['nisn'],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SiswaFormPage()),
          ).then((_) => _loadData());
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
