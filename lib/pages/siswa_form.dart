import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SiswaFormPage extends StatefulWidget {
  final Map<String, dynamic>? siswa;
  const SiswaFormPage({super.key, this.siswa});

  @override
  State<SiswaFormPage> createState() => _SiswaFormPageState();
}

class _SiswaFormPageState extends State<SiswaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _service = SupabaseService();

  final Map<String, TextEditingController> _controllers = {};
  String? _jenisKelamin;
  String? _agama;
  DateTime? _tanggalLahir;
  final TextEditingController _tempatController = TextEditingController();
  final TextEditingController _dusunController = TextEditingController();
  String? _selectedDusun;
  List<String> _dusunList = [];
  bool _isLoadingDusun = true;
  bool _isLoadingAddress = false;

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
    final fields = [
      'nisn',
      'nama_lengkap',
      'no_telp',
      'nik',
      'alamat_jalan',
      'alamat_rt_rw',
      'alamat_desa',
      'alamat_kecamatan',
      'alamat_kabupaten',
      'alamat_provinsi',
      'alamat_kode_pos',
      'nama_ayah',
      'nama_ibu',
      'nama_wali',
      'alamat_wali'
    ];
    for (var f in fields) {
      _controllers[f] = TextEditingController(text: widget.siswa?[f] ?? '');
    }

    _jenisKelamin = widget.siswa?['jenis_kelamin'];
    _agama = widget.siswa?['agama'];
    _selectedDusun = widget.siswa?['alamat_dusun'];
    _dusunController.text = widget.siswa?['alamat_dusun'] ?? '';
    if (widget.siswa?['tempat_tanggal_lahir'] != null) {
      final ttl = widget.siswa!['tempat_tanggal_lahir'].split(', ');
      if (ttl.length == 2) {
        _tempatController.text = ttl[0];
        try {
          _tanggalLahir = DateTime.parse(ttl[1]);
        } catch (_) {}
      }
    }

    _fetchDusunList();
    if (_selectedDusun != null) {
      _fetchAddressDetails(_selectedDusun!);
    }
  }

  Future<void> _fetchDusunList() async {
    setState(() => _isLoadingDusun = true);
    try {
      final dusunData = await _service.fetchDusunList();
      setState(() {
        _dusunList = dusunData.map((e) => e['dusun'] as String).toList();
        _isLoadingDusun = false;
      });
    } catch (e) {
      setState(() => _isLoadingDusun = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar dusun: $e')),
      );
    }
  }

  Future<void> _fetchAddressDetails(String dusun) async {
    setState(() => _isLoadingAddress = true);
    try {
      final addressData = await _service.fetchAddressByDusun(dusun);
      setState(() {
        if (addressData != null) {
          _controllers['alamat_desa']?.text = addressData['desa'] ?? '';
          _controllers['alamat_kecamatan']?.text = addressData['kecamatan'] ?? '';
          _controllers['alamat_kabupaten']?.text = addressData['kabupaten'] ?? '';
          _controllers['alamat_provinsi']?.text = addressData['provinsi'] ?? '';
          _controllers['alamat_kode_pos']?.text = addressData['kode_pos'] ?? '';
          _selectedDusun = dusun; // Update selected dusun
        } else {
          // Clear fields if no address data is found
          _controllers['alamat_desa']?.text = '';
          _controllers['alamat_kecamatan']?.text = '';
          _controllers['alamat_kabupaten']?.text = '';
          _controllers['alamat_provinsi']?.text = '';
          _controllers['alamat_kode_pos']?.text = '';
          _selectedDusun = null;
        }
        _isLoadingAddress = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
        _controllers['alamat_desa']?.text = '';
        _controllers['alamat_kecamatan']?.text = '';
        _controllers['alamat_kabupaten']?.text = '';
        _controllers['alamat_provinsi']?.text = '';
        _controllers['alamat_kode_pos']?.text = '';
        _selectedDusun = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail alamat: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        for (var e in _controllers.entries) e.key: e.value.text,
        'jenis_kelamin': _jenisKelamin,
        'agama': _agama,
        'tempat_tanggal_lahir':
            "${_tempatController.text}, ${_tanggalLahir?.toIso8601String().split('T').first}",
        'alamat_dusun': _selectedDusun,
      };
      try {
        if (widget.siswa == null) {
          await _service.addSiswa(data);
        } else {
          await _service.updateSiswa(widget.siswa!['id'], data);
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
        );
      }
    }
  }

  Widget _buildField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
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
        validator: (value) =>
            value == null || value.isEmpty ? "$label tidak boleh kosong" : null,
        enabled: !['alamat_desa', 'alamat_kecamatan', 'alamat_kabupaten', 'alamat_provinsi', 'alamat_kode_pos']
            .contains(key), // Disable auto-populated fields
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.siswa == null ? "Tambah Siswa" : "Edit Siswa",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        shadowColor: Colors.blueAccent.withOpacity(0.5),
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
                  const Text(
                    "Informasi Pribadi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField('nisn', "NISN"),
                  _buildField('nama_lengkap', "Nama Lengkap"),
                  DropdownButtonFormField<String>(
                    value: _jenisKelamin,
                    items: _listJenisKelamin
                        .map((jk) => DropdownMenuItem(value: jk, child: Text(jk)))
                        .toList(),
                    onChanged: (val) => setState(() => _jenisKelamin = val),
                    decoration: InputDecoration(
                      labelText: "Jenis Kelamin",
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
                    validator: (val) =>
                        val == null ? "Jenis Kelamin tidak boleh kosong" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _agama,
                    items: _listAgama
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (val) => setState(() => _agama = val),
                    decoration: InputDecoration(
                      labelText: "Agama",
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
                    validator: (val) =>
                        val == null ? "Agama tidak boleh kosong" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tempatController,
                    decoration: InputDecoration(
                      labelText: "Tempat Lahir",
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
                    validator: (val) => val == null || val.isEmpty
                        ? "Tempat lahir wajib diisi"
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Tanggal Lahir",
                      hintText: _tanggalLahir == null
                          ? "Pilih tanggal"
                          : "${_tanggalLahir!.day}-${_tanggalLahir!.month}-${_tanggalLahir!.year}",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _tanggalLahir ?? DateTime(2000),
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
                              dialogBackgroundColor: Colors.white,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _tanggalLahir = picked);
                      }
                    },
                    validator: (_) => _tanggalLahir == null
                        ? "Tanggal lahir wajib diisi"
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField('no_telp', "No. Tlp/HP"),
                  _buildField('nik', "NIK"),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "Alamat",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField('alamat_jalan', "Jalan"),
                  _buildField('alamat_rt_rw', "RT/RW"),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _dusunList.where((String option) {
                        return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) async {
                      setState(() {
                        _selectedDusun = selection;
                        _dusunController.text = selection;
                        _isLoadingAddress = true;
                      });
                      await _fetchAddressDetails(selection);
                    },
                    fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      textEditingController.text = _dusunController.text;
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: "Dusun",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: _isLoadingDusun
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Dusun tidak boleh kosong";
                          }
                          if (!_dusunList.contains(value)) {
                            return "Dusun tidak valid";
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _dusunController.text = value;
                            if (_dusunList.contains(value)) {
                              _selectedDusun = value;
                              _fetchAddressDetails(value);
                            } else {
                              _selectedDusun = null;
                              _controllers['alamat_desa']?.text = '';
                              _controllers['alamat_kecamatan']?.text = '';
                              _controllers['alamat_kabupaten']?.text = '';
                              _controllers['alamat_provinsi']?.text = '';
                              _controllers['alamat_kode_pos']?.text = '';
                            }
                          });
                        },
                      );
                    },
                    optionsViewBuilder: (
                      BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options,
                    ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return GestureDetector(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: ListTile(
                                    title: Text(option),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      _buildField('alamat_desa', "Desa"),
                      if (_isLoadingAddress)
                        const Positioned(
                          right: 16,
                          top: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  Stack(
                    children: [
                      _buildField('alamat_kecamatan', "Kecamatan"),
                      if (_isLoadingAddress)
                        const Positioned(
                          right: 16,
                          top: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  Stack(
                    children: [
                      _buildField('alamat_kabupaten', "Kabupaten"),
                      if (_isLoadingAddress)
                        const Positioned(
                          right: 16,
                          top: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  Stack(
                    children: [
                      _buildField('alamat_provinsi', "Provinsi"),
                      if (_isLoadingAddress)
                        const Positioned(
                          right: 16,
                          top: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  Stack(
                    children: [
                      _buildField('alamat_kode_pos', "Kode Pos"),
                      if (_isLoadingAddress)
                        const Positioned(
                          right: 16,
                          top: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "Orang Tua / Wali",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField('nama_ayah', "Nama Ayah"),
                  _buildField('nama_ibu', "Nama Ibu"),
                  _buildField('nama_wali', "Nama Wali"),
                  _buildField('alamat_wali', "Alamat Wali"),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "Simpan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
    _tempatController.dispose();
    _dusunController.dispose();
    super.dispose();
  }
}