import 'package:flutter/material.dart';

import '../models/survey.dart';
import '../services/api_service.dart';
import 'survey_detail_screen.dart';
import 'survey_form_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  List<Survey> _surveys = [];
  bool _loading = true;
  String? _error;

  // Definisi Tema Warna Hijau Tua Konsisten
  final Color primaryGreen = const Color(0xFF00695C);
  final Color primaryGreenLight = const Color(0xFFE0F2F1);
  final Color backgroundColor = const Color(0xFFF4F8F6);

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getSurveys();

      dynamic data = result;

      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      if (data is Map) {
        if (data['surveys'] is List) {
          data = data['surveys'];
        } else if (data['items'] is List) {
          data = data['items'];
        } else if (data['data'] is List) {
          data = data['data'];
        }
      }

      List<dynamic> items = [];

      if (data is List) {
        items = data;
      }

      final surveys = items
          .whereType<Map>()
          .map(
            (item) => Survey.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _surveys = surveys;
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

  Future<void> _openForm({Survey? survey}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyFormScreen(survey: survey),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadSurveys();
    }
  }

  Future<void> _deleteSurvey(Survey survey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Survey'),
        content: Text(
          'Yakin ingin menghapus survey "${survey.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteSurvey(survey.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadSurveys();
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
    }
  }

  void _showSurveyMenu(Survey survey) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.info_outline, color: primaryGreen),
              title: const Text('Lihat Detail'),
              onTap: () {
                Navigator.pop(sheetContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurveyDetailScreen(
                      surveyId: survey.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: primaryGreen),
              title: const Text('Edit Survey'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openForm(survey: survey);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              title: const Text(
                'Hapus Survey',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteSurvey(survey);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Data Survey'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Survey'),
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _loadSurveys,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 250),
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              )
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton(
                          onPressed: _loadSurveys,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ),
                    ],
                  )
                : _surveys.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 100),
                          Icon(
                            Icons.assignment_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada data survey.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tekan tombol Tambah Survey untuk membuat data.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          90,
                        ),
                        itemCount: _surveys.length,
                        itemBuilder: (context, index) {
                          final survey = _surveys[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: CircleAvatar(
                                backgroundColor: primaryGreenLight,
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: primaryGreen,
                                ),
                              ),
                              title: Text(
                                survey.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (survey.categoryName.isNotEmpty)
                                      Text(
                                        'Kategori: ${survey.categoryName}',
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      survey.description.isEmpty
                                          ? 'Tidak ada deskripsi'
                                          : survey.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () =>
                                    _showSurveyMenu(survey),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SurveyDetailScreen(
                                      surveyId: survey.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}