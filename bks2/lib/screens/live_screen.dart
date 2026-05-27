import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class LiveScreen extends StatefulWidget {
  final String? stemJobId;
  final String? transcriptionJobId;
  const LiveScreen({super.key, this.stemJobId, this.transcriptionJobId});
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  bool _playing = false;
  double _time = 0;
  final double _total = 47;
  Timer? _timer;
  double _transpose = 0;
  double _tempo = 100;
  bool _stageMode = false;
  List<LyricLine> _lyrics = [];

  int get _activeIdx =>
      _lyrics.indexWhere((l) => _time >= l.lineStart && _time < l.lineEnd);

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    if (widget.transcriptionJobId == null) return;
    try {
      final job = await ApiService.getJob(widget.transcriptionJobId!);
      if (job.isDone && mounted) {
        setState(() => _lyrics = ApiService.parseLyrics(job));
      }
    } catch (_) {}
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        setState(() {
          _time += 0.1;
          if (_time >= _total) {
            _time = 0;
            _playing = false;
            _timer?.cancel();
          }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  String _fmtTime(double s) =>
      '${s ~/ 60}:${(s % 60).toInt().toString().padLeft(2, '0')}';

  List<Widget> _buildTransposeButtons() {
    return [-4, -3, -2, -1, 0, 1, 2, 3, 4].map<Widget>((s) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: () => setState(() => _transpose = s.toDouble()),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: _transpose == s ? BksColors.gold : BksColors.bg3,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _transpose == s ? BksColors.gold : BksColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                s > 0 ? '+$s' : '$s',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: _transpose == s
                      ? BksColors.textInverse : BksColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_stageMode) return _buildStage();
    return Scaffold(
      backgroundColor: BksColors.bg0,
      appBar: AppBar(
        title: const Text('LIVE'),
        actions: [
          if (widget.stemJobId != null)
            IconButton(
              icon: const Icon(Icons.theater_comedy, color: BksColors.gold),
              onPressed: () {
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                setState(() => _stageMode = true);
              },
            ),
        ],
      ),
      body: widget.stemJobId == null
          ? const Center(child: Text('Прво увези песна',
              style: TextStyle(color: BksColors.textMuted, fontSize: 16)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Transport
                _card(Column(children: [
                  Row(children: [
                    Text(_fmtTime(_time),
                        style: const TextStyle(fontSize: 11, color: BksColors.textMuted)),
                    Expanded(child: Slider(
                      value: _time.clamp(0, _total),
                      max: _total,
                      onChanged: (v) => setState(() => _time = v),
                      activeColor: BksColors.gold,
                      inactiveColor: BksColors.bg3,
                    )),
                    Text(_fmtTime(_total),
                        style: const TextStyle(fontSize: 11, color: BksColors.textMuted)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                      onPressed: () => setState(() => _time = 0),
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: BksColors.textSecondary, size: 30),
                    ),
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _playing ? BksColors.gold : const Color(0xFF2A2000),
                          border: Border.all(color: BksColors.gold, width: 2),
                        ),
                        child: Icon(
                          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: _playing ? BksColors.textInverse : BksColors.gold,
                          size: 32,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _time = _total),
                      icon: const Icon(Icons.skip_next_rounded,
                          color: BksColors.textSecondary, size: 30),
                    ),
                  ]),
                ])),
                const SizedBox(height: 12),

                // Transpose
                _card(Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TRANSPOSE', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: BksColors.textMuted, letterSpacing: 2)),
                      Text(
                        _transpose == 0 ? '0 ST'
                            : '${_transpose > 0 ? '+' : ''}${_transpose.toInt()} ST',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: _transpose == 0 ? BksColors.textMuted : BksColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: _buildTransposeButtons()),
                ])),
                const SizedBox(height: 12),

                // Tempo
                _card(Row(children: [
                  const Text('TEMPO', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: BksColors.textMuted, letterSpacing: 2)),
                  const SizedBox(width: 12),
                  Expanded(child: SliderTheme(
                    data: const SliderThemeData(
                      activeTrackColor: BksColors.bass,
                      inactiveTrackColor: BksColors.bg3,
                      thumbColor: BksColors.bass,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _tempo,
                      min: 70, max: 130,
                      onChanged: (v) => setState(() => _tempo = v),
                    ),
                  )),
                  Text('${_tempo.round()}%', style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: BksColors.bass)),
                ])),
                const SizedBox(height: 12),

                // Lyrics preview
                if (_lyrics.isNotEmpty) Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0800),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BksColors.goldDim),
                  ),
                  child: Column(children: [
                    Text(
                      _activeIdx >= 0 ? _lyrics[_activeIdx].text : '♪',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                          color: BksColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    if (_activeIdx >= 0 && _activeIdx + 1 < _lyrics.length) ...[
                      const SizedBox(height: 8),
                      Text(
                        _lyrics[_activeIdx + 1].text,
                        style: const TextStyle(fontSize: 14, color: BksColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                      setState(() => _stageMode = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A1A00),
                      foregroundColor: BksColors.gold,
                      side: const BorderSide(color: BksColors.goldDim),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.theater_comedy),
                    label: const Text('🎭 ВЛЕЗИ ВО STAGE MODE'),
                  ),
                ),
                const SizedBox(height: 30),
              ]),
            ),
    );
  }

  Widget _buildStage() {
    final active = _activeIdx >= 0 ? _lyrics[_activeIdx] : null;
    final next = _activeIdx >= 0 && _activeIdx + 1 < _lyrics.length
        ? _lyrics[_activeIdx + 1] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: const Color(0xFF0A0800),
          child: Row(children: [
            IconButton(
              onPressed: () {
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                setState(() => _stageMode = false);
              },
              icon: const Icon(Icons.close, color: Colors.white38, size: 22),
            ),
            const Spacer(),
            Text('${_tempo.round()}% BPM',
                style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2)),
            const SizedBox(width: 16),
            Text(
              _transpose == 0 ? '– ST'
                  : '${_transpose > 0 ? '+' : ''}${_transpose.toInt()} ST',
              style: TextStyle(
                color: _transpose == 0 ? Colors.white38 : BksColors.gold,
                fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2,
              ),
            ),
          ]),
        ),
        Expanded(child: GestureDetector(
          onTap: _togglePlay,
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (active != null)
                Text(active.text,
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900,
                        color: Colors.white),
                    textAlign: TextAlign.center),
              if (next != null) ...[
                const SizedBox(height: 16),
                Text(next.text,
                    style: const TextStyle(fontSize: 20, color: Color(0xFF3A3020)),
                    textAlign: TextAlign.center),
              ],
              if (active == null)
                Icon(_playing ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.white12, size: 80),
            ]),
          ),
        )),
        Container(
          color: const Color(0xFF080600),
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            LinearProgressIndicator(
              value: _time / _total,
              backgroundColor: Colors.white10,
              color: BksColors.gold,
              minHeight: 3,
            ),
            const SizedBox(height: 12),
            Row(children: [
              _stageBtn('−ST', BksColors.vocals,
                  () => setState(() => _transpose = (_transpose - 1).clamp(-12, 12))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _stageBtnLarge(
                _playing ? '⏸' : '▶', BksColors.gold, _togglePlay)),
              const SizedBox(width: 8),
              _stageBtn('+ST', BksColors.instr,
                  () => setState(() => _transpose = (_transpose + 1).clamp(-12, 12))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _stageBtn('−BPM', BksColors.bass,
                  () => setState(() => _tempo = (_tempo - 5).clamp(70, 130))),
              const SizedBox(width: 8),
              _stageBtn('RESET', BksColors.textMuted,
                  () => setState(() { _transpose = 0; _tempo = 100; })),
              const SizedBox(width: 8),
              _stageBtn('+BPM', BksColors.bass,
                  () => setState(() => _tempo = (_tempo + 5).clamp(70, 130))),
            ]),
          ]),
        ),
      ])),
    );
  }

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: BksColors.bg1,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: BksColors.border),
    ),
    child: child,
  );

  Widget _stageBtn(String label, Color color, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    ),
  );

  Widget _stageBtnLarge(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.6)),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(
              color: color, fontSize: 28, fontWeight: FontWeight.w700)),
        ),
      );
}
