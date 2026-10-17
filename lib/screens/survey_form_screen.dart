import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/survey.dart';
import '../services/api_service.dart';

class SurveyFormScreen extends StatefulWidget {
  final Survey? survey;

  const SurveyFormScreen({
    super.key,
    this.survey,
  });

  @override
  State<SurveyFormScreen> createState() => _SurveyFormScreenState();
}

class _SurveyFormScreenState extends State<SurveyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  File? _selectedPhoto;

  bool _loading = false;
  bool _loadingCategories = true;

  // Definisi Tema Warna Hijau Tua
  final Color primaryGreen = const Color(0xFF00695C); // Hijau Tua (Teal 800)
  final Color primaryGreenLight = const Color(0xFFE0F2F1); // Hijau Sangat Pucat
  final Color backgroundColor = const Color(0xFFF4F8F6); // Background Clean

  bool get _isEditing => widget.survey != null;

  @override
  void initState() {
    super.initState();

    final survey = widget.survey;

    if (survey != null) {
      _titleController.text = survey.title;
      _descriptionController.text = survey.description;
      _latitudeController.text = survey.latitude;
      _longitudeController.text = survey.longitude;
      _selectedCategoryId = survey.categoryId;
    }

    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await ApiService.getCategories();
      final data = ApiService.unwrap(result);

      List<dynamic> items = [];

      if (data is List) {
        items = data;
      } else if (data is Map) {
        if (data['categories'] is List) {
          items = data['categories'];
        } else if (data['data'] is List) {
          items = data['data'];
        } else if (data['items'] is List) {
          items = data['items'];
        }
      }

      if (!mounted) return;

      setState(() {
        _categories = items;
        _loadingCategories = false;

        if (_selectedCategoryId != null &&
            !_categories.any(
              (item) =>
                  int.tryParse('${item['id']}') ==
                  _selectedCategoryId,
            )) {
          _selectedCategoryId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat kategori: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedPhoto = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSurvey() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori survey.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiService.saveSurvey(
        id: widget.survey?.id,
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId!,
        description: _descriptionController.text.trim(),
        latitude: _latitudeController.text.trim(),
        longitude: _longitudeController.text.trim(),
        photo: _selectedPhoto,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Survey berhasil diperbarui.'
                : 'Survey berhasil ditambahkan.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _categoryLabel(dynamic item) {
    return (item['name'] ?? item['title'] ?? item['nama'] ?? '')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Survey' : 'Tambah Survey'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isEditing ? Icons.edit_note : Icons.post_add,
                            size: 32,
                            color: primaryGreen,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isEditing
                                ? 'Perbarui Data Survey'
                                : 'Form Tambah Survey',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),

                      // Judul Survey
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Judul Survey',
                          prefixIcon: Icon(Icons.assignment_outlined, color: primaryGreen),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryGreen, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul survey wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Kategori Survey
                      if (_loadingCategories)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(color: primaryGreen),
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Kategori Survey',
                            prefixIcon: Icon(Icons.category_outlined, color: primaryGreen),
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryGreen, width: 2),
                            ),
                          ),
                          items: _categories.map((item) {
                            final id = int.tryParse('${item['id']}');

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(_categoryLabel(item)),
                            );
                          }).where((item) => item.value != null).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Kategori wajib dipilih';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 20),

                      // Deskripsi
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description_outlined, color: primaryGreen),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryGreen, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Deskripsi wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Latitude & Longitude dalam Row (Biar rapi & modern)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                hintText: 'Contoh: -6.200',
                                prefixIcon: Icon(Icons.location_on_outlined, color: primaryGreen),
                                border: const OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryGreen, width: 2),
                                ),
                              ),
                              validator: (value) {
                                final number = double.tryParse(
                                  (value ?? '').trim(),
                                );

                                if (number == null) {
                                  return 'Harus angka';
                                }

                                if (number < -90 || number > 90) {
                                  return 'Antara -90 s.d 90';
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                hintText: 'Contoh: 106.816',
                                prefixIcon: Icon(Icons.location_searching, color: primaryGreen),
                                border: const OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryGreen, width: 2),
                                ),
                              ),
                              validator: (value) {
                                final number = double.tryParse(
                                  (value ?? '').trim(),
                                );

                                if (number == null) {
                                  return 'Harus angka';
                                }

                                if (number < -180 || number > 180) {
                                  return 'Antara -180 s.d 180';
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bagian Foto Survey
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryGreenLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Foto Survey (Opsional)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _pickPhoto,
                              icon: Icon(Icons.image_outlined, color: primaryGreen),
                              label: Text(
                                'Pilih Foto dari Galeri',
                                style: TextStyle(color: primaryGreen),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryGreen),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (_selectedPhoto != null) ...[
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedPhoto!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ] else if (_isEditing &&
                                widget.survey!.photo != null &&
                                widget.survey!.photo!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Foto lama akan tetap digunakan jika tidak memilih foto baru.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Tombol Simpan
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _saveSurvey,
                          icon: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _loading
                                ? 'Menyimpan...'
                                : _isEditing
                                    ? 'Simpan Perubahan'
                                    : 'Simpan Survey',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}