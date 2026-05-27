class Job {
  final String id;
  final String type;
  final String status;
  final int progress;
  final String message;
  final Map<String, dynamic>? result;
  final String? error;

  const Job({required this.id, required this.type, required this.status,
      required this.progress, required this.message, this.result, this.error});

  factory Job.fromJson(Map<String, dynamic> j) => Job(
    id: j['id'] ?? '', type: j['type'] ?? '',
    status: j['status'] ?? 'queued', progress: j['progress'] ?? 0,
    message: j['message'] ?? '', result: j['result'], error: j['error'],
  );

  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing' || status == 'queued';
}

class LyricLine {
  final double lineStart;
  final double lineEnd;
  final String text;
  final List<String> words;

  const LyricLine({required this.lineStart, required this.lineEnd,
      required this.text, required this.words});

  factory LyricLine.fromJson(Map<String, dynamic> j) => LyricLine(
    lineStart: (j['line_start'] ?? 0).toDouble(),
    lineEnd: (j['line_end'] ?? 0).toDouble(),
    text: j['text'] ?? '',
    words: (j['words'] as List? ?? [])
        .map((w) => (w['word'] ?? '').toString().trim())
        .where((w) => w.isNotEmpty)
        .toList(),
  );
}

class AudioAnalysis {
  final double bpm;
  final String key;
  final String mode;
  final double durationSeconds;

  const AudioAnalysis({required this.bpm, required this.key,
      required this.mode, required this.durationSeconds});

  factory AudioAnalysis.fromJson(Map<String, dynamic> j) => AudioAnalysis(
    bpm: (j['bpm'] ?? 0).toDouble(), key: j['key'] ?? '',
    mode: j['mode'] ?? '', durationSeconds: (j['duration_seconds'] ?? 0).toDouble(),
  );
}

const bksLanguages = [
  {'code': 'auto', 'label': 'Auto', 'flag': '🌐'},
  {'code': 'mk',   'label': 'Македонски', 'flag': '🇲🇰'},
  {'code': 'sr',   'label': 'Srpski',     'flag': '🇷🇸'},
  {'code': 'hr',   'label': 'Hrvatski',   'flag': '🇭🇷'},
  {'code': 'bs',   'label': 'Bosanski',   'flag': '🇧🇦'},
  {'code': 'en',   'label': 'English',    'flag': '🇬🇧'},
];
