import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/bks_widgets.dart';

class ImportScreen extends StatefulWidget {
  final void Function(String) onStemJobComplete;
  const ImportScreen({super.key, required this.onStemJobComplete});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  File? _file;
  bool _uploading = false;
  int _progress = 0;
  String _status = '';
  bool _done = false;
  final List<String> _log = [];

  void _addLog(String msg) { if (mounted) setState(() => _log.add(msg)); }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result?.files.first.path != null) {
      setState(() { _file = File(result!.files.first.path!); _done = false; _log.clear(); });
    }
  }

  Future<void> _process() async {
    if (_file == null || _uploading) return;
    setState(() { _uploading = true; _log.clear(); _progress = 0; });
    _addLog('📤 Качување на аудио...');
    try {
      final jobId = await ApiService.uploadAndSeparate(_file!);
      _addLog('🤖 AI сепарација почна...');
      await ApiService.pollJob(jobId, onProgress: (job) {
        if (mounted) setState(() {
          _progress = job.progress;
          _status = job.message;
          if (job.progress > 0) _addLog('[${job.progress}%] ${job.message}');
        });
      });
      final job = await ApiService.getJob(jobId);
      if (job.isDone) {
        _addLog('✅ Готово! 4 стема се подготвени.');
        setState(() { _done = true; _uploading = false; });
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onStemJobComplete(jobId);
      } else {
        _addLog('❌ Грешка: ${job.error}');
        setState(() => _uploading = false);
      }
    } catch (e) {
      _addLog('❌ $e');
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BksColors.bg0,
      appBar: AppBar(title: const Text('IMPORT AUDIO'), actions: [
        Padding(padding: const EdgeInsets.only(right: 14),
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: BksColors.bg3,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: BksColors.border)),
            child: const Text('DEMUCS v4', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: BksColors.gold, letterSpacing: 1.5)),
          ))),
      ]),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Drop zone
          GestureDetector(
            onTap: _uploading ? null : _pickFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 150,
              decoration: BoxDecoration(
                color: _file != null ? const Color(0xFF12100A) : BksColors.bg1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _file != null ? BksColors.goldDim : BksColors.border,
                  width: 1.5,
                ),
              ),
              child: _file != null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.audio_file, color: BksColors.gold, size: 40),
                const SizedBox(height: 10),
                Text(_file!.path.split('/').last,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: BksColors.textPrimary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('${(_file!.lengthSync()/1024/1024).toStringAsFixed(1)} MB',
                    style: const TextStyle(fontSize: 12, color: BksColors.textMuted)),
              ]) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_circle_outline, size: 44, color: BksColors.textMuted),
                const SizedBox(height: 12),
                const Text('ДОПРИ ЗА АУДИО ФАЈЛ', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: BksColors.textSecondary, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                const Text('MP3 · WAV · FLAC · M4A', style: TextStyle(
                    fontSize: 11, color: BksColors.textMuted, letterSpacing: 1)),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          if (_uploading || _done) ...[
            BksProgressCard(progress: _progress,
                message: _status.isEmpty ? 'Обработува...' : _status,
                isComplete: _done),
            const SizedBox(height: 12),
          ],

          if (_log.isNotEmpty) ...[
            Container(
              height: 160, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF05050A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BksColors.border)),
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (_, i) => Text(_log[i], style: TextStyle(
                  fontSize: 11.5, fontFamily: 'monospace',
                  color: _log[i].startsWith('✅') ? BksColors.success
                      : _log[i].startsWith('❌') ? BksColors.error : BksColors.textSecondary,
                )),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_file != null && !_uploading && !_done)
            ElevatedButton.icon(
              onPressed: _process,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ПРОЦЕСИРАЈ СО AI'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            ),

          if (_uploading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: BksColors.gold, strokeWidth: 2)),
                SizedBox(width: 12),
                Text('AI ОБРАБОТУВА...', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: BksColors.gold, letterSpacing: 2)),
              ]),
            )),

          const SizedBox(height: 20),
          BksCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel(text: 'AI СЕПАРАЦИЈА'),
            for (final s in [
              ['🎤', 'Вокали', 'Изолирани вокали'],
              ['🥁', 'Удари', 'Зачувани — никогаш не се транспонираат'],
              ['🎸', 'Бас', 'Изолирана бас линија'],
              ['🎹', 'Инструменти', 'Мелодиски содржини'],
              ['🎵', 'Инструментал', 'Комплетна матрица'],
            ])
              Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Text(s[0], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s[1], style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: BksColors.textPrimary)),
                    Text(s[2], style: const TextStyle(fontSize: 11, color: BksColors.textMuted)),
                  ]),
                ])),
          ])),
        ]),
      )),
    );
  }
}
