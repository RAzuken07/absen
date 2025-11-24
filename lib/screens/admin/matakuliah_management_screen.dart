// lib/screens/admin/matakuliah_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_model.dart';
import '../../services/admin_service.dart';
import '../../services/api_service.dart';
import '../../config/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';

// Provider untuk mengambil daftar Matakuliah
final matakuliahListProvider = FutureProvider.autoDispose<List<Matakuliah>>((ref) async {
  // Asumsi: adminServiceProvider sudah didefinisikan di lib/services/admin_service.dart
  final service = ref.watch(adminServiceProvider); 
  return service.getAllMatakuliah();
});

class MatakuliahManagementScreen extends ConsumerWidget {
  const MatakuliahManagementScreen({super.key});

  void _showAddEditForm(BuildContext context, WidgetRef ref, {Matakuliah? matakuliah}) {
    showDialog(
      context: context,
      builder: (ctx) => MatakuliahFormDialog(matakuliah: matakuliah, ref: ref),
    );
  }

  Future<void> _deleteMatakuliah(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus Matakuliah ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(adminServiceProvider).deleteMatakuliah(id);
        if(context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matakuliah berhasil dihapus!'), backgroundColor: Colors.green));
           // Muat ulang list setelah operasi berhasil
           ref.invalidate(matakuliahListProvider); 
        }
      } catch (e) {
        if(context.mounted) {
           String errorMessage = (e is ApiException) ? e.message : 'Gagal menghapus data.';
           showErrorDialog(context, 'Error Hapus', errorMessage);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matakuliahAsync = ref.watch(matakuliahListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Matakuliah'),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(matakuliahListProvider);
        },
        child: matakuliahAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            String message = (err is ApiException) ? err.message : 'Gagal memuat data Matakuliah.';
            return Center(child: Text('Error: $message', style: const TextStyle(color: Colors.red)));
          },
          data: (list) {
            if (list.isEmpty) {
              return const Center(child: Text('Belum ada data Matakuliah.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(DefaultPadding),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final mk = list[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Colors.blue),
                    title: Text(mk.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Kode: ${mk.kode} | SKS: ${mk.sks}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showAddEditForm(context, ref, matakuliah: mk),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMatakuliah(context, ref, mk.idMatakuliah),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditForm(context, ref),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Dialog Form untuk Tambah/Edit Matakuliah
class MatakuliahFormDialog extends ConsumerStatefulWidget {
  final Matakuliah? matakuliah;
  final WidgetRef ref;
  const MatakuliahFormDialog({super.key, this.matakuliah, required this.ref});

  @override
  ConsumerState<MatakuliahFormDialog> createState() => _MatakuliahFormDialogState();
}

class _MatakuliahFormDialogState extends ConsumerState<MatakuliahFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _kode;
  late String _nama;
  late int _sks;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _kode = widget.matakuliah?.kode ?? '';
    _nama = widget.matakuliah?.nama ?? '';
    _sks = widget.matakuliah?.sks ?? 3;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() { _isLoading = true; });

      try {
        final service = ref.read(adminServiceProvider);
        
        if (widget.matakuliah == null) {
          // Tambah
          await service.addMatakuliah(_kode, _nama, _sks);
        } else {
          // Edit
          await service.updateMatakuliah(widget.matakuliah!.idMatakuliah, _kode, _nama, _sks);
        }

        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Matakuliah berhasil ${widget.matakuliah == null ? 'ditambahkan' : 'diperbarui'}!'),
            backgroundColor: Colors.green,
          ));
          Navigator.of(context).pop();
          ref.invalidate(matakuliahListProvider); // Muat ulang list
        }

      } catch (e) {
        if(mounted) {
          String errorMessage = (e is ApiException) ? e.message : 'Operasi gagal.';
          showErrorDialog(context, 'Error', errorMessage);
        }
      } finally {
        if(mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.matakuliah == null ? 'Tambah Matakuliah Baru' : 'Edit Matakuliah'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _kode,
                decoration: const InputDecoration(labelText: 'Kode Matakuliah'),
                validator: (value) => value!.isEmpty ? 'Kode tidak boleh kosong.' : null,
                onSaved: (value) => _kode = value!,
              ),
              TextFormField(
                initialValue: _nama,
                decoration: const InputDecoration(labelText: 'Nama Matakuliah'),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong.' : null,
                onSaved: (value) => _nama = value!,
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'SKS'),
                value: _sks,
                items: [1, 2, 3, 4].map((s) => DropdownMenuItem(value: s, child: Text(s.toString()))).toList(),
                onChanged: (value) {
                  setState(() {
                    _sks = value!;
                  });
                },
                onSaved: (value) => _sks = value!,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        CustomButton(
          text: widget.matakuliah == null ? 'SIMPAN' : 'UPDATE',
          onPressed: _isLoading ? null : _submitForm,
          isLoading: _isLoading,
          backgroundColor: Colors.blue,
          width: 100,
          height: 35,
        ),
      ],
    );
  }
}