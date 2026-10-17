import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controller untuk inputan form
  final TextEditingController _nameController = TextEditingController(text: 'delaa');
  final TextEditingController _emailController = TextEditingController(text: 'dela@gmail.com');
  final TextEditingController _phoneController = TextEditingController(text: '08211765343');

  // Value awal 'P' (Perempuan) atau 'L' (Laki-laki)
  String _selectedGender = 'P'; 
  bool _isLoading = false;

  // Fungsi untuk update profil ke API Laravel
  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Gunakan IP 127.0.0.1 atau localhost sesuai port Laravel kamu
      final url = Uri.parse('http://127.0.0.1:8000/api/update'); 
      
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          // 'Authorization': 'Bearer TOKEN_KAMU', // Hilangkan komentar jika menggunakan token
        },
        body: {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'gender': _selectedGender, // Kirim 'P' atau 'L' langsung
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'), 
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['errors']?['gender']?[0] ?? data['message'] ?? 'Gagal memperbarui profil'), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan koneksi. Pastikan server Laravel sudah nyala!'), 
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: const Color(0xFF0A5C36),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.person, size: 50, color: Color(0xFF0A5C36)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Informasi Akun', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Field Nama
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap', 
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Field Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email', 
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Field Phone
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon', 
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Dropdown Gender ('P' / 'L')
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Jenis Kelamin', 
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const SizedBox(height: 30),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A5C36)),
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Perubahan', 
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}