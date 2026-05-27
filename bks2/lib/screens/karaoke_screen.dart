import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class KaraokeScreen extends StatefulWidget {
  final String? transcriptionJobId;
  const KaraokeScreen({super.key, this.transcriptionJobId});
  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  List<LyricLine> _lyrics = [];
  bool _loading = false;
  bool _playing = false;
  double _time = 0;
  final double _total = 47;
  Timer? _timer;
  bool _fullscreen = false;
  final _scroll = ScrollController();

  int get _activeIdx => _lyrics.indexWhere((l) => _time >= l.lineStart && _time < l.lineEnd);
  int get _activeWord {
    if (_activeIdx < 0) return 0;
    final l = _lyrics[_activeIdx];
    if (l.words.isEmpty) return 0;
    final elapsed = _time - l.lineStart;
    final dur = (l.lineEnd - l.lineStart) / l.words.length;
    return (elapsed / dur).floor().clamp(0, l.words.length - 1);
  }

  @override
  void initState() {
    super.initState();
    if (widget.transcriptionJobId != null) _load();
  }

  @override
  void didUpdateWidget(KaraokeScreen old) {
    super.didUpdateWidget(old);
    if (widget.transcriptionJobId != old.transcriptionJobId &&
        widget.transcriptionJobId != null) _load();
  }

  @override
  void dispose() { _timer?.cancel(); _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final job = await ApiService.getJob(widget.transcriptionJobId!);
      if (job.isDone) setState(() { _lyrics = ApiService.parseLyrics(job); });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        setState(() {
          _time += 0.1;
          if (_time >= _total) { _time = 0; _playing = false; _timer?.cancel(); }
        });
      });
    } else { _timer?.cancel(); }
  }

  String _fmt(double s) => '${s~/60}:${(s%60).toInt().toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    if (_fullscreen) return _buildFullscreen();
    return Scaffold(
      backgroundColor: BksColors.bg0,
      appBar: AppBar(title: const Text('KARAOKE'), actions: [
        if (_lyrics.isNotEmpty) IconButton(
          icon: const Icon(Icons.fullscreen, color: BksColors.gold),
          onPressed: () {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            setState(() => _fullscreen = true);
          }),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: BksColors.gold))
          : _lyrics.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lyrics_outlined, size: 64, color: BksColors.textMuted),
                  const SizedBox(height: 16),
                  Text(widget.transcriptionJobId != null ? 'Се вчитува...' : 'Транскрибирај текст во Mixer',
                      style: const TextStyle(color: BksColors.textMuted, fontSize: 15)),
                ]))
              : Column(children: [
                  Expanded(child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    itemCount: _lyrics.length,
                    itemBuilder: (_, i) {
                      final line = _lyrics[i];
                      final isActive = i == _activeIdx;
                      final isPast = _time > line.lineEnd;
                      return GestureDetector(
                        onTap: () => setState(() => _time = line.lineStart),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 72, margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF13122A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isActive ? Border.all(color: BksColors.gold.withOpacity(0.3))
                                : Border.all(color: Colors.transparent),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (isActive && line.words.isNotEmpty)
                              Wrap(spacing: 4, children: List.generate(line.words.length, (wi) =>
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 100),
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                                    color: wi == _activeWord ? BksColors.gold
                                        : wi < _activeWord ? BksColors.textSecondary : BksColors.textPrimary,
                                    shadows: wi == _activeWord
                                        ? [Shadow(color: BksColors.gold.withOpacity(0.5), blurRadius: 10)]
                                        : null),
                                  child: Text(line.words[wi]))))
                            else
                              Text(line.text, style: TextStyle(
                                fontSize: isActive ? 19 : 15,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                color: isActive ? BksColors.textPrimary
                                    : isPast ? BksColors.textMuted.withOpacity(0.5) : BksColors.textSecondary),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (isActive) ...[
                              const SizedBox(height: 3),
                              LinearProgressIndicator(
                                value: (((_time - line.lineStart) / (line.lineEnd - line.lineStart)).clamp(0.0, 1.0)),
                                backgroundColor: BksColors.bg3, color: BksColors.gold, minHeight: 2,
                                borderRadius: BorderRadius.circular(1)),
                            ],
                          ]),
                        ),
                      );
                    })),
                  _buildTransport(),
                ]),
    );
  }

  Widget _buildTransport() => Container(
    decoration: const BoxDecoration(color: BksColors.bg1,
        border: Border(top: BorderSide(color: BksColors.border))),
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
    child: Column(children: [
      Row(children: [
        Text(_fmt(_time), style: const TextStyle(fontSize: 11, color: BksColors.textMuted)),
        Expanded(child: Slider(value: _time.clamp(0, _total), max: _total,
            onChanged: (v) => setState(() => _time = v),
            activeColor: BksColors.gold, inactiveColor: BksColors.bg3)),
        Text(_fmt(_total), style: const TextStyle(fontSize: 11, color: BksColors.textMuted)),
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: () => setState(() => _time = 0),
            icon: const Icon(Icons.skip_previous_rounded, color: BksColors.textSecondary, size: 30)),
        const SizedBox(width: 12),
        GestureDetector(onTap: _togglePlay,
          child: Container(width: 54, height: 54,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: BksColors.gold),
            child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: BksColors.textInverse, size: 30))),
        const SizedBox(width: 12),
        IconButton(onPressed: () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          setState(() => _fullscreen = true);
        }, icon: const Icon(Icons.fullscreen_rounded, color: BksColors.gold, size: 28)),
      ]),
    ]),
  );

  Widget _buildFullscreen() => Scaffold(
    backgroundColor: Colors.black,
    body: GestureDetector(onTap: _togglePlay,
      child: Stack(fit: StackFit.expand, children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(
            center: Alignment.bottomCenter, radius: 1.2,
            colors: [Color(0xFF1A1000), Colors.black]))),
        Positioned(left: 24, right: 24, top: 0, bottom: 0,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_activeIdx > 0) Text(_lyrics[_activeIdx - 1].text,
                style: const TextStyle(fontFamily: 'serif', fontSize: 18,
                    color: Color(0xFF1A1600)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_activeIdx >= 0) ...[
              Wrap(spacing: 6, alignment: WrapAlignment.center,
                children: List.generate(_lyrics[_activeIdx].words.length, (wi) =>
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 80),
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900,
                      color: wi == _activeWord ? BksColors.gold
                          : wi < _activeWord ? const Color(0xFFBB8820) : Colors.white,
                      shadows: wi == _activeWord
                          ? [Shadow(color: BksColors.gold.withOpacity(0.6), blurRadius: 20)] : null),
                    child: Text(_lyrics[_activeIdx].words[wi])))),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: ((_time - _lyrics[_activeIdx].lineStart) /
                    (_lyrics[_activeIdx].lineEnd - _lyrics[_activeIdx].lineStart)).clamp(0.0, 1.0),
                backgroundColor: Colors.white12, color: BksColors.gold, minHeight: 2),
            ],
            const SizedBox(height: 16),
            if (_activeIdx >= 0 && _activeIdx + 1 < _lyrics.length)
              Text(_lyrics[_activeIdx + 1].text,
                  style: const TextStyle(fontSize: 20, color: Color(0xFF554A30)),
                  textAlign: TextAlign.center),
          ])),
        Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(child: Row(children: [
            IconButton(onPressed: () {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              setState(() => _fullscreen = false);
            }, icon: const Icon(Icons.fullscreen_exit, color: Colors.white38, size: 28)),
          ]))),
        Positioned(bottom: 0, left: 0, right: 0,
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              Text(_fmt(_time), style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 10),
              Expanded(child: SliderTheme(
                data: const SliderThemeData(trackHeight: 2,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6)),
                child: Slider(value: _time.clamp(0, _total), max: _total,
                    onChanged: (v) => setState(() => _time = v),
                    activeColor: BksColors.gold, inactiveColor: Colors.white10))),
              const SizedBox(width: 10),
              Text(_fmt(_total), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ])))),
      ])),
  );
}
