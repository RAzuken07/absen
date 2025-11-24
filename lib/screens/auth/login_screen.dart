// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart'; // Mengasumsikan ada widget ini
import '../../widgets/error_dialog.dart'; // Mengasumsikan ada widget ini

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await ref.read(authProvider.notifier).login(
              _usernameController.text,
              _passwordController.text,
            );

        if (success) {
          // Navigasi setelah login berhasil
          // authProvider akan handle navigasi ke dashboard sesuai role
          // atau Anda bisa tambahkan navigasi spesifik di sini
          // Contoh: Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SomeDashboardScreen()));
        } else {
          // Ini seharusnya tidak terpanggil jika backend benar, karena error akan throw DioException
          // Tapi sebagai fallback jika login return false tanpa exception
          if (mounted) {
            showErrorDialog(context, 'Login Gagal', 'Username atau password salah.');
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Terjadi kesalahan tidak dikenal.';
          if (e.toString().contains('Invalid credentials')) {
            errorMessage = 'Username atau password tidak valid.';
          } else if (e.toString().contains('No Internet Connection')) {
             errorMessage = 'Tidak ada koneksi internet.';
          } else {
             // Tangani error lain dari Dio, misalnya 401 Unauthorized, 403 Forbidden
             // Anda bisa parsing error message dari DioException jika backend mengirimkannya
             // Contoh: if (e is DioException && e.response?.data != null) { errorMessage = e.response!.data['message']; }
             errorMessage = 'Gagal login. Silakan coba lagi.';
          }
          showErrorDialog(context, 'Login Gagal', errorMessage);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan state login
    ref.listen<AsyncValue<void>>(
      authProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            // Error handling sudah ada di _handleLogin, ini sebagai fallback
            if (mounted && !_isLoading) { // Pastikan tidak menampilkan dialog berulang
               showErrorDialog(context, 'Error Auth', error.toString());
            }
          },
          data: (_) {
            // Setelah login berhasil, authProvider akan mengarahkan user.
            // Anda bisa menambahkan logic tambahan jika diperlukan.
          }
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Absensi Kampus'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo atau Icon Aplikasi
                Hero(
                  tag: 'app_logo', // Untuk animasi hero jika ada
                  child: Image.asset(
                    'assets/images/logo_kampus.png', // Pastikan path benar
                    height: 120,
                  ),
                ),
                const SizedBox(height: 48.0),

                // Username/NIP/NIM Input
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username / NIP / NIM',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32.0),

                // Login Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton( // Menggunakan CustomButton Anda
                        text: 'LOGIN',
                        onPressed: _handleLogin,
                        // Anda bisa menambahkan warna atau style lain di CustomButton
                      ),
                const SizedBox(height: 16.0),
                
                // Opsi "Lupa Password" atau "Daftar Akun Baru" (Opsional)
                // TextButton(
                //   onPressed: () {
                //     // TODO: Implementasi navigasi ke Lupa Password
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(content: Text('Fitur lupa password belum tersedia.')),
                //     );
                //   },
                //   child: const Text('Lupa Password?'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Dummy showErrorDialog dan CustomButton jika Anda belum membuatnya
// Pastikan path import Anda benar: '../../widgets/error_dialog.dart' dan '../../widgets/custom_button.dart'
// Jika belum ada, Anda bisa menggunakan yang sederhana seperti di bawah:
/*
void showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor, // Warna default atau dari tema
          foregroundColor: textColor ?? Colors.white, // Warna teks default
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
*/