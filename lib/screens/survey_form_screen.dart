import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

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

  final MapController _mapController = MapController();

  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  
  File? _selectedPhotoFile;
  Uint8List? _selectedPhotoBytes;

  bool _loading = false;
  bool _loadingCategories = true;
  bool _gettingLocation = false;

  final Color primaryGreen = const Color(0xFF00695C);
  final Color primaryGreenLight = const Color(0xFFE0F2F1);
  final Color backgroundColor = const Color(0xFFF4F8F6);

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

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan lokasi (GPS) tidak aktif.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin akses lokasi ditolak.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak secara permanen.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });

      _mapController.move(newLatLng, 16.0);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi berhasil didapatkan secara otomatis!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _gettingLocation = false);
      }
    }
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
              (item) => int.tryParse('${item['id']}') == _selectedCategoryId,
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
            'Gagal memuat kategori: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final imageXFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imageXFile == null || !mounted) return;

      if (kIsWeb) {
        final bytes = await imageXFile.readAsBytes();
        setState(() {
          _selectedPhotoBytes = bytes;
          _selectedPhotoFile = null;
        });
      } else {
        setState(() {
          _selectedPhotoFile = File(imageXFile.path);
          _selectedPhotoBytes = null;
        });
      }
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

  Widget _buildPhotoPreview() {
    if (kIsWeb) {
      if (_selectedPhotoBytes != null) {
        return Image.memory(
          _selectedPhotoBytes!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } else {
      if (_selectedPhotoFile != null) {
        return Image.file(
          _selectedPhotoFile!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    if (_isEditing && widget.survey!.photo != null && widget.survey!.photo!.isNotEmpty) {
      return Image.network(
        widget.survey!.photo!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Text('Gagal memuat foto survey lama.'));
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInteractiveMap() {
    double lat = double.tryParse(_latitudeController.text) ?? -6.200000;
    double lng = double.tryParse(_longitudeController.text) ?? 106.816666;
    LatLng currentCenter = LatLng(lat, lng);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: currentCenter,
        initialZoom: 15.0,
        onTap: (tapPosition, point) {
          setState(() {
            _latitudeController.text = point.latitude.toStringAsFixed(6);
            _longitudeController.text = point.longitude.toStringAsFixed(6);
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: currentCenter,
              width: 50,
              height: 50,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 45,
              ),
            ),
          ],
        ),
      ],
    );
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
        photoFile: _selectedPhotoFile,
        photoBytes: _selectedPhotoBytes,
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
                            _isEditing ? 'Perbarui Data Survey' : 'Form Tambah Survey',
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

                      // Latitude & Longitude dengan Tombol GPS Otomatis
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              onChanged: (_) => setState(() {}),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                hintText: 'Contoh: -6.200',
                                prefixIcon: IconButton(
                                  icon: _gettingLocation
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Icon(Icons.my_location, color: primaryGreen),
                                  onPressed: _getCurrentLocation,
                                  tooltip: 'Ambil Lokasi Otomatis',
                                ),
                                border: const OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryGreen, width: 2),
                                ),
                              ),
                              validator: (value) {
                                final number = double.tryParse((value ?? '').trim());
                                if (number == null) return 'Harus angka';
                                if (number < -90 || number > 90) return 'Antara -90 s.d 90';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              onChanged: (_) => setState(() {}),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                hintText: 'Contoh: 106.816',
                                prefixIcon: IconButton(
                                  icon: _gettingLocation
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Icon(Icons.map_outlined, color: primaryGreen),
                                  onPressed: _getCurrentLocation,
                                  tooltip: 'Ambil Lokasi Otomatis',
                                ),
                                border: const OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryGreen, width: 2),
                                ),
                              ),
                              validator: (value) {
                                final number = double.tryParse((value ?? '').trim());
                                if (number == null) return 'Harus angka';
                                if (number < -180 || number > 180) return 'Antara -180 s.d 180';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // === PETA INTERAKTIF ===
                      const Text(
                        'Peta Lokasi (Ketuk peta untuk pilih titik / geser & zoom)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryGreen.withOpacity(0.3)),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildInteractiveMap(),
                        ),
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
                              label: Text('Pilih Foto dari Galeri', style: TextStyle(color: primaryGreen)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryGreen),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            
                            const SizedBox(height: 14),
                            if (_selectedPhotoFile != null || _selectedPhotoBytes != null || (_isEditing && widget.survey!.photo != null))
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildPhotoPreview(),
                              ),

                            if (_isEditing && _selectedPhotoFile == null && _selectedPhotoBytes == null && widget.survey!.photo != null && widget.survey!.photo!.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  'Foto lama akan tetap digunakan jika tidak memilih foto baru.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
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
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _loading ? 'Menyimpan...' : _isEditing ? 'Simpan Perubahan' : 'Simpan Survey',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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