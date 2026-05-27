import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/bks_widgets.dart';

class MixerScreen extends StatefulWidget {
  final String? stemJobId;
  final void Function(String) onTranscriptionComplete;
  const MixerScreen({super.key, this.stemJobId, required this.onTranscriptionComplete});
  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
  final _vols = {'vocals': 85.0, 'drums': 100.0, 'bass': 90.0, 'instruments': 88.0};
  final _muted = {'vocals': false, 'drums': false, 'bass': false, 'instruments': false};
  String? _soloed;
  double _semi = 0;
  bool _transposing = false;
  bool _transposed = false;
  String _lang = 'mk';
  bool _transcribing = false;
  bool _transcribed = false;

  final _stemCfg = [
    {'key': 'vocals', 'label': 'ВОКАЛИ', 'icon': '🎤', 'color': BksColors.vocals},
    {'key': 'drums',  'label': 'УДАРИ',  'icon': '🥁', 'color': BksColors.drums},
    {'key': 'bass',   'label': 'БАС',    'icon': '🎸', 'color': BksColors.bass},
    {'key': 'instruments', 'label': 'ИНСТРУМЕНТИ', 'icon': '🎹', 'color': BksColors.instr},
  ];

  Future<void> _doTranspose() async {
    if (_semi == 0 || _transposing || widget.stemJobId == null) return;
    setState(() { _transposing = true; _transposed = false; });
    try {
      final jid = await ApiService.startTranspose(stemJobId: widget.stemJobId!, semitones: _semi);
      await ApiService.pollJob(jid);
      setState(() { _transposing = false; _transposed = true; });
    } catch (e) {
      setState(() => _transposing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: BksColors.error));
    }
  }

  Future<void> _doTranscribe() async {
    if (_transcribing || widget.stemJobId == null) return;
    setState(() { _transcribing = true; _transcribed = false; });
    try {
      final jid = await ApiService.startTranscription(stemJobId: widget.stemJobId!, language: _lang);
      await ApiService.pollJob(jid);
      widget.onTranscriptionComplete(jid);
      setState(() { _transcribing = false; _transcribed = true; });
    } catch (e) {
      setState(() => _transcribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.stemJobId != null;
    return Scaffold(
      backgroundColor: BksColors.bg0,
      appBar: AppBar(title: const Text('STEM MIKSER')),
      body: !ready
          ? const Center(child: Text('Прво увези песна',
              style: TextStyle(color: BksColors.textMuted, fontSize: 16)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Stems
                const SectionLabel(text: 'STEM TRACKOVI'),
                ..._stemCfg.map((s) {
                  final key = s['key'] as String;
                  final color = s['color'] as Color;
                  final isDrums = key == 'drums';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _muted[key]! ? 0.35 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: BksColors.bg1, borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: color, width: 3),
                            top: BorderSide(color: _soloed == key ? color.withOpacity(0.4) : BksColors.border),
                            right: BorderSide(color: _soloed == key ? color.withOpacity(0.4) : BksColors.border),
                            bottom: BorderSide(color: _soloed == key ? color.withOpacity(0.4) : BksColors.border),
                          ),
                        ),
                        child: Column(children: [
                          Row(children: [
                            Text(s['icon'] as String, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(s['label'] as String, style: TextStyle(
                                color: color, fontWeight: FontWeight.w700,
                                fontSize: 12, letterSpacing: 1.2)),
                            if (isDrums) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF2A200A),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: BksColors.goldDim)),
                                child: const Text('NO TRANSPOSE', style: TextStyle(
                                    fontSize: 8, fontWeight: FontWeight.w700,
                                    color: BksColors.gold, letterSpacing: 1)),
                              ),
                            ],
                            const Spacer(),
                            SmallBtn(label: 'MUTE', active: _muted[key]!, activeColor: color,
                                onTap: () => setState(() => _muted[key] = !_muted[key]!)),
                            const SizedBox(width: 6),
                            SmallBtn(label: 'SOLO', active: _soloed == key, activeColor: BksColors.gold,
                                onTap: () => setState(() => _soloed = _soloed == key ? null : key)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Text('VOL', style: TextStyle(fontSize: 9,
                                color: BksColors.textMuted, letterSpacing: 1.5)),
                            Expanded(child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: color, inactiveTrackColor: BksColors.bg3,
                                thumbColor: color, trackHeight: 3,
                                overlayColor: color.withOpacity(0.2),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(value: _vols[key]! / 100, onChanged: (v) =>
                                  setState(() => _vols[key] = v * 100)),
                            )),
                            Text('${_vols[key]!.round()}%',
                                style: const TextStyle(fontSize: 11, color: BksColors.textMuted)),
                          ]),
                        ]),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                const SectionLabel(text: 'TRANSPOSE ENGINE'),
                BksCard(glowColor: _semi != 0 ? BksColors.gold : null, child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _TBtn(icon: Icons.remove, onTap: _semi > -12 ? () => setState(() => _semi -= 1) : null),
                    const SizedBox(width: 16),
                    Column(children: [
                      Text(_semi > 0 ? '+${_semi.toInt()}' : '${_semi.toInt()}',
                          style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800,
                              color: _semi == 0 ? BksColors.textMuted : BksColors.gold)),
                      const Text('SEMITОНИ', style: TextStyle(fontSize: 9,
                          color: BksColors.textMuted, letterSpacing: 2)),
                    ]),
                    const SizedBox(width: 16),
                    _TBtn(icon: Icons.add, onTap: _semi < 12 ? () => setState(() => _semi += 1) : null),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 5, runSpacing: 5, alignment: WrapAlignment.center,
                    children: [-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6].map((s) =>
                      GestureDetector(onTap: () => setState(() => _semi = s.toDouble()),
                        child: Container(width: 34, height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _semi == s ? BksColors.gold : BksColors.bg3,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _semi == s ? BksColors.gold : BksColors.border),
                          ),
                          child: Text(s > 0 ? '+$s' : '$s', style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: _semi == s ? BksColors.textInverse : BksColors.textSecondary)),
                        ))).toList()),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: const Color(0xFF0A180A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1A3A1A))),
                    child: const Row(children: [
                      Icon(Icons.lock, color: BksColors.success, size: 14),
                      SizedBox(width: 8),
                      Expanded(child: Text('🥁 Удари НИКОГАШ не се транспонираат',
                          style: TextStyle(color: BksColors.success, fontSize: 12))),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  if (_transposed) const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('✅ Транспонирање завршено!',
                        style: TextStyle(color: BksColors.success, fontSize: 12),
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _semi == 0 || _transposing ? null : _doTranspose,
                      icon: _transposing
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: BksColors.textInverse))
                          : const Icon(Icons.music_note),
                      label: Text(_transposing ? 'ТРАНСПОНИРА...'
                          : _semi == 0 ? 'ИЗБЕРИ СЕМИТОНИ' : 'ПРИМЕНИ TRANSPOSE'),
                    )),
                ])),

                const SizedBox(height: 16),
                const SectionLabel(text: 'ТРАНСКРИПЦИЈА НА ТЕКСТ'),
                BksCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SectionLabel(text: 'ЈАЗИК'),
                  Wrap(spacing: 7, runSpacing: 7, children: bksLanguages.map((l) =>
                    GestureDetector(onTap: () => setState(() => _lang = l['code']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _lang == l['code'] ? BksColors.accent.withOpacity(0.3) : BksColors.bg3,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _lang == l['code'] ? BksColors.accent : BksColors.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(l['flag']!, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(l['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: _lang == l['code'] ? BksColors.textPrimary : BksColors.textSecondary)),
                        ]),
                      ))).toList()),
                  const SizedBox(height: 10),
                  if (_transcribed) const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('✅ Текст транскрибиран! Оди на KARAOKE',
                        style: TextStyle(color: BksColors.success, fontSize: 12),
                        textAlign: TextAlign.center),
                  ),
                  ElevatedButton.icon(
                    onPressed: _transcribing ? null : _doTranscribe,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: BksColors.accent, foregroundColor: Colors.white),
                    icon: _transcribing
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.mic),
                    label: Text(_transcribing ? 'WHISPER ТРАНСКРИБИРА...' : '🎤 ТРАНСКРИБИРАЈ ТЕКСТ'),
                  ),
                ])),
                const SizedBox(height: 30),
              ]),
            ),
    );
  }
}

class _TBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _TBtn({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 46, height: 46,
      decoration: BoxDecoration(color: onTap != null ? BksColors.bg3 : BksColors.bg1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: onTap != null ? const Color(0xFF363660) : BksColors.border,
              width: 1.5)),
      child: Icon(icon, color: onTap != null ? BksColors.textPrimary : BksColors.textMuted)),
  );
