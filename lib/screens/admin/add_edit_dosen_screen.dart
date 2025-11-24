import 'package:flutter/material.dart';

class AddEditDosenScreen extends StatefulWidget {
  const AddEditDosenScreen({super.key});

  @override
  State<AddEditDosenScreen> createState() => _AddEditDosenScreenState();
}

class _AddEditDosenScreenState extends State<AddEditDosenScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _departemenController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _nipController.dispose();
    _departemenController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      // Kembalikan data ke layar pemanggil. Di sini Anda bisa memanggil service API.
      Navigator.of(context).pop<Map<String, String>>({
        'nama': _namaController.text.trim(),
        'nip': _nipController.text.trim(),
        'departemen': _departemenController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Dosen'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nipController,
                decoration: const InputDecoration(labelText: 'NIP / NIDN'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'NIP/NIDN wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departemenController,
                decoration: const InputDecoration(
                  labelText: 'Departemen / Prodi',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Departemen wajib diisi'
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _onSave,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
