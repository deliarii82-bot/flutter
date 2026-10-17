import 'package:flutter/material.dart';

import '../models/survey.dart';
import '../services/api_service.dart';
import 'survey_form_screen.dart';

class SurveyDetailScreen extends StatefulWidget {
  final int surveyId;

  const SurveyDetailScreen({
    super.key,
    required this.surveyId,
  });

  @override
  State<SurveyDetailScreen> createState() =>
      _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  Survey? _survey;
  bool _loading = true;
  String? _error;

  // Definisi Warna Hijau Tua
  final Color primaryGreen = const Color(0xFF00695C); // Hijau Tua (Teal 800)
  final Color backgroundColor = const Color(0xFFF4F8F6); // Background hijau sangat pucat/clean

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getSurvey(widget.surveyId);
      final data = ApiService.unwrap(result);

      Map<String, dynamic>? item;

      if (data is Map) {
        if (data['survey'] is Map) {
          item = Map<String, dynamic>.from(data['survey']);
        } else if (data['data'] is Map) {
          item = Map<String, dynamic>.from(data['data']);
        } else {
          item = Map<String, dynamic>.from(data);
        }
      }

      if (item == null) {
        throw Exception('Data detail survey tidak ditemukan.');
      }

      if (!mounted) return;

      setState(() {
        _survey = Survey.fromJson(item!);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // Fungsi URL Foto yang Diperbaiki Secara Mutlak
  String _photoUrl(String photo) {
    final cleanPhoto = photo.trim();

    if (cleanPhoto.startsWith('http://') || cleanPhoto.startsWith('https://')) {
      return cleanPhoto;
    }

    // Hilangkan slash di depan jika ada
    final pathWithoutSlash = cleanPhoto.startsWith('/') ? cleanPhoto.substring(1) : cleanPhoto;

    // Jika path sudah mengandung 'storage/', langsung gabungkan dengan domain utama
    if (pathWithoutSlash.startsWith('storage/')) {
      return 'https://sijala.biz.id/$pathWithoutSlash';
    }

    // Jika path dari database berupa nama file atau folder (misal: surveys/xxx.jpg atau xxx.jpg)
    // Cek apakah sudah ada folder 'surveys/' di dalamnya
    if (pathWithoutSlash.contains('surveys/')) {
      return 'https://sijala.biz.id/storage/$pathWithoutSlash';
    } else {
      return 'https://sijala.biz.id/storage/surveys/$pathWithoutSlash';
    }
  }

  Widget _detailItem(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSurvey() async {
    if (_survey == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyFormScreen(survey: _survey),
      ),
    );

    if (result == true) {
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detail Survey'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_survey != null)
            IconButton(
              tooltip: 'Edit Survey',
              onPressed: _editSurvey,
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _survey == null
                  ? const Center(
                      child: Text('Data survey tidak ditemukan.'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (_survey!.photo != null &&
                                  _survey!.photo!.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: Image.network(
                                    _photoUrl(_survey!.photo!),
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              Text(
                                _survey!.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _detailItem(
                                Icons.category_outlined,
                                'Kategori',
                                _survey!.categoryName,
                              ),
                              _detailItem(
                                Icons.description_outlined,
                                'Deskripsi',
                                _survey!.description,
                              ),
                              _detailItem(
                                Icons.location_on_outlined,
                                'Latitude',
                                _survey!.latitude,
                              ),
                              _detailItem(
                                Icons.location_searching,
                                'Longitude',
                                _survey!.longitude,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _editSurvey,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Survey'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(14),
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
    );
  }
}