// lib/providers/sesi_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sesi_model.dart';
import '../services/absensi_service.dart';
import '../services/api_service.dart';

class SesiAbsensiState {
  final List<SesiAbsensi> sesiAktif;
  final bool isLoading;
  final String? errorMessage;

  SesiAbsensiState({
    this.sesiAktif = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  SesiAbsensiState copyWith({
    List<SesiAbsensi>? sesiAktif,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SesiAbsensiState(
      sesiAktif: sesiAktif ?? this.sesiAktif,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SesiAbsensiNotifier extends StateNotifier<SesiAbsensiState> {
  final AbsensiService _absensiService;

  SesiAbsensiNotifier(this._absensiService) : super(SesiAbsensiState());

  // Digunakan oleh Mahasiswa untuk mendapatkan daftar sesi aktif
  Future<void> fetchSesiAktif() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final listSesi = await _absensiService.getSesiAktif();
      state = state.copyWith(
        sesiAktif: listSesi,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        sesiAktif: [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengambil data sesi aktif.',
        sesiAktif: [],
      );
    }
  }
}

final absensiServiceProvider = Provider<AbsensiService>((ref) => AbsensiService());

final sesiAbsensiProvider = StateNotifierProvider<SesiAbsensiNotifier, SesiAbsensiState>((ref) {
  final absensiService = ref.watch(absensiServiceProvider);
  return SesiAbsensiNotifier(absensiService);
});