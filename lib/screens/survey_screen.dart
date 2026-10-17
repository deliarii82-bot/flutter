
import 'package:flutter/material.dart';

import '../models/survey.dart';
import '../services/api_service.dart';
import 'survey_detail_screen.dart';
import 'survey_form_screen.dart';

class SurveyScreen extends StatefulWidget {
  SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  List<Survey> _surveys = [];
  bool _loading = true;
  String? _error;

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
        title: Text('Hapus Survey'),
        content: Text(
          'Yakin ingin menghapus survey "${survey.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteSurvey(survey.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Lihat Detail'),
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
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit Survey'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openForm(survey: survey);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              title: Text(
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
      backgroundColor: Color(0xFFF3F5FA),
      appBar: AppBar(
        title: Text('Data Survey'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Tambah Survey'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSurveys,
        child: _loading
            ? ListView(
                children: [
                  SizedBox(height: 250),
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              )
            : _error != null
                ? ListView(
                    padding: EdgeInsets.all(24),
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: ElevatedButton(
                          onPressed: _loadSurveys,
                          child: Text('Coba Lagi'),
                        ),
                      ),
                    ],
                  )
                : _surveys.isEmpty
                    ? ListView(
                        padding: EdgeInsets.all(24),
                        children: [
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
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          90,
                        ),
                        itemCount: _surveys.length,
                        itemBuilder: (context, index) {
                          final survey = _surveys[index];

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(14),
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo.shade50,
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: Colors.indigo,
                                ),
                              ),
                              title: Text(
                                survey.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (survey.categoryName.isNotEmpty)
                                      Text(
                                        'Kategori: ${survey.categoryName}',
                                      ),
                                    SizedBox(height: 4),
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
                                icon: Icon(Icons.more_vert),
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
