import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/bks_widgets.dart';

class ExportScreen extends StatefulWidget {
  final String? stemJobId;
  const ExportScreen({super.key, this.stemJobId});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _format = 'mp3';
  String _bitrate = '320k';
  bool _stems = false;
  bool _ketron = false;
  String _title = '';
  String _artist = '';
  bool _exporting = false;
  int _progress = 0;
  String _status = '';
  Map<String, String> _results = {};

  Future<void> _export() async {
    if (widget.stemJobId == null) return;
    setState(() { _exporting = true; _results = {}; _progress = 0; });
    try {
      final jid = await ApiService.startExport(
        stemJobId: widget.stemJobId!, format: _format, bitrate: _bitrate,
        includeStems: _stems, exportKetron: _ketron, title: _title, artist: _artist);
      await ApiService.pollJob(jid, onProgress: (job) {
        if (mounted) setState(() { _progress = job.progress; _status = job.message; });
      });
      final job = await ApiService.getJob(jid);
      if (job.isDone && job.result != null) {
        final files = <String, String>{};
        for (final e in job.result!.entries) {
          if (e.value is String) files[e.key] = ApiService.fileUrl(e.value as String);
        }
        setState(() => _results = files);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: BksColors.error));
    } finally { if (mounted) setState(() => _exporting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BksColors.bg0,
      appBar: AppBar(title: const Text('EXPORT')),
      body: widget.stemJobId == null
          ? const Center(child: Text('Прво увези песна',
              style: TextStyle(color: BksColors.textMuted, fontSize: 16)))
          : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            BksCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionLabel(text: 'FORMAT'),
              Row(children: ['mp3','wav','flac'].map((f) => Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(onTap: () => setState(() => _format = f),
                  child: Container(height: 40, decoration: BoxDecoration(
                    color: _format == f ? BksColors.gold.withOpacity(0.15) : BksColors.bg3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _format == f ? BksColors.gold : BksColors.border)),
                    alignment: Alignment.center,
                    child: Text(f.toUpperCase(), style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, letterSpacing: 1,
                        color: _format == f ? BksColors.gold : BksColors.textSecondary)))))
              ).toList()),
            ])),
            const SizedBox(height: 10),
            if (_format == 'mp3') BksCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionLabel(text: 'BITRATE'),
              Row(children: ['128k','192k','256k','320k'].map((b) => Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(onTap: () => setState(() => _bitrate = b),
                  child: Container(height: 38, decoration: BoxDecoration(
                    color: _bitrate == b ? BksColors.bass.withOpacity(0.15) : BksColors.bg3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _bitrate == b ? BksColors.bass : BksColors.border)),
                    alignment: Alignment.center,
                    child: Text(b, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: _bitrate == b ? BksColors.bass : BksColors.textSecondary)))))
              ).toList()),
            ])),
            const SizedBox(height: 10),
            BksCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionLabel(text: 'МЕТАПОДАТОЦИ'),
              _field('Наслов на песната', (v) => _title = v),
              const SizedBox(height: 8),
              _field('Изведувач', (v) => _artist = v),
            ])),
            const SizedBox(height: 10),
            BksCard(child: Column(children: [
              const SectionLabel(text: 'ОПЦИИ'),
              _toggle('📦 Stems ZIP', 'Сите стемови одвоено', _stems, (v) => setState(() => _stems = v)),
              _toggle('🎹 Ketron фајл', 'Стерео MP3 320kbps за клавијатури', _ketron, (v) => setState(() => _ketron = v)),
            ])),
            const SizedBox(height: 14),
            if (_exporting) ...[
              BksProgressCard(progress: _progress, message: _status, isComplete: false),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _exporting ? null : _export,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: _exporting
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: BksColors.textInverse))
                  : const Icon(Icons.download_rounded),
              label: Text(_exporting ? 'EXPORTИРА...' : '⬇ EXPORTИРАЈ'),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionLabel(text: 'ГОТОВИ ФАЈЛОВИ'),
              ..._results.entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF0A180A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A4A1A))),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: BksColors.success, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: BksColors.textPrimary)),
                    Text(e.value.split('/').last,
                        style: const TextStyle(fontSize: 11, color: BksColors.textMuted)),
                  ])),
                  const Icon(Icons.share, color: BksColors.success, size: 20),
                ]))),
            ],
            const SizedBox(height: 30),
          ])),
    );
  }

  Widget _field(String hint, Function(String) onChanged) => TextField(
    onChanged: onChanged,
    style: const TextStyle(fontSize: 14, color: BksColors.textPrimary),
    decoration: InputDecoration(hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: BksColors.textMuted),
      filled: true, fillColor: BksColors.bg3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BksColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BksColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BksColors.gold))));

  Widget _toggle(String label, String sub, bool val, Function(bool) onChange) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: BksColors.textPrimary)),
        Text(sub, style: const TextStyle(fontSize: 11, color: BksColors.textMuted)),
      ])),
      Switch(value: val, onChanged: onChange, activeColor: BksColors.gold),
    ]));
}
