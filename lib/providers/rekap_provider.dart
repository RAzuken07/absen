// lib/providers/rekap_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/absensi_model.dart';
import '../services/dosen_service.dart';
import '../services/api_service.dart';

class RekapKehadiranState {
  final List<RekapKehadiran> rekapData;
  final bool isLoading;
  final String? errorMessage;
  final int? currentIdKelas;

  RekapKehadiranState({
    this.rekapData = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentIdKelas,
  });

  RekapKehadiranState copyWith({
    List<RekapKehadiran>? rekapData,
    bool? isLoading,
    String? errorMessage,
    int? currentIdKelas,
  }) {
    return RekapKehadiranState(
      rekapData: rekapData ?? this.rekapData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentIdKelas: currentIdKelas ?? this.currentIdKelas,
    );
  }
}

class RekapKehadiranNotifier extends StateNotifier<RekapKehadiranState> {
  final DosenService _dosenService;

  RekapKehadiranNotifier(this._dosenService) : super(RekapKehadiranState());

  // Digunakan oleh Dosen/Admin untuk mengambil data rekap per kelas
  Future<void> fetchRekapKehadiran(int idKelas) async {
    state = state.copyWith(isLoading: true, errorMessage: null, currentIdKelas: idKelas);
    try {
      final rekapList = await _dosenService.getRekapKehadiran(idKelas);
      state = state.copyWith(
        rekapData: rekapList,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        rekapData: [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengambil data rekap kehadiran.',
        rekapData: [],
      );
    }
  }
}

final dosenServiceProvider = Provider<DosenService>((ref) => DosenService());

final rekapKehadiranProvider = StateNotifierProvider<RekapKehadiranNotifier, RekapKehadiranState>((ref) {
  final dosenService = ref.watch(dosenServiceProvider);
  return RekapKehadiranNotifier(dosenService);
});