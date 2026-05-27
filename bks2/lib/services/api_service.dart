import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/models.dart';

class ApiService {
  // ⚠️ Promeni ova na IP na tvojot server!
  // Za emulator: 'http://10.0.2.2:8000'
  // Za realen ureд: 'http://192.168.1.XXX:8000'
  static const String baseUrl = 'http://10.0.2.2:8000';

  static String fileUrl(String path) => '$baseUrl$path';

  static Future<String> uploadAndSeparate(File audioFile) async {
    final request = http.MultipartRequest('POST',
        Uri.parse('$baseUrl/api/stems/separate'));
    final ext = audioFile.path.split('.').last.toLowerCase();
    request.files.add(await http.MultipartFile.fromPath(
        'file', audioFile.path,
        contentType: MediaType.parse(_mime(ext))));
    final response = await request.send();
    if (response.statusCode != 200) throw Exception('Upload failed');
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['job_id'] as String;
  }

  static Future<Job> getJob(String jobId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/jobs/$jobId'));
    if (res.statusCode != 200) throw Exception('Job not found');
    return Job.fromJson(jsonDecode(res.body));
  }

  static Future<Job> pollJob(String jobId,
      {void Function(Job)? onProgress}) async {
    while (true) {
      final job = await getJob(jobId);
      onProgress?.call(job);
      if (job.isDone || job.isFailed) return job;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  static Future<String> startTranscription(
      {required String stemJobId, required String language}) async {
    final res = await http.post(Uri.parse('$baseUrl/api/transcribe/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'job_id': stemJobId, 'language': language,
            'word_timestamps': true}));
    if (res.statusCode != 200) throw Exception('Transcription failed');
    return jsonDecode(res.body)['job_id'] as String;
  }

  static List<LyricLine> parseLyrics(Job job) {
    final list = job.result?['karaoke_json'] as List? ?? [];
    return list.map((e) => LyricLine.fromJson(e)).toList();
  }

  static Future<String> startTranspose(
      {required String stemJobId, required double semitones}) async {
    final res = await http.post(Uri.parse('$baseUrl/api/transpose/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'job_id': stemJobId, 'semitones': semitones}));
    if (res.statusCode != 200) throw Exception('Transpose failed');
    return jsonDecode(res.body)['job_id'] as String;
  }

  static Future<String> startExport(
      {required String stemJobId, String format = 'mp3',
       String bitrate = '320k', bool includeStems = false,
       bool exportKetron = false, String title = '', String artist = ''}) async {
    final res = await http.post(Uri.parse('$baseUrl/api/export/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'job_id': stemJobId, 'format': format,
            'bitrate': bitrate, 'include_stems': includeStems,
            'export_ketron': exportKetron, 'title': title, 'artist': artist}));
    if (res.statusCode != 200) throw Exception('Export failed');
    return jsonDecode(res.body)['job_id'] as String;
  }

  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  static String _mime(String ext) {
    switch (ext) {
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'flac': return 'audio/flac';
      case 'm4a': return 'audio/mp4';
      default: return 'audio/mpeg';
    }
  }
}
