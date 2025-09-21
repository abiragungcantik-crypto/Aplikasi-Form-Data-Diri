import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaEditPage extends StatefulWidget {
  final Map<String, dynamic> siswa; // Required for editing
  const SiswaEditPage({super.key, required this.siswa});

  @override
  State<SiswaEditPage> createState() => _SiswaEditPageState();
}

class _SiswaEditPageState extends State<SiswaEditPage> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, TextEditingController> _controllers = {};
  String? _jenisKelamin;
  String? _agama;
  late final TextEditingController _tempatLahirController;
  late final TextEditingController _tanggalLahirController;
  final TextEditingController _dusunSiswaController = TextEditingController();
  final TextEditingController _dusunWaliController = TextEditingController();
  String? _selectedDusunSiswa;
  String? _selectedDusunWali;
  List<Map<String, dynamic>> _dusunList = [];
  bool _isLoadingDusun = true;
  bool _isLoadingSiswaAddress = false;
  bool _isLoadingWaliAddress = false;
  bool _hasDusunError = false;
  bool _isSaving = false;
  String? _dateError; // To store date parsing error

  final List<String> _listJenisKelamin = ["Laki-laki", "Perempuan"];
  final List<String> _listAgama = [
    "Islam",
    "Kristen",
    "Katolik",
    "Hindu",
    "Buddha",
    "Konghucu",
    "Lainnya"
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFormData();
    _fetchDusunList();
  }

  void _initializeControllers() {
    final fields = [
      'nisn',
      'nama',
      'no_hp',
      'nik',
      'jalan_siswa',
      'rt_rw_siswa',
      'desa_siswa',
      'kecamatan_siswa',
      'kabupaten_siswa',
      'provinsi_siswa',
      'kode_pos_siswa',
      'nama_ayah',
      'nama_ibu',
      'nama_wali',
      'jalan_wali',
      'rt_rw_wali',
      'desa_wali',
      'kecamatan_wali',
      'kabupaten_wali',
      'provinsi_wali',
      'kode_pos_wali',
    ];
    for (var f in fields) {
      _controllers[f] = TextEditingController(text: widget.siswa[f.replaceAll('_siswa', '').replaceAll('_wali', '')]?.toString() ?? '');
    }

    // Initialize tempat and tanggal lahir controllers
    String tempat = '';
    String tanggal = '';
    if (widget.siswa['ttl'] != null && widget.siswa['ttl'].toString().isNotEmpty) {
      final ttlParts = widget.siswa['ttl'].toString().split(', ');
      if (ttlParts.length >= 2) {
        tempat = ttlParts[0].trim();
        tanggal = ttlParts[1].trim();
        // Validate date format
        try {
          DateTime.parse(tanggal);
          _dateError = null;
        } catch (e) {
          debugPrint('Error parsing date: $e');
          _dateError = 'Format tanggal lahir tidak valid: $tanggal';
        }
      } else {
        tempat = widget.siswa['ttl'].toString().trim();
        _dateError = 'Data tanggal lahir tidak lengkap';
      }
    } else {
      _dateError = 'Data tempat dan tanggal lahir kosong';
    }

    _tempatLahirController = TextEditingController(text: tempat);
    _tanggalLahirController = TextEditingController(text: tanggal);

    // Show SnackBar for date error
    if (_dateError != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_dateError!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
  }

  void _initializeFormData() async {
    _jenisKelamin = widget.siswa['jenis_kelamin']?.toString();
    _agama = widget.siswa['agama']?.toString();
    _selectedDusunSiswa = widget.siswa['dusun']?.toString();
    _dusunSiswaController.text = widget.siswa['dusun']?.toString() ?? '';

    _controllers['desa_siswa']?.text = widget.siswa['desa']?.toString() ?? '';
    _controllers['kecamatan_siswa']?.text = widget.siswa['kecamatan']?.toString() ?? '';
    _controllers['kabupaten_siswa']?.text = widget.siswa['kabupaten']?.toString() ?? '';
    _controllers['provinsi_siswa']?.text = widget.siswa['provinsi']?.toString() ?? '';
    _controllers['kode_pos_siswa']?.text = widget.siswa['kode_pos']?.toString() ?? '';

    if (widget.siswa['orang_tua_id'] != null) {
      await _fetchParentData(widget.siswa['orang_tua_id']);
    }
  }

  Future<void> _fetchParentData(int orangTuaId) async {
    try {
      final response = await _supabase
          .from('orang_tua')
          .select('*')
          .eq('id', orangTuaId)
          .maybeSingle();

      if (response != null) {
        _controllers['nama_ayah']?.text = response['nama_ayah']?.toString() ?? '';
        _controllers['nama_ibu']?.text = response['nama_ibu']?.toString() ?? '';
        _controllers['nama_wali']?.text = response['nama_wali']?.toString() ?? '';
        _controllers['jalan_wali']?.text = response['jalan']?.toString() ?? '';
        _controllers['rt_rw_wali']?.text = response['rt_rw']?.toString() ?? '';
        _controllers['desa_wali']?.text = response['desa']?.toString() ?? '';
        _controllers['kecamatan_wali']?.text = response['kecamatan']?.toString() ?? '';
        _controllers['kabupaten_wali']?.text = response['kabupaten']?.toString() ?? '';
        _controllers['provinsi_wali']?.text = response['provinsi']?.toString() ?? '';
        _controllers['kode_pos_wali']?.text = response['kode_pos']?.toString() ?? '';
        _selectedDusunWali = response['dusun']?.toString();
        _dusunWaliController.text = response['dusun']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching parent data: $e');
    }
  }

  Future<void> _fetchDusunList() async {
    setState(() {
      _isLoadingDusun = true;
      _hasDusunError = false;
    });

    try {
      final response = await _supabase
          .from('alamat')
          .select('id, dusun')
          .not('dusun', 'is', null)
          .order('dusun', ascending: true);

      setState(() {
        _dusunList = response
            ?.where((e) => e['dusun'].toString().trim().isNotEmpty)
            .toList() ?? [];
        _isLoadingDusun = false;
      });

      debugPrint('Fetched ${_dusunList.length} dusun records: $_dusunList');

      if (_selectedDusunSiswa != null && _selectedDusunSiswa!.isNotEmpty) {
        await _fetchAddressDetails(_selectedDusunSiswa!, isSiswa: true);
      }
      if (_selectedDusunWali != null && _selectedDusunWali!.isNotEmpty) {
        await _fetchAddressDetails(_selectedDusunWali!, isSiswa: false);
      }
    } catch (e) {
      debugPrint('Error fetching dusun list: $e');
      setState(() {
        _dusunList = [];
        _isLoadingDusun = false;
        _hasDusunError = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(child: Text('Gagal memuat daftar dusun. Gunakan input manual.')),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _fetchDusunList,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Coba lagi",
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _fetchDusunList,
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchAddressDetails(String dusun, {required bool isSiswa}) async {
    setState(() {
      if (isSiswa) {
        _isLoadingSiswaAddress = true;
      } else {
        _isLoadingWaliAddress = true;
      }
    });

    try {
      final response = await _supabase
          .from('alamat')
          .select('id, dusun, desa, kecamatan, kabupaten, provinsi, kode_pos')
          .eq('dusun', dusun)
          .maybeSingle();

      setState(() {
        if (response != null) {
          if (isSiswa) {
            _controllers['desa_siswa']?.text = response['desa']?.toString() ?? '';
            _controllers['kecamatan_siswa']?.text = response['kecamatan']?.toString() ?? '';
            _controllers['kabupaten_siswa']?.text = response['kabupaten']?.toString() ?? '';
            _controllers['provinsi_siswa']?.text = response['provinsi']?.toString() ?? '';
            _controllers['kode_pos_siswa']?.text = response['kode_pos']?.toString() ?? '';
            _selectedDusunSiswa = dusun;
          } else {
            _controllers['desa_wali']?.text = response['desa']?.toString() ?? '';
            _controllers['kecamatan_wali']?.text = response['kecamatan']?.toString() ?? '';
            _controllers['kabupaten_wali']?.text = response['kabupaten']?.toString() ?? '';
            _controllers['provinsi_wali']?.text = response['provinsi']?.toString() ?? '';
            _controllers['kode_pos_wali']?.text = response['kode_pos']?.toString() ?? '';
            _selectedDusunWali = dusun;
          }
        } else {
          if (isSiswa) {
            _clearSiswaAddressFields();
            _selectedDusunSiswa = null;
          } else {
            _clearWaliAddressFields();
            _selectedDusunWali = null;
          }
        }
        if (isSiswa) {
          _isLoadingSiswaAddress = false;
        } else {
          _isLoadingWaliAddress = false;
        }
      });

      debugPrint('Address details loaded for dusun: $dusun (isSiswa: $isSiswa) - $response');
    } catch (e) {
      debugPrint('Error fetching address details: $e');
      setState(() {
        if (isSiswa) {
          _isLoadingSiswaAddress = false;
          _clearSiswaAddressFields();
          _selectedDusunSiswa = null;
        } else {
          _isLoadingWaliAddress = false;
          _clearWaliAddressFields();
          _selectedDusunWali = null;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detail alamat untuk "$dusun" tidak ditemukan di database.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => _fetchAddressDetails(dusun, isSiswa: isSiswa),
            ),
          ),
        );
      }
    }
  }

  void _clearSiswaAddressFields() {
    _controllers['desa_siswa']?.clear();
    _controllers['kecamatan_siswa']?.clear();
    _controllers['kabupaten_siswa']?.clear();
    _controllers['provinsi_siswa']?.clear();
    _controllers['kode_pos_siswa']?.clear();
  }

  void _clearWaliAddressFields() {
    _controllers['desa_wali']?.clear();
    _controllers['kecamatan_wali']?.clear();
    _controllers['kabupaten_wali']?.clear();
    _controllers['provinsi_wali']?.clear();
    _controllers['kode_pos_wali']?.clear();
  }

  Future<int> _saveOrangTua(Map<String, dynamic> data, {int? existingId}) async {
    try {
      final orangTuaData = {
        'nama_ayah': data['nama_ayah'] ?? '',
        'nama_ibu': data['nama_ibu'] ?? '',
        'nama_wali': data['nama_wali'],
        'jalan': data['jalan_wali'] ?? '',
        'rt_rw': data['rt_rw_wali'] ?? '',
        'dusun': data['dusun_wali'] ?? '',
        'desa': data['desa_wali'] ?? '',
        'kecamatan': data['kecamatan_wali'] ?? '',
        'kabupaten': data['kabupaten_wali'] ?? '',
        'provinsi': data['provinsi_wali'] ?? '',
        'kode_pos': data['kode_pos_wali'] ?? '',
        'alamat_id': data['alamat_id_wali'],
      };

      if (existingId == null) {
        final response = await _supabase.from('orang_tua').insert(orangTuaData).select('id').single();
        return response['id'] as int;
      } else {
        await _supabase.from('orang_tua').update(orangTuaData).eq('id', existingId);
        return existingId;
      }
    } catch (e) {
      debugPrint('Error saving orang_tua: $e');
      rethrow;
    }
  }

  Future<void> _updateSiswa(String id, Map<String, dynamic> data) async {
    try {
      final existingOrangTuaId = widget.siswa['orang_tua_id'];
      final orangTuaId = await _saveOrangTua(data, existingId: existingOrangTuaId);

      final updateData = {
        'nisn': data['nisn'],
        'nama': data['nama'],
        'jenis_kelamin': data['jenis_kelamin'],
        'agama': data['agama'],
        'ttl': data['ttl'],
        'no_hp': data['no_hp'],
        'nik': data['nik'],
        'jalan': data['jalan_siswa'],
        'rt_rw': data['rt_rw_siswa'],
        'dusun': data['dusun_siswa'],
        'desa': data['desa_siswa'],
        'kecamatan': data['kecamatan_siswa'],
        'kabupaten': data['kabupaten_siswa'],
        'provinsi': data['provinsi_siswa'],
        'kode_pos': data['kode_pos_siswa'],
        'alamat_id': data['alamat_id_siswa'],
        'orang_tua_id': orangTuaId,
      };

      final response = await _supabase
          .from('siswa')
          .update(updateData)
          .eq('id', id);
      debugPrint('Siswa updated successfully: $response');
    } catch (e) {
      debugPrint('Error updating siswa: $e');
      rethrow;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    if (_formKey.currentState!.validate()) {
      final dusunSiswaValue = _dusunSiswaController.text.trim();
      final dusunWaliValue = _dusunWaliController.text.trim();
      final noHpValue = _controllers['no_hp']!.text.trim();
      final nikValue = _controllers['nik']!.text.trim();
      final rtRwSiswaValue = _controllers['rt_rw_siswa']!.text.trim();
      final rtRwWaliValue = _controllers['rt_rw_wali']!.text.trim();
      final jalanSiswaValue = _controllers['jalan_siswa']!.text.trim();
      final jalanWaliValue = _controllers['jalan_wali']!.text.trim();
      final tempatLahirValue = _tempatLahirController.text.trim();
      final tanggalLahirValue = _tanggalLahirController.text.trim();

      // Additional validations
      if (dusunSiswaValue.isEmpty || dusunWaliValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dusun siswa dan wali wajib diisi')),
        );
        return;
      }

      if (tempatLahirValue.isEmpty || tanggalLahirValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tempat dan tanggal lahir wajib diisi')),
        );
        return;
      }

      // Validate date format
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(tanggalLahirValue)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal lahir harus dalam format YYYY-MM-DD')),
        );
        return;
      }

      try {
        DateTime.parse(tanggalLahirValue);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tanggal lahir tidak valid: $e')),
        );
        return;
      }

      if (noHpValue.length < 12 || noHpValue.length > 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor HP harus antara 12 hingga 15 digit')),
        );
        return;
      }

      if (nikValue.length != 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NIK harus tepat 16 digit')),
        );
        return;
      }

      if (jalanSiswaValue.isEmpty || jalanWaliValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jalan untuk siswa dan wali wajib diisi')),
        );
        return;
      }

      if (!RegExp(r'^\d+/\d+$').hasMatch(rtRwSiswaValue) || !RegExp(r'^\d+/\d+$').hasMatch(rtRwWaliValue)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RT/RW harus dalam format XX/YY (contoh: 66/07)')),
        );
        return;
      }

      if (_controllers['nama_ayah']!.text.trim().isEmpty ||
          _controllers['nama_ibu']!.text.trim().isEmpty ||
          _controllers['rt_rw_wali']!.text.trim().isEmpty ||
          _controllers['desa_wali']!.text.trim().isEmpty ||
          _controllers['kecamatan_wali']!.text.trim().isEmpty ||
          _controllers['kabupaten_wali']!.text.trim().isEmpty ||
          _controllers['provinsi_wali']!.text.trim().isEmpty ||
          _controllers['kode_pos_wali']!.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nama ayah, nama ibu, dan semua kolom alamat wali wajib diisi')),
        );
        return;
      }

      setState(() => _isSaving = true);

      int? alamatIdSiswa;
      if (dusunSiswaValue.isNotEmpty) {
        final alamatResponse = await _supabase
            .from('alamat')
            .select('id')
            .eq('dusun', dusunSiswaValue)
            .maybeSingle();
        if (alamatResponse != null) {
          alamatIdSiswa = alamatResponse['id'];
        }
      }

      int? alamatIdWali;
      if (dusunWaliValue.isNotEmpty) {
        final alamatResponse = await _supabase
            .from('alamat')
            .select('id')
            .eq('dusun', dusunWaliValue)
            .maybeSingle();
        if (alamatResponse != null) {
          alamatIdWali = alamatResponse['id'];
        }
      }

      final data = {
        'nisn': _controllers['nisn']?.text.trim(),
        'nama': _controllers['nama']?.text.trim(),
        'no_hp': _controllers['no_hp']?.text.trim(),
        'nik': _controllers['nik']?.text.trim(),
        'jalan_siswa': _controllers['jalan_siswa']?.text.trim(),
        'rt_rw_siswa': _controllers['rt_rw_siswa']?.text.trim(),
        'dusun_siswa': dusunSiswaValue,
        'desa_siswa': _controllers['desa_siswa']?.text.trim(),
        'kecamatan_siswa': _controllers['kecamatan_siswa']?.text.trim(),
        'kabupaten_siswa': _controllers['kabupaten_siswa']?.text.trim(),
        'provinsi_siswa': _controllers['provinsi_siswa']?.text.trim(),
        'kode_pos_siswa': _controllers['kode_pos_siswa']?.text.trim(),
        'alamat_id_siswa': alamatIdSiswa,
        'nama_ayah': _controllers['nama_ayah']?.text.trim(),
        'nama_ibu': _controllers['nama_ibu']?.text.trim(),
        'nama_wali': _controllers['nama_wali']!.text.trim().isNotEmpty
            ? _controllers['nama_wali']?.text.trim()
            : null,
        'jalan_wali': _controllers['jalan_wali']?.text.trim(),
        'rt_rw_wali': _controllers['rt_rw_wali']?.text.trim(),
        'dusun_wali': dusunWaliValue,
        'desa_wali': _controllers['desa_wali']?.text.trim(),
        'kecamatan_wali': _controllers['kecamatan_wali']?.text.trim(),
        'kabupaten_wali': _controllers['kabupaten_wali']?.text.trim(),
        'provinsi_wali': _controllers['provinsi_wali']?.text.trim(),
        'kode_pos_wali': _controllers['kode_pos_wali']?.text.trim(),
        'alamat_id_wali': alamatIdWali,
        'jenis_kelamin': _jenisKelamin,
        'agama': _agama,
        'ttl': '$tempatLahirValue, $tanggalLahirValue',
      };

      try {
        await _updateSiswa(widget.siswa['id'].toString(), data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data siswa berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Save error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Widget _buildField(String key, String label, {Widget? suffixIcon, bool isWali = false}) {
    final isAddressField = [
      'desa_siswa',
      'kecamatan_siswa',
      'kabupaten_siswa',
      'provinsi_siswa',
      'kode_pos_siswa',
      'desa_wali',
      'kecamatan_wali',
      'kabupaten_wali',
      'provinsi_wali',
      'kode_pos_wali',
    ].contains(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          hintText: key == 'rt_rw_siswa' || key == 'rt_rw_wali' ? 'Contoh: 66/07' : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: isAddressField && (isWali ? _selectedDusunWali != null : _selectedDusunSiswa != null)
              ? Colors.grey[200]
              : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: suffixIcon,
          enabled: !isAddressField || (isWali ? _selectedDusunWali == null : _selectedDusunSiswa == null),
          prefixIcon: key == 'no_hp'
              ? const Icon(Icons.phone)
              : key == 'nik'
                  ? const Icon(Icons.fingerprint)
                  : null,
        ),
        validator: (value) {
          final trimmedValue = value?.trim() ?? '';
          if (isAddressField && (isWali ? _selectedDusunWali != null : _selectedDusunSiswa != null)) {
            return null;
          }
          if (key == 'nisn') {
            if (trimmedValue.isEmpty) {
              return "NISN wajib diisi";
            }
            if (trimmedValue.length != 10) {
              return "NISN harus tepat 10 digit";
            }
            return null;
          }
          if (key == 'no_hp') {
            if (trimmedValue.isEmpty) {
              return "Nomor HP wajib diisi";
            }
            if (trimmedValue.length < 12 || trimmedValue.length > 15) {
              return "Nomor HP harus antara 12 hingga 15 digit";
            }
            return null;
          }
          if (key == 'nik') {
            if (trimmedValue.isEmpty) {
              return "NIK wajib diisi";
            }
            if (trimmedValue.length != 16) {
              return "NIK harus tepat 16 digit";
            }
            return null;
          }
          if (key == 'jalan_siswa' || key == 'jalan_wali') {
            if (trimmedValue.isEmpty) {
              return "Jalan wajib diisi";
            }
            return null;
          }
          if (key == 'rt_rw_siswa' || key == 'rt_rw_wali') {
            if (trimmedValue.isEmpty) {
              return "RT/RW wajib diisi";
            }
            if (!RegExp(r'^\d+/\d+$').hasMatch(trimmedValue)) {
              return "RT/RW harus dalam format XX/YY (contoh: 66/07)";
            }
            return null;
          }
          if ((key == 'nama' || key == 'nama_ayah' || key == 'nama_ibu' ||
                  (isWali && (key == 'rt_rw_wali' || isAddressField))) &&
              trimmedValue.isEmpty) {
            return "$label wajib diisi";
          }
          return null;
        },
        readOnly: isAddressField && (isWali ? _selectedDusunWali != null : _selectedDusunSiswa != null),
        inputFormatters: key == 'nisn'
            ? [FilteringTextInputFormatter.digitsOnly]
            : key == 'no_hp'
                ? [FilteringTextInputFormatter.digitsOnly]
                : key == 'nik'
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : key == 'rt_rw_siswa' || key == 'rt_rw_wali'
                        ? [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                            LengthLimitingTextInputFormatter(7),
                          ]
                        : null,
        keyboardType: key == 'no_hp' || key == 'nik'
            ? TextInputType.number
            : key == 'rt_rw_siswa' || key == 'rt_rw_wali'
                ? TextInputType.text
                : TextInputType.text,
      ),
    );
  }

  Widget _buildDusunField({required bool isSiswa}) {
    final controller = isSiswa ? _dusunSiswaController : _dusunWaliController;
    final selectedDusun = isSiswa ? _selectedDusunSiswa : _selectedDusunWali;
    final isLoadingAddress = isSiswa ? _isLoadingSiswaAddress : _isLoadingWaliAddress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          final input = textEditingValue.text.trim().toLowerCase();
          if (_isLoadingDusun || _hasDusunError) {
            return const Iterable<String>.empty();
          }
          return _dusunList
              .where((item) {
                final dusun = item['dusun']?.toString().toLowerCase() ?? '';
                return dusun.contains(input);
              })
              .map((item) => item['dusun'].toString())
              .toList();
        },
        onSelected: (String selection) async {
          setState(() {
            if (isSiswa) {
              _selectedDusunSiswa = selection;
              _dusunSiswaController.text = selection;
              _isLoadingSiswaAddress = true;
            } else {
              _selectedDusunWali = selection;
              _dusunWaliController.text = selection;
              _isLoadingWaliAddress = true;
            }
          });
          await _fetchAddressDetails(selection, isSiswa: isSiswa);
        },
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          if (textEditingController.text != controller.text) {
            textEditingController.text = controller.text;
            textEditingController.selection = TextSelection.fromPosition(
              TextPosition(offset: textEditingController.text.length),
            );
          }

          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: isSiswa ? "Dusun Siswa *" : "Dusun Wali *",
              hintText: _hasDusunError
                  ? "Ketik nama dusun secara manual"
                  : _isLoadingDusun
                      ? "Memuat daftar dusun..."
                      : "Ketik untuk mencari dusun (contoh: Dusun I)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.location_city),
              suffixIcon: _isLoadingDusun || isLoadingAddress
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      ),
                    )
                  : null,
              errorMaxLines: 2,
            ),
            validator: (value) {
              if (_isLoadingDusun) return null;
              if (value == null || value.trim().isEmpty) {
                return isSiswa ? "Dusun siswa wajib diisi" : "Dusun wali wajib diisi";
              }
              return null;
            },
            onChanged: (value) {
              controller.text = value;
              final trimmedValue = value.trim();

              if (trimmedValue.isEmpty) {
                setState(() {
                  if (isSiswa) {
                    _selectedDusunSiswa = null;
                    _clearSiswaAddressFields();
                  } else {
                    _selectedDusunWali = null;
                    _clearWaliAddressFields();
                  }
                });
                return;
              }

              final exactMatch = _dusunList.firstWhere(
                (item) => item['dusun'].toString().toLowerCase() == trimmedValue.toLowerCase(),
                orElse: () => <String, dynamic>{},
              );

              if (exactMatch.isNotEmpty) {
                setState(() {
                  if (isSiswa) {
                    _selectedDusunSiswa = trimmedValue;
                    _isLoadingSiswaAddress = true;
                  } else {
                    _selectedDusunWali = trimmedValue;
                    _isLoadingWaliAddress = true;
                  }
                });
                _fetchAddressDetails(trimmedValue, isSiswa: isSiswa);
              } else {
                setState(() {
                  if (isSiswa) {
                    _selectedDusunSiswa = null;
                    _clearSiswaAddressFields();
                  } else {
                    _selectedDusunWali = null;
                    _clearWaliAddressFields();
                  }
                });
              }
            },
          );
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options,
        ) {
          if (options.isEmpty && !_isLoadingDusun) {
            return const SizedBox.shrink();
          }

          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(option)),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Siswa",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        shadowColor: Colors.blueAccent.withOpacity(0.5),
        actions: [
          if (!_isLoadingDusun && !_isLoadingSiswaAddress && !_isLoadingWaliAddress && !_isSaving)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white,),
              onPressed: _fetchDusunList,
              tooltip: "Refresh daftar dusun",
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Informasi Siswa",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        if (_isLoadingDusun)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildField('nisn', "NISN"),
                  _buildField('nama', "Nama Lengkap *"),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _jenisKelamin,
                      items: _listJenisKelamin
                          .map((jk) => DropdownMenuItem(value: jk, child: Text(jk)))
                          .toList(),
                      onChanged: (val) => setState(() => _jenisKelamin = val),
                      decoration: InputDecoration(
                        labelText: "Jenis Kelamin *",
                        prefixIcon: const Icon(Icons.wc),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => val == null ? "Jenis Kelamin wajib dipilih" : null,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _agama,
                      items: _listAgama
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) => setState(() => _agama = val),
                      decoration: InputDecoration(
                        labelText: "Agama *",
                        prefixIcon: const Icon(Icons.book),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => val == null ? "Agama wajib dipilih" : null,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextFormField(
                      controller: _tempatLahirController,
                      decoration: InputDecoration(
                        labelText: "Tempat Lahir *",
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Tempat lahir wajib diisi"
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextFormField(
                      controller: _tanggalLahirController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Tanggal Lahir *",
                        hintText: "Pilih tanggal (YYYY-MM-DD)",
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        errorText: _dateError,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _tanggalLahirController.text.isNotEmpty
                              ? DateTime.tryParse(_tanggalLahirController.text) ?? DateTime(2000)
                              : DateTime(2000),
                          firstDate: DateTime(1970),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.blueAccent,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _tanggalLahirController.text = picked.toIso8601String().split('T').first;
                            _dateError = null; // Clear error on user selection
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Tanggal lahir wajib diisi";
                        }
                        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
                          return "Tanggal lahir harus dalam format YYYY-MM-DD";
                        }
                        try {
                          DateTime.parse(value.trim());
                        } catch (e) {
                          return "Tanggal lahir tidak valid";
                        }
                        return null;
                      },
                    ),
                  ),

                  _buildField('no_hp', "No. HP *"),
                  _buildField('nik', "NIK *"),

                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Alamat Tinggal Siswa",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        if (_selectedDusunSiswa != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  "Otomatis",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  _buildField('jalan_siswa', "Jalan *"),
                  _buildField('rt_rw_siswa', "RT/RW *"),
                  _buildDusunField(isSiswa: true),
                  const SizedBox(height: 16),

                  if (_selectedDusunSiswa != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: Colors.green,
                            width: 4,
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green, size: 20),
                          SizedBox(width: 5),
                          Text(
                            "Alamat siswa diisi otomatis,\nberdasarkan dusun",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  _buildField(
                    'desa_siswa',
                    "Desa/Kelurahan",
                    suffixIcon: _isLoadingSiswaAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunSiswa != null
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                  ),
                  _buildField(
                    'kecamatan_siswa',
                    "Kecamatan",
                    suffixIcon: _isLoadingSiswaAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunSiswa != null
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                  ),
                  _buildField(
                    'kabupaten_siswa',
                    "Kabupaten/Kota",
                    suffixIcon: _isLoadingSiswaAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunSiswa != null
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                  ),
                  _buildField(
                    'provinsi_siswa',
                    "Provinsi",
                    suffixIcon: _isLoadingSiswaAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunSiswa != null
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                  ),
                  _buildField(
                    'kode_pos_siswa',
                    "Kode Pos",
                    suffixIcon: _isLoadingSiswaAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunSiswa != null
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                  ),

                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.family_restroom, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Informasi Orang Tua/Wali",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildField('nama_ayah', "Nama Ayah *"),
                  _buildField('nama_ibu', "Nama Ibu *"),
                  _buildField('nama_wali', "Nama Wali (opsional)"),

                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Alamat Tinggal Wali",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        if (_selectedDusunWali != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  "Otomatis",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  _buildField('jalan_wali', "Jalan *", isWali: true),
                  _buildField('rt_rw_wali', "RT/RW *", isWali: true),
                  _buildDusunField(isSiswa: false),
                  const SizedBox(height: 16),

                  if (_selectedDusunWali != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: Colors.orange,
                            width: 4,
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          SizedBox(width: 5),
                          Text(
                            "Alamat wali diisi otomatis,\nberdasarkan dusun",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  _buildField(
                    'desa_wali',
                    "Desa/Kelurahan",
                    isWali: true,
                    suffixIcon: _isLoadingWaliAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunWali != null
                            ? const Icon(Icons.check_circle, color: Colors.orange)
                            : null,
                  ),
                  _buildField(
                    'kecamatan_wali',
                    "Kecamatan",
                    isWali: true,
                    suffixIcon: _isLoadingWaliAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunWali != null
                            ? const Icon(Icons.check_circle, color: Colors.orange)
                            : null,
                  ),
                  _buildField(
                    'kabupaten_wali',
                    "Kabupaten/Kota",
                    isWali: true,
                    suffixIcon: _isLoadingWaliAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunWali != null
                            ? const Icon(Icons.check_circle, color: Colors.orange)
                            : null,
                  ),
                  _buildField(
                    'provinsi_wali',
                    "Provinsi",
                    isWali: true,
                    suffixIcon: _isLoadingWaliAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunWali != null
                            ? const Icon(Icons.check_circle, color: Colors.orange)
                            : null,
                  ),
                  _buildField(
                    'kode_pos_wali',
                    "Kode Pos",
                    isWali: true,
                    suffixIcon: _isLoadingWaliAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _selectedDusunWali != null
                            ? const Icon(Icons.check_circle, color: Colors.orange)
                            : null,
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (_isLoadingDusun || _isLoadingSiswaAddress || _isLoadingWaliAddress || _isSaving) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving ? "Menyimpan..." : "Update Data Siswa",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _dusunSiswaController.dispose();
    _dusunWaliController.dispose();
    super.dispose();
  }
}