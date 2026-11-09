import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pipes/data/services/link_sniffer.dart';
import 'package:pipes/domain/models/app_settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.author,
    required this.path,
  });

  final String id;
  final String title;
  final String author;
  final String path;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'path': path,
      };

  factory MusicTrack.fromMap(Map<dynamic, dynamic> m) => MusicTrack(
        id: (m['id'] ?? '') as String,
        title: (m['title'] ?? 'Unknown') as String,
        author: (m['author'] ?? '') as String,
        path: (m['path'] ?? '') as String,
      );
}

/// Playlist + player + YouTube downloader (audio only, saved on the device).
class MusicController extends ChangeNotifier {
  MusicController();

  static const String _boxName = 'pipes_settings';
  static const String _playlistKey = 'playlist';

  final AudioPlayer _player = AudioPlayer();
  final List<MusicTrack> _tracks = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _status;
  bool _initialized = false;
  bool _disposed = false;
  bool _shuffle = false;
  bool _repeatOne = false;
  final List<String> _log = [];
  final Stopwatch _logClock = Stopwatch();
  String? _pendingLabel;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  double _speedBps = 0;

  /// Parallel connections / chunk size used for fast downloads.
  /// Parallel ranged download is switched off: YouTube answers it with 403.
  /// The library's own download is used instead (flip to true to experiment).
  static const bool _useParallel = false;
  static const int _workers = 6;
  static const int _chunkSize = 512 * 1024;

  List<String> get log => List.unmodifiable(_log);
  String? get pendingLabel => _pendingLabel;

  void _addLog(String m) {
    final t = _logClock.elapsed.inSeconds.toString().padLeft(3);
    _log.add('[${t}s] $m');
    if (_log.length > 60) _log.removeAt(0);
    _notify();
  }

  int get downloadedBytes => _downloadedBytes;
  int get totalBytes => _totalBytes;
  double get speedBytesPerSecond => _speedBps;
  int? get etaSeconds {
    if (_speedBps < 1 || _totalBytes <= 0) return null;
    return ((_totalBytes - _downloadedBytes) / _speedBps).ceil();
  }

  List<MusicTrack> get tracks => List.unmodifiable(_tracks);
  int get currentIndex => _currentIndex;
  MusicTrack? get current =>
      (_currentIndex >= 0 && _currentIndex < _tracks.length)
          ? _tracks[_currentIndex]
          : null;
  bool get isPlaying => _isPlaying;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get status => _status;
  bool get shuffle => _shuffle;
  bool get repeatOne => _repeatOne;
  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final box = Hive.box(_boxName);
      final raw = box.get(_playlistKey, defaultValue: const []) as List;
      for (final item in raw) {
        if (item is Map) {
          final t = MusicTrack.fromMap(item);
          // Skip tracks whose file was deleted from the phone.
          if (t.path.isNotEmpty && File(t.path).existsSync()) {
            _tracks.add(t);
          }
        }
      }
    } catch (_) {}

    _player.playerStateStream.listen((s) {
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (playing != _isPlaying) {
        _isPlaying = playing;
        _notify();
      }
      if (s.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      _status = 'Playback error: $e';
      _isPlaying = false;
      _notify();
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _savePlaylist() async {
    try {
      await Hive.box(_boxName)
          .put(_playlistKey, _tracks.map((t) => t.toMap()).toList());
    } catch (_) {}
  }

  void _onTrackCompleted() {
    if (_tracks.isEmpty) return;
    if (_repeatOne) {
      playIndex(_currentIndex);
    } else {
      next();
    }
  }

  Future<void> playIndex(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final track = _tracks[index];
    try {
      _currentIndex = index;
      _status = null;
      _notify();
      await _player.setFilePath(track.path);
      await _player.play();
    } catch (e) {
      _status = 'Cannot play "${track.title}": $e';
      _isPlaying = false;
      _notify();
    }
  }

  Future<void> togglePlayPause() async {
    if (_tracks.isEmpty) return;
    if (current == null) {
      await playIndex(0);
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> next() async {
    if (_tracks.isEmpty) return;
    int nextIndex;
    if (_shuffle && _tracks.length > 1) {
      nextIndex = (DateTime.now().millisecondsSinceEpoch % _tracks.length);
      if (nextIndex == _currentIndex) {
        nextIndex = (nextIndex + 1) % _tracks.length;
      }
    } else {
      nextIndex = (_currentIndex + 1) % _tracks.length;
    }
    await playIndex(nextIndex);
  }

  Future<void> previous() async {
    if (_tracks.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    final prev = (_currentIndex - 1) < 0 ? _tracks.length - 1 : _currentIndex - 1;
    await playIndex(prev);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _notify();
  }

  void toggleRepeatOne() {
    _repeatOne = !_repeatOne;
    _notify();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final removed = _tracks[index];
    final wasCurrent = index == _currentIndex;

    _tracks.removeAt(index);
    if (wasCurrent) {
      await _player.stop();
      _currentIndex = -1;
    } else if (index < _currentIndex) {
      _currentIndex -= 1;
    }
    try {
      final f = File(removed.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await _savePlaylist();
    _notify();
  }

  /// Starts the playlist if nothing is playing yet.
  Future<void> startIfIdle() async {
    if (_tracks.isEmpty || _isPlaying) return;
    await playIndex(_currentIndex >= 0 ? _currentIndex : 0);
  }

  Future<void> pause() async {
    if (_player.playing) await _player.pause();
  }

  /// Picks the audio stream that matches the chosen [quality].
  /// Smaller streams = much faster download.
  AudioStreamInfo _pickStream(
    Iterable<AudioStreamInfo> streams,
    AudioQuality quality,
  ) {
    // Copy into an explicit List<AudioStreamInfo>: the manifest hands out a
    // List<AudioOnlyStreamInfo>, and `orElse` below would then fail its
    // runtime type check.
    final all = List<AudioStreamInfo>.from(streams);
    final mp4 = all.where((s) => s.container.name.toLowerCase() == 'mp4').toList();
    final pool = List<AudioStreamInfo>.of(mp4.isNotEmpty ? mp4 : all);
    pool.sort((a, b) => a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
    switch (quality) {
      case AudioQuality.fast:
        return pool.first;
      case AudioQuality.high:
        return pool.last;
      case AudioQuality.normal:
        return pool.firstWhere(
          (s) => s.bitrate.bitsPerSecond >= 100000,
          orElse: () => pool.last,
        );
    }
  }

  /// Downloads [url] with several parallel ranged requests (this is what
  /// makes it fast: YouTube throttles a single connection).
  Future<void> _downloadParallel(
    Uri url,
    int total,
    File file,
    Stopwatch watch,
  ) async {
    final raf = await file.open(mode: FileMode.write);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..maxConnectionsPerHost = _workers + 2;
    try {
      final chunkCount = (total / _chunkSize).ceil();
      var nextChunk = 0;
      var writeQueue = Future<void>.value();
      var lastNotifyMs = 0;
      var cancelled = false;

      Future<void> fetchChunk(int index) async {
        final start = index * _chunkSize;
        final end = (start + _chunkSize - 1) < total ? start + _chunkSize - 1 : total - 1;
        final expected = end - start + 1;
        Object? lastError;
        for (var attempt = 0; attempt < 2; attempt++) {
          if (cancelled) return;
          var got = 0;
          try {
            // Same request shape the library itself uses: ANDROID urls take
            // a Range header, every other client takes a `range` query param.
            // A bare dart:io request (Dart user-agent, no cookie) gets 403.
            final isAndroid = url.queryParameters['c'] == 'ANDROID';
            final reqUri = isAndroid
                ? url
                : url.replace(
                    queryParameters: {
                      ...url.queryParameters,
                      'range': '$start-$end',
                    },
                  );
            final req = await client.getUrl(reqUri);
            YoutubeHttpClient.defaultHeaders.forEach(req.headers.set);
            if (isAndroid) req.headers.set('Range', 'bytes=$start-$end');
            final res = await req.close().timeout(const Duration(seconds: 10));
            if (res.statusCode != 200 && res.statusCode != 206) {
              // Keep a short piece of the answer – it tells why YouTube said no.
              var body = '';
              try {
                final bytes = await res
                    .fold<List<int>>(<int>[], (a, b) => a.length < 300 ? (a..addAll(b)) : a)
                    .timeout(const Duration(seconds: 3));
                body = String.fromCharCodes(bytes.take(200))
                    .replaceAll(RegExp(r'\s+'), ' ');
              } catch (_) {}
              throw HttpException(
                'HTTP ${res.statusCode} '
                '[c=${url.queryParameters['c']} '
                'ratebypass=${url.queryParameters['ratebypass']} '
                'clen=${url.queryParameters['clen']} '
                'range=$start-$end '
                'ct=${res.headers.contentType}] $body',
              );
            }
            final bb = BytesBuilder(copy: false);
            await for (final c in res.timeout(const Duration(seconds: 10))) {
              if (cancelled) throw const HttpException('cancelled');
              bb.add(c);
              got += c.length;
              _downloadedBytes += c.length;
            }
            final bytes = bb.takeBytes();
            if (bytes.length != expected) {
              throw HttpException('Bad chunk size ${bytes.length} != $expected');
            }
            writeQueue = writeQueue.then((_) async {
              await raf.setPosition(start);
              await raf.writeFrom(bytes);
            });
            await writeQueue;

            final ms = watch.elapsedMilliseconds;
            if (ms - lastNotifyMs > 350) {
              lastNotifyMs = ms;
              _speedBps = ms > 0 ? _downloadedBytes * 1000 / ms : 0;
              _downloadProgress = (_downloadedBytes / total).clamp(0.0, 1.0);
              _notify();
            }
            return;
          } catch (e) {
            if (cancelled) return;
            lastError = e;
            _downloadedBytes -= got; // this chunk will be re-downloaded
          }
        }
        throw lastError ?? Exception('chunk failed');
      }

      Future<void> worker() async {
        while (!cancelled) {
          final i = nextChunk++;
          if (i >= chunkCount) return;
          await fetchChunk(i);
        }
      }

      try {
        await Future.wait(
          List.generate(_workers, (_) => worker()),
          eagerError: true,
        );
      } catch (_) {
        cancelled = true;
        rethrow;
      }
      await writeQueue;
      await raf.flush();
    } finally {
      client.close(force: true);
      await raf.close();
    }
  }

  /// User-Agent that matches the YouTube client the stream URL came from.
  /// The CDN often answers 403 when the agent doesn't match the client.
  static String? _uaForClient(String? c) {
    switch (c) {
      case 'ANDROID':
        return 'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip';
      case 'ANDROID_VR':
        return 'com.google.android.apps.youtube.vr.oculus/1.56.21 '
            '(Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip';
      case 'IOS':
        return 'com.google.ios.youtube/20.10.4 '
            '(iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)';
    }
    return null;
  }

  /// Own single-connection downloader. Fetches the file in 2 MB ranged pieces,
  /// tries the matching User-Agent first, then the browser one, and writes
  /// every HTTP status into the log so a failure can be understood.
  Future<void> _downloadDirect(
    Uri url,
    int total,
    File file,
    Stopwatch watch,
  ) async {
    const piece = 2 * 1024 * 1024;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    final c = url.queryParameters['c'];
    final isAndroid = c == 'ANDROID';
    final agents = <String>{
      if (_uaForClient(c) != null) _uaForClient(c)!,
      YoutubeHttpClient.defaultHeaders['user-agent']!,
    }.toList();
    _addLog('Direct: client c=$c, ratebypass=${url.queryParameters['ratebypass']}');

    Future<HttpClientResponse> open(String ua, int start, int end) async {
      final uri = isAndroid
          ? url
          : url.replace(
              queryParameters: {...url.queryParameters, 'range': '$start-$end'},
            );
      final req = await client.getUrl(uri);
      YoutubeHttpClient.defaultHeaders.forEach(req.headers.set);
      req.headers.set('user-agent', ua);
      if (isAndroid) req.headers.set('Range', 'bytes=$start-$end');
      return req.close().timeout(const Duration(seconds: 15));
    }

    final sink = file.openWrite();
    try {
      String? ua;
      var pos = 0;
      var nextLogPct = 25;
      while (pos < total) {
        final end = (pos + piece - 1) < total ? pos + piece - 1 : total - 1;
        HttpClientResponse? res;
        if (ua == null) {
          // First piece: find a User-Agent the server accepts.
          for (var i = 0; i < agents.length; i++) {
            final r = await open(agents[i], pos, end);
            _addLog('Direct: UA#${i + 1} -> HTTP ${r.statusCode}');
            if (r.statusCode == 200 || r.statusCode == 206) {
              ua = agents[i];
              res = r;
              break;
            }
            try {
              final b = await r
                  .fold<List<int>>(<int>[], (a, d) => a.length < 300 ? (a..addAll(d)) : a)
                  .timeout(const Duration(seconds: 3));
              _addLog(
                'Direct: body: '
                '${String.fromCharCodes(b.take(160)).replaceAll(RegExp(r'\s+'), ' ')}',
              );
            } catch (_) {}
          }
          if (res == null) throw const HttpException('Direct: all User-Agents refused');
        } else {
          res = await open(ua, pos, end);
          if (res.statusCode != 200 && res.statusCode != 206) {
            throw HttpException('Direct: HTTP ${res.statusCode} at byte $pos');
          }
        }

        final expected = end - pos + 1;
        var got = 0;
        await for (final d in res.timeout(const Duration(seconds: 15))) {
          sink.add(d);
          got += d.length;
          _downloadedBytes += d.length;
          final ms = watch.elapsedMilliseconds;
          _speedBps = ms > 0 ? _downloadedBytes * 1000 / ms : 0;
          _downloadProgress = (_downloadedBytes / total).clamp(0.0, 1.0);
          _notify();
        }
        if (pos == 0) _addLog('Direct: first piece ok after ${watch.elapsedMilliseconds} ms');
        // A server that ignored the range sends the whole file with 200.
        if (res.statusCode == 200 && got >= total) {
          pos = total;
        } else {
          if (got != expected) {
            throw HttpException('Direct: short piece $got != $expected');
          }
          pos += got;
        }
        final pct = pos * 100 ~/ total;
        if (pct >= nextLogPct) {
          _addLog('Direct: $pct%  ${(pos / 1024).round()} KB');
          nextLogPct += 25;
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
      client.close(force: true);
    }
  }

  /// Fallback: the normal single-connection download of the library.
  Future<void> _downloadSequential(
    YoutubeExplode yt,
    AudioStreamInfo streamInfo,
    File file,
    Stopwatch watch,
  ) async {
    final sink = file.openWrite();
    try {
      final total = streamInfo.size.totalBytes;
      var lastNotifyMs = 0;
      var gotFirst = false;
      var nextLogPct = 25;
      await for (final chunk in yt.videos.streams
          .get(streamInfo)
          .timeout(const Duration(seconds: 12))) {
        if (!gotFirst) {
          gotFirst = true;
          _addLog('Normal: first bytes after ${watch.elapsedMilliseconds} ms');
        }
        _downloadedBytes += chunk.length;
        if (total > 0) {
          final pct = _downloadedBytes * 100 ~/ total;
          if (pct >= nextLogPct) {
            _addLog('Normal: $pct%  ${(_downloadedBytes / 1024).round()} KB');
            nextLogPct += 25;
          }
        }
        sink.add(chunk);
        final ms = watch.elapsedMilliseconds;
        if (ms - lastNotifyMs > 350 && total > 0) {
          lastNotifyMs = ms;
          _speedBps = ms > 0 ? _downloadedBytes * 1000 / ms : 0;
          _downloadProgress = (_downloadedBytes / total).clamp(0.0, 1.0);
          _notify();
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Adds audio files from the phone (picked with the file picker).
  /// Each file is copied into the app folder so it keeps working later.
  /// Returns null when OK, otherwise an error message.
  Future<String?> addLocalFiles(
    List<({String path, String name})> files, {
    bool playAfter = true,
  }) async {
    if (files.isEmpty) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      final firstNew = _tracks.length;
      var added = 0;
      for (final f in files) {
        final src = File(f.path);
        if (!await src.exists()) continue;
        final dot = f.name.lastIndexOf('.');
        final ext = dot > 0 ? f.name.substring(dot) : '.mp3';
        final title = dot > 0 ? f.name.substring(0, dot) : f.name;
        final id = 'local_${DateTime.now().microsecondsSinceEpoch}_$added';
        final dest = File('${musicDir.path}/$id$ext');
        await src.copy(dest.path);
        _tracks.add(
          MusicTrack(id: id, title: title, author: 'My phone', path: dest.path),
        );
        added++;
      }
      if (added == 0) return 'File එක කියවන්න බැරි උනා.';
      await _savePlaylist();
      _status = 'සිංදු $added ක් add උනා ✓';
      _notify();
      if (playAfter) await playIndex(firstNew);
      return null;
    } catch (e) {
      return 'සිංදු add කරන්න බැරි උනා.\n($e)';
    }
  }

  static bool _isYoutubeLink(String link) {
    final u = Uri.tryParse(link.trim());
    final h = (u?.host ?? '').toLowerCase();
    return h == 'youtu.be' || h.endsWith('youtube.com') || h.endsWith('youtube-nocookie.com');
  }

  /// Cookies seen while following a link (token-protected stream URLs need the
  /// session cookie the web page set) and the page to send as Referer.
  final Map<String, Map<String, String>> _jar = {};
  String? _fetchReferer;

  static const String _browserUa =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  /// Turns "share page" links (Google Drive, Dropbox) into direct-download ones.
  static Uri _normalizeShareLink(Uri u) {
    final host = u.host.toLowerCase();
    if (host == 'drive.google.com' || host == 'docs.google.com') {
      final m = RegExp(r'/d/([A-Za-z0-9_-]+)').firstMatch(u.path);
      final id = m?.group(1) ?? u.queryParameters['id'];
      if (id != null) {
        return Uri.parse(
          'https://drive.usercontent.google.com/download?id=$id&export=download&confirm=t',
        );
      }
    }
    if (host.endsWith('dropbox.com')) {
      return u.replace(queryParameters: {...u.queryParameters, 'dl': '1'});
    }
    return u;
  }

  /// GET with browser-like headers; follows redirects by hand so the final
  /// URL is known (needed for the fast ranged download).
  Future<({HttpClientResponse res, Uri url})> _fetch(
    HttpClient client,
    Uri uri, {
    int? rangeStart,
    int? rangeEnd,
  }) async {
    var cur = uri;
    for (var hop = 0; hop < 8; hop++) {
      final req = await client.getUrl(cur).timeout(const Duration(seconds: 20));
      req.followRedirects = false;
      req.headers.set('user-agent', _browserUa);
      req.headers.set('accept', '*/*');
      req.headers.set('accept-language', 'en-US,en;q=0.8');
      req.headers.set('referer', _fetchReferer ?? '${uri.scheme}://${uri.host}/');
      final saved = _jar[cur.host];
      if (saved != null && saved.isNotEmpty) {
        req.headers.set('cookie', saved.entries.map((e) => '${e.key}=${e.value}').join('; '));
      }
      if (rangeStart != null) {
        req.headers.set('range', 'bytes=$rangeStart-${rangeEnd ?? ''}');
      }
      final res = await req.close().timeout(const Duration(seconds: 20));
      try {
        for (final c in res.cookies) {
          (_jar[cur.host] ??= {})[c.name] = c.value;
        }
      } catch (_) {}
      if (res.isRedirect) {
        final loc = res.headers.value('location');
        await res.drain<void>();
        if (loc == null) throw const HttpException('Redirect එකේ location නෑ');
        cur = cur.resolve(loc);
        continue;
      }
      return (res: res, url: cur);
    }
    throw const HttpException('Redirects ගොඩක්');
  }

  Future<String> _readText(HttpClientResponse res, {int maxBytes = 3 * 1024 * 1024}) async {
    final b = BytesBuilder(copy: false);
    await for (final d in res.timeout(const Duration(seconds: 20))) {
      b.add(d);
      if (b.length >= maxBytes) break;
    }
    return utf8.decode(b.takeBytes(), allowMalformed: true);
  }

  static String _decodeEntities(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  static String? _pageTitle(String html) {
    final og = RegExp(
      r"""<meta[^>]+property=["']og:title["'][^>]*content=["']([^"']+)["']""",
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    final t = og ??
        RegExp(r'<title[^>]*>([^<]{1,200})</title>', caseSensitive: false)
            .firstMatch(html)
            ?.group(1);
    if (t == null) return null;
    final c = _decodeEntities(t).replaceAll(RegExp(r'\s+'), ' ').trim();
    return c.isEmpty ? null : (c.length > 90 ? c.substring(0, 90) : c);
  }

  /// YouTube links mentioned on a page (used as a fallback).
  static List<String> _findYoutubeLinks(String html) {
    final t = html.replaceAll(r'\/', '/');
    final ids = <String>{};
    for (final m in RegExp(
      r'https?://(?:www\.|m\.)?(?:youtube\.com/(?:watch\?v=|embed/)|youtu\.be/)([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    ).allMatches(t)) {
      ids.add(m.group(1)!);
    }
    return [for (final id in ids) 'https://www.youtube.com/watch?v=$id'];
  }

  /// Finds links to audio files inside a web page (best guesses first).
  static List<Uri> _findAudioLinks(String html, Uri base) {
    final raw = <String>[];
    void add(String? v) {
      if (v == null) return;
      final s = v
          .trim()
          .replaceAll(r'\/', '/')
          .replaceAll(r'&', '&')
          .replaceAll('&amp;', '&');
      if (s.isEmpty || s.startsWith('data:') || s.startsWith('blob:')) return;
      raw.add(s);
    }

    // 1) social-preview meta tags
    for (final m in RegExp(
      r"""<meta[^>]+(?:property|name)=["'](?:og:audio(?::url|:secure_url)?|twitter:player:stream)["'][^>]*>""",
      caseSensitive: false,
    ).allMatches(html)) {
      add(RegExp(r"""content=["']([^"']+)["']""", caseSensitive: false)
          .firstMatch(m.group(0)!)
          ?.group(1));
    }
    // 2) <audio src> / <source src>
    for (final m in RegExp(
      r"""<(?:audio|source)[^>]+src=["']([^"']+)["']""",
      caseSensitive: false,
    ).allMatches(html)) {
      add(m.group(1));
    }
    // 3) href/src/data-* attributes that end in an audio extension
    for (final m in RegExp(
      r"""(?:href|src|data-src|data-url|data-mp3|data-audio)=["']([^"']+?\.(?:mp3|m4a|aac|ogg|opus|wav|flac)(?:\?[^"']*)?)["']""",
      caseSensitive: false,
    ).allMatches(html)) {
      add(m.group(1));
    }
    // 4) any absolute audio URL, also inside JSON / JavaScript (with \/ escapes)
    for (final m in RegExp(
      r"""https?:\\?/\\?/[^"'\s<>()]+?\.(?:mp3|m4a|aac|ogg|opus|wav|flac)(?:\?[^"'\s<>()]*)?""",
      caseSensitive: false,
    ).allMatches(html)) {
      add(m.group(0));
    }

    // 5) "download"-style links (the file may have no .mp3 extension)
    final hint = RegExp(r'download|mp3|audio|/dl/|\.php|/file', caseSensitive: false);
    for (final m in RegExp(
      r"""<a\s[^>]*href=["']([^"'#][^"']*)["'][^>]*>([\s\S]{0,160}?)</a>""",
      caseSensitive: false,
    ).allMatches(html)) {
      final href = m.group(1)!;
      if (href.startsWith('javascript:') || href.startsWith('mailto:') || href.startsWith('tel:')) {
        continue;
      }
      final label = (m.group(2) ?? '').replaceAll(RegExp(r'<[^>]*>'), ' ');
      if (hint.hasMatch(href) || hint.hasMatch(label)) add(href);
    }

    final out = <Uri>[];
    final seen = <String>{};
    for (final r in raw) {
      Uri? u;
      try {
        u = base.resolve(r);
      } catch (_) {
        continue;
      }
      if (!(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) continue;
      if (seen.add(u.toString())) out.add(u);
      if (out.length >= 8) break;
    }
    return out;
  }

  /// Fast download: the file is cut into pieces which are fetched by several
  /// connections at the same time (this is what makes it quick).
  Future<void> _parallelRanged(
    HttpClient client,
    Uri url,
    int total,
    File file,
    Stopwatch watch,
  ) async {
    const workers = 8;
    final chunk = (total ~/ 12).clamp(512 * 1024, 4 * 1024 * 1024);
    final count = (total / chunk).ceil();
    final raf = await file.open(mode: FileMode.write);
    var lock = Future<void>.value();
    var next = 0;
    var aborted = false;
    var lastNotify = 0;

    Future<void> writeAt(int off, Uint8List data) async {
      final prev = lock;
      final c = Completer<void>();
      lock = c.future;
      await prev;
      try {
        await raf.setPosition(off);
        await raf.writeFrom(data);
      } finally {
        c.complete();
      }
    }

    Future<void> worker() async {
      while (!aborted) {
        final i = next++;
        if (i >= count) return;
        final start = i * chunk;
        final end = (start + chunk - 1) < total ? start + chunk - 1 : total - 1;
        final expected = end - start + 1;
        for (var attempt = 0;; attempt++) {
          var got = 0;
          try {
            final r = await _fetch(client, url, rangeStart: start, rangeEnd: end);
            if (r.res.statusCode != 206) {
              await r.res.drain<void>();
              throw HttpException('Range එක පිළිගත්තේ නෑ (HTTP ${r.res.statusCode})');
            }
            final bb = BytesBuilder(copy: false);
            await for (final d in r.res.timeout(const Duration(seconds: 20))) {
              if (aborted) return;
              bb.add(d);
              got += d.length;
              _downloadedBytes += d.length;
              final ms = watch.elapsedMilliseconds;
              if (ms - lastNotify > 120) {
                lastNotify = ms;
                _speedBps = ms > 0 ? _downloadedBytes * 1000 / ms : 0;
                _downloadProgress = (_downloadedBytes / total).clamp(0.0, 1.0);
                _notify();
              }
            }
            if (got != expected) throw const HttpException('කෑල්ල අසම්පූර්ණයි');
            await writeAt(start, bb.takeBytes());
            break;
          } catch (e) {
            _downloadedBytes -= got;
            if (attempt >= 2) rethrow;
            await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          }
        }
      }
    }

    try {
      await Future.wait(List.generate(workers, (_) => worker()), eagerError: true);
      await raf.flush();
    } catch (_) {
      aborted = true;
      rethrow;
    } finally {
      await raf.close();
    }
  }

  /// Takes ANY link – a direct .mp3 link, or a normal web page (for example a
  /// result from a Google search) – finds the audio file, downloads it fast
  /// and adds it to the playlist. Returns null when OK, otherwise an error.
  Future<String?> _addFromDirectLink(String link, {required bool playAfter}) async {
    final parsed = Uri.tryParse(link);
    if (parsed == null || !(parsed.scheme == 'http' || parsed.scheme == 'https') || parsed.host.isEmpty) {
      return 'Link එක වැරදියි. https://… වගේ link එකක් දාන්න.';
    }
    final uri = _normalizeShareLink(parsed);
    // Stable id (String.hashCode is not guaranteed to survive app restarts).
    var h = 0x811C9DC5;
    for (final b in link.codeUnits) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    final id = 'url_${h.toRadixString(16)}';
    final existing = _tracks.indexWhere((t) => t.id == id);
    if (existing != -1) {
      _status = 'මේ සිංදුව කලින්ම playlist එකේ තියෙනවා.';
      _notify();
      if (playAfter) await playIndex(existing);
      return null;
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..maxConnectionsPerHost = 12;
    File? file;
    try {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadedBytes = 0;
      _totalBytes = 0;
      _speedBps = 0;
      _log.clear();
      _logClock
        ..reset()
        ..start();
      _pendingLabel = link;
      _status = 'Link එක බලනවා…';
      _notify();
      _addLog('Start (link): $uri');

      _jar.clear();
      _fetchReferer = null;
      var first = await _fetch(client, uri);
      var res = first.res;
      var finalUrl = first.url;
      var ct = (res.headers.contentType?.mimeType ?? '').toLowerCase();
      _addLog('HTTP ${res.statusCode}  type=$ct  size=${res.contentLength}');
      if (res.statusCode != 200) {
        throw Exception('Server එක HTTP ${res.statusCode} කියලා දුන්නා');
      }

      bool isPage(String t) =>
          t.contains('html') || t.startsWith('text/') || t.contains('json') || t.contains('xml');

      String? pageTitle;
      if (isPage(ct)) {
        // A web page: look inside it for the real audio file.
        _status = 'Page එකේ සිංදුව හොයනවා…';
        _notify();
        final text = await _readText(res);
        pageTitle = _pageTitle(text);
        _fetchReferer = finalUrl.toString();
        var cands = _findAudioLinks(text, finalUrl);
        _addLog('Page title: $pageTitle');
        _addLog('Audio links found: ${cands.length}');
        for (final c in cands) {
          _addLog('  • $c');
        }
        // Nothing in the HTML itself? Many sites only reveal the mp3 after their
        // JavaScript runs / the Download button is pressed: let a hidden browser
        // do that and report the audio URLs it sees.
        if (cands.isEmpty) {
          _status = 'Page එක ඇතුළේ බොත්තම් එබිලා බලනවා…';
          _notify();
          try {
            final sn = await LinkSniffer.sniff(finalUrl, log: _addLog);
            cands = sn.urls;
            if (sn.cookies.isNotEmpty) {
              final jar = (_jar[finalUrl.host] ??= {});
              for (final part in sn.cookies.split(';')) {
                final i = part.indexOf('=');
                if (i > 0) jar[part.substring(0, i).trim()] = part.substring(i + 1).trim();
              }
            }
          } catch (e) {
            _addLog('WebView failed: $e');
          }
          _addLog('WebView candidates: ${cands.length}');
          for (final c in cands) {
            _addLog('  • $c');
          }
        }

        final yt = _findYoutubeLinks(text);
        Future<String?> viaYoutube() async {
          _addLog('Page එකේ YouTube link එකක් තියෙනවා, ඒක try කරනවා: ${yt.first}');
          _isDownloading = false;
          _status = null;
          _notify();
          return addFromYoutube(yt.first, playAfter: playAfter);
        }

        const noAudioMsg =
            'මේ page එකේ කෙලින්ම download කරන්න පුළුවන් mp3 link එකක් නෑ '
            '(Download බොත්තම JavaScript එකෙන් වැඩ කරනවා වෙන්න පුළුවන්).\n'
            'Browser එකෙන් download කරලා, "phone එකෙන් තෝරන්න" වලින් add කරන්න, '
            'නැත්නම් .mp3 එකට කෙලින්ම යන link එකක් දාන්න.';
        if (cands.isEmpty) {
          if (yt.isNotEmpty) return viaYoutube();
          throw Exception(noAudioMsg);
        }
        HttpClientResponse? good;
        for (final c in cands) {
          try {
            final r = await _fetch(client, c);
            final t = (r.res.headers.contentType?.mimeType ?? '').toLowerCase();
            _addLog('  try $c -> HTTP ${r.res.statusCode} $t');
            final audioish = t.startsWith('audio/') ||
                t.contains('ogg') ||
                t.contains('octet-stream') ||
                t.startsWith('video/') ||
                (!t.startsWith('image/') &&
                    !t.startsWith('font/') &&
                    !t.contains('javascript') &&
                    !t.contains('zip') &&
                    !t.contains('pdf') &&
                    RegExp(r'\.(?:mp3|m4a|aac|ogg|opus|wav|flac)(?:[?#]|$)', caseSensitive: false)
                        .hasMatch(r.url.toString()));
            if ((r.res.statusCode == 200 || r.res.statusCode == 206) &&
                !isPage(t) &&
                audioish &&
                r.res.contentLength != 0) {
              good = r.res;
              finalUrl = r.url;
              ct = t;
              break;
            }
            if (isPage(t)) {
              final snip = (await _readText(r.res, maxBytes: 2000))
                  .replaceAll(RegExp(r'\s+'), ' ');
              _addLog('    reply: ${snip.length > 150 ? snip.substring(0, 150) : snip}');
            } else {
              await r.res.drain<void>();
            }
          } catch (e) {
            _addLog('  try $c failed: $e');
          }
        }
        if (good == null) {
          if (yt.isNotEmpty) return viaYoutube();
          throw Exception(noAudioMsg);
        }
        res = good;
      }

      // File name / extension.
      const known = ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac', 'opus', 'webm', 'mp4'];
      final segs = finalUrl.pathSegments.where((e) => e.isNotEmpty).toList();
      var name = segs.isNotEmpty ? Uri.decodeComponent(segs.last) : 'Song';
      final dot = name.lastIndexOf('.');
      var ext = dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
      if (known.contains(ext)) {
        name = name.substring(0, dot);
      } else {
        ext = ct.contains('mp4') || ct.contains('m4a')
            ? 'm4a'
            : ct.contains('ogg')
                ? 'ogg'
                : ct.contains('wav')
                    ? 'wav'
                    : ct.contains('aac')
                        ? 'aac'
                        : 'mp3';
      }
      final title = pageTitle ?? (name.isEmpty ? 'Song' : name.replaceAll(RegExp(r'[_]+'), ' '));

      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      if (!await musicDir.exists()) await musicDir.create(recursive: true);
      file = File('${musicDir.path}/$id.$ext');

      final len = res.contentLength > 0 ? res.contentLength : 0;
      _totalBytes = len;
      _status = 'Download කරනවා…';
      _notify();
      final watch = Stopwatch()..start();

      // Does the server allow ranged requests? Then use many connections.
      final acceptsRanges =
          (res.headers.value('accept-ranges') ?? '').toLowerCase().contains('bytes');
      var useRanges = len >= 1536 * 1024 && acceptsRanges;
      if (!useRanges && len >= 1536 * 1024) {
        try {
          final p = await _fetch(client, finalUrl, rangeStart: 0, rangeEnd: 0);
          useRanges = p.res.statusCode == 206;
          await p.res.drain<void>();
        } catch (_) {}
      }
      _addLog('Size $len bytes, ranges: $useRanges');

      var done = false;
      if (useRanges) {
        await res.listen((_) {}).cancel(); // drop the first connection
        try {
          _addLog('Fast mode: 8 connections');
          await _parallelRanged(client, finalUrl, len, file, watch);
          done = true;
        } catch (e) {
          _addLog('Fast mode failed: $e');
          _downloadedBytes = 0;
          _downloadProgress = 0;
          watch.reset();
          if (await file.exists()) await file.delete();
        }
      }
      if (!done) {
        final r = useRanges ? (await _fetch(client, finalUrl)).res : res;
        final sink = file.openWrite();
        try {
          await for (final chunk in r.timeout(const Duration(seconds: 20))) {
            sink.add(chunk);
            _downloadedBytes += chunk.length;
            final ms = watch.elapsedMilliseconds;
            _speedBps = ms > 0 ? _downloadedBytes * 1000 / ms : 0;
            if (len > 0) _downloadProgress = (_downloadedBytes / len).clamp(0.0, 1.0);
            _notify();
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
      }

      final size = await file.length();
      _addLog('Downloaded ${(size / 1024).round()} KB in ${watch.elapsedMilliseconds} ms');
      if (size < 10 * 1024) throw Exception('Download උන file එක ඉතා කුඩායි');
      if (len > 0 && size != len) {
        throw Exception('File එක අසම්පූර්ණයි ($size / $len bytes)');
      }

      _tracks.add(MusicTrack(id: id, title: title, author: finalUrl.host, path: file.path));
      await _savePlaylist();
      _addLog('DONE ✓');
      _pendingLabel = null;
      _status = 'Playlist එකට add උනා ✓  $title';
      _isDownloading = false;
      _downloadProgress = 1;
      _notify();
      if (playAfter) await playIndex(_tracks.length - 1);
      return null;
    } catch (e) {
      _addLog('ERROR: $e');
      try {
        if (file != null && await file.exists()) await file.delete();
      } catch (_) {}
      _pendingLabel = null;
      _isDownloading = false;
      _status = null;
      _notify();
      return 'Download කරන්න බැරි උනා.\n($e)';
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads the audio of a YouTube link and adds it to the playlist.
  /// Tries several YouTube "clients" one after another, because YouTube
  /// blocks some of them from time to time.
  /// Returns null when OK, otherwise an error message.
  Future<String?> addFromYoutube(
    String link, {
    bool playAfter = true,
    AudioQuality quality = AudioQuality.normal,
  }) async {
    final url = link.trim();
    if (url.isEmpty) return 'Link එකක් paste කරන්න.';
    if (_isDownloading) return 'දැනටමත් download වෙමින් පවතී…';
    // Not a YouTube link? Treat it as a direct link to an audio file (.mp3 …).
    if (url.startsWith('http') && !_isYoutubeLink(url)) {
      return _addFromDirectLink(url, playAfter: playAfter);
    }

    final yt = YoutubeExplode();
    File? file;
    try {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadedBytes = 0;
      _totalBytes = 0;
      _speedBps = 0;
      _log.clear();
      _logClock
        ..reset()
        ..start();
      _pendingLabel = url;
      _status = 'Video info ගන්නවා…';
      _notify();
      _addLog('Start: $url');

      final videoId = VideoId(url);
      _addLog('Video id: ${videoId.value}');
      final existing = _tracks.indexWhere((t) => t.id == videoId.value);
      if (existing != -1) {
        _status = 'මේ සිංදුව කලින්ම playlist එකේ තියෙනවා.';
        _pendingLabel = null;
        _isDownloading = false;
        _notify();
        if (playAfter) await playIndex(existing);
        return null;
      }

      // Title is only for display, so a failure here must not stop the download.
      final Future<Video?> infoFuture = () async {
        try {
          return await yt.videos.get(videoId).timeout(const Duration(seconds: 15));
        } catch (_) {
          return null;
        }
      }();

      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      // Every client is tried in turn; the whole round is repeated once
      // so a short network hiccup doesn't fail the download.
      final baseClients = <List<YoutubeApiClient>?>[
        null, // library default (androidSdkless)
        [YoutubeApiClient.androidVr],
        [YoutubeApiClient.ios],
        [YoutubeApiClient.tv],
        [YoutubeApiClient.safari],
        [YoutubeApiClient.mweb],
        [YoutubeApiClient.android],
      ];
      final clientSets = <List<YoutubeApiClient>?>[
        ...baseClients,
        ...baseClients,
      ];

      var ok = false;
      final errors = <String>[];
      final overall = Stopwatch()..start();
      for (var ci = 0; ci < clientSets.length; ci++) {
        final clients = clientSets[ci];
        if (overall.elapsed.inSeconds > 180) {
          errors.add('time out (180s)');
          break;
        }
        try {
          _status = 'Link එක බලනවා… (${ci + 1}/${clientSets.length})'
              '${errors.isEmpty ? '' : '\nකලින් එක fail: ${errors.last}'}';
          _downloadedBytes = 0;
          _downloadProgress = 0;
          _speedBps = 0;
          _notify();

          final manifest = await yt.videos.streams
              .getManifest(videoId, ytClients: clients)
              .timeout(const Duration(seconds: 15));
          final audioStreams = manifest.audioOnly;
          _addLog('Client ${ci + 1}: audio streams = ${audioStreams.length}');
          if (audioStreams.isEmpty) throw Exception('Audio stream එකක් නෑ');
          final streamInfo = _pickStream(audioStreams, quality);
          _addLog(
            'Picked ${streamInfo.container.name} '
            '${streamInfo.bitrate.bitsPerSecond ~/ 1000}kbps '
            '${(streamInfo.size.totalBytes / 1024).round()} KB',
          );

          file = File(
            '${musicDir.path}/${videoId.value}.${streamInfo.container.name}',
          );
          if (await file.exists()) await file.delete();

          final total = streamInfo.size.totalBytes;
          _totalBytes = total;
          _status = 'Download පටන් ගත්තා…  '
              '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
          _notify();

          final watch = Stopwatch()..start();
          var done = false;
          if (total > 0) {
            try {
              if (_useParallel) {
                await _downloadParallel(streamInfo.url, total, file, watch);
              } else {
                await _downloadDirect(streamInfo.url, total, file, watch);
              }
              done = true;
            } catch (e) {
              _addLog('Direct download failed: $e');
              // Direct mode refused – do it the library's way.
              _downloadedBytes = 0;
              _downloadProgress = 0;
              _speedBps = 0;
              watch.reset();
              if (await file.exists()) await file.delete();
            }
          }
          if (!done) {
            _addLog('Normal download…');
            await _downloadSequential(yt, streamInfo, file, watch);
          }
          _addLog('Downloaded ${(await file.length() / 1024).round()} KB');
          if (await file.length() < 10 * 1024) {
            throw Exception('Download උන file එක හිස්');
          }
          ok = true;
          break;
        } catch (e) {
          final m = '$e'.replaceAll('\n', ' ');
          _addLog('Client ${ci + 1} FAILED: $m');
          errors.add(m.length > 70 ? '${m.substring(0, 70)}…' : m);
          try {
            if (file != null && await file.exists()) await file.delete();
          } catch (_) {}
        }
      }
      if (!ok || file == null) {
        throw Exception(
          errors.isEmpty ? 'unknown error' : errors.asMap().entries.map((e) => '#${e.key + 1}: ${e.value}').join(' | '),
        );
      }

      final video = await infoFuture;
      final track = MusicTrack(
        id: videoId.value,
        title: video?.title ?? 'YouTube ${videoId.value}',
        author: video?.author ?? '',
        path: file.path,
      );
      _tracks.add(track);
      await _savePlaylist();

      _addLog('DONE ✓');
      _pendingLabel = null;
      _status = 'Playlist එකට add උනා ✓  ${track.title}';
      _isDownloading = false;
      _downloadProgress = 1;
      _notify();

      if (playAfter) await playIndex(_tracks.length - 1);
      return null;
    } catch (e) {
      _addLog('ERROR: $e');
      _pendingLabel = null;
      _isDownloading = false;
      _status = null;
      _notify();
      final msg = '$e';
      final short = msg.length > 420 ? '${msg.substring(0, 420)}…' : msg;
      return 'Download කරන්න බැරි උනා. Link එක / internet එක බලන්න.\n($short)';
    } finally {
      yt.close();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _player.dispose();
    super.dispose();
  }
}
