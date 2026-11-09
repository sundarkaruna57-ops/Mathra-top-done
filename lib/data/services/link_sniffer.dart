import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SniffResult {
  const SniffResult(this.urls, this.cookies);

  /// Audio-looking URLs the page used, best guesses first.
  final List<Uri> urls;

  /// `document.cookie` of the page (for the follow-up download requests).
  final String cookies;
}

/// Opens a page in a hidden WebView, runs its JavaScript, presses the
/// "Download" / "Play" buttons and reports every audio URL the page touches.
/// This is for sites where the mp3 link only appears after JavaScript runs.
class LinkSniffer {
  /// The app shows this controller's WebView (hidden under the pages) while a
  /// sniff is running – see `SniffHost`.
  static final ValueNotifier<WebViewController?> host =
      ValueNotifier<WebViewController?>(null);

  static const String _ua =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static final RegExp _audioExt = RegExp(
    r'\.(?:mp3|m4a|aac|ogg|opus|wav|flac)(?:[?#]|$)',
    caseSensitive: false,
  );
  static final RegExp _hint = RegExp(r'stream|download|mp3|audio|/file', caseSensitive: false);

  static const String _js = r"""
(function(){
  if (window.__snInit) { try { window.__snScan(); window.__snClick(); } catch(e){} return; }
  window.__snInit = true;
  function send(k, v){ try { Sniff.postMessage(JSON.stringify({k:k, v:String(v).slice(0,8000)})); } catch(e){} }
  function abs(u){ try { return new URL(u, location.href).href; } catch(e){ return String(u); } }
  try {
    var d = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
    Object.defineProperty(HTMLMediaElement.prototype, 'src', {
      configurable: true,
      get: function(){ return d.get.call(this); },
      set: function(v){ send('media', abs(v)); d.set.call(this, v); }
    });
  } catch(e){}
  try {
    var sa = Element.prototype.setAttribute;
    Element.prototype.setAttribute = function(n, v){
      if ((n === 'src' || n === 'href') && /^(AUDIO|VIDEO|SOURCE)$/.test(this.tagName)) send('media', abs(v));
      return sa.apply(this, arguments);
    };
  } catch(e){}
  try {
    var pl = HTMLMediaElement.prototype.play;
    HTMLMediaElement.prototype.play = function(){
      if (this.currentSrc) send('media', this.currentSrc);
      return pl.apply(this, arguments);
    };
  } catch(e){}
  try {
    var of = window.fetch;
    window.fetch = function(){
      var u = arguments[0]; u = (u && u.url) ? u.url : u; send('req', abs(u));
      return of.apply(this, arguments).then(function(r){
        try {
          var ct = r.headers.get('content-type') || '';
          send('req', abs(r.url));
          if (/json|text/.test(ct)) r.clone().text().then(function(t){ send('body', t); });
        } catch(e){}
        return r;
      });
    };
  } catch(e){}
  try {
    var xo = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(m, u){
      send('req', abs(u));
      this.addEventListener('load', function(){
        try {
          var ct = this.getResponseHeader('content-type') || '';
          if (/json|text/.test(ct)) send('body', this.responseText);
        } catch(e){}
      });
      return xo.apply(this, arguments);
    };
  } catch(e){}
  try { window.open = function(u){ if (u) send('open', abs(u)); return null; }; } catch(e){}
  window.__snScan = function(){
    document.querySelectorAll('audio,video,source').forEach(function(e){
      var s = e.currentSrc || e.src || e.getAttribute('src'); if (s) send('media', abs(s));
    });
    document.querySelectorAll('a[href]').forEach(function(a){
      var h = a.getAttribute('href') || '';
      if (/\.(mp3|m4a|aac|ogg|opus|wav|flac)(\?|$)/i.test(h) || /download|stream|mp3/i.test(h)) send('link', abs(h));
    });
  };
  window.__snClick = function(){
    var els = Array.prototype.slice.call(document.querySelectorAll('a,button,[role=button],.btn,[onclick],input[type=button]'));
    function txt(e){ return ((e.innerText || e.value || '') + ' ' + (e.getAttribute('aria-label') || '') + ' ' + (e.id || '') + ' ' + (typeof e.className === 'string' ? e.className : '')).toLowerCase(); }
    var dl = els.filter(function(e){ return /download/.test(txt(e)); });
    var pl = els.filter(function(e){ return /(^|\W)play(\W|$)/.test(txt(e)); });
    var list = dl.slice(0, 3).concat(pl.slice(0, 2));
    list.forEach(function(e, i){ setTimeout(function(){ try { e.click(); } catch(x){} }, 400 * i); });
  };
  window.__snScan();
  window.__snClick();
})();
""";

  static Future<SniffResult> sniff(
    Uri page, {
    Duration timeout = const Duration(seconds: 25),
    void Function(String)? log,
  }) async {
    final media = <String>[]; // definite audio (media elements, audio files)
    final extra = <String>[]; // "download"/"stream" style guesses

    void addUrl(String raw, {bool definite = false}) {
      final u = raw.trim().replaceAll(r'\/', '/').replaceAll('&amp;', '&');
      if (u.isEmpty || u.startsWith('blob:') || u.startsWith('data:') || u.startsWith('javascript:')) {
        return;
      }
      Uri uri;
      try {
        uri = page.resolve(u);
      } catch (_) {
        return;
      }
      if (!(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) return;
      final s = uri.toString();
      if (definite || _audioExt.hasMatch(s)) {
        if (!media.contains(s)) media.add(s);
      } else if (_hint.hasMatch(s) && !extra.contains(s)) {
        extra.add(s);
      }
    }

    void scanBody(String body) {
      final t = body.replaceAll(r'\/', '/');
      for (final m in RegExp(
        r'''"(?:url|download_url|downloadUrl|download|stream_url|streamUrl|stream|file|link|src|path|audio|mp3)"\s*:\s*"([^"]+)"''',
        caseSensitive: false,
      ).allMatches(t)) {
        addUrl(m.group(1)!);
      }
      for (final m in RegExp(
        r'https?://[^"\s<>\\]+?\.(?:mp3|m4a|aac|ogg|opus|wav|flac)(?:\?[^"\s<>\\]*)?',
        caseSensitive: false,
      ).allMatches(t)) {
        addUrl(m.group(0)!);
      }
    }

    late final WebViewController ctrl;
    ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_ua)
      ..addJavaScriptChannel(
        'Sniff',
        onMessageReceived: (m) {
          try {
            final j = jsonDecode(m.message) as Map<String, dynamic>;
            final k = j['k'] as String;
            final v = j['v'] as String;
            if (k == 'media') {
              addUrl(v, definite: true);
            } else if (k == 'body') {
              scanBody(v);
            } else {
              addUrl(v);
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) {
            addUrl(r.url);
            // Don't let the hidden browser open / download the audio itself.
            if (_audioExt.hasMatch(r.url)) return NavigationDecision.prevent;
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) async {
            try {
              await ctrl.runJavaScript(_js);
            } catch (_) {}
          },
          onWebResourceError: (_) {},
        ),
      );

    host.value = ctrl; // makes the app mount the (hidden) WebView
    var cookies = '';
    try {
      log?.call('WebView: page එක open කරනවා…');
      await ctrl.loadRequest(page);
      final sw = Stopwatch()..start();
      var foundAt = -1;
      var tick = 0;
      while (sw.elapsed < timeout) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        tick++;
        if (media.isNotEmpty && foundAt < 0) foundAt = sw.elapsedMilliseconds;
        if (foundAt >= 0 && sw.elapsedMilliseconds - foundAt > 1500) break;
        // Nothing yet after 6 s: scan and press the buttons once more.
        if (tick == 12 && media.isEmpty) {
          try {
            await ctrl.runJavaScript('window.__snScan&&window.__snScan();window.__snClick&&window.__snClick();');
          } catch (_) {}
        }
      }
      log?.call('WebView: ${sw.elapsedMilliseconds} ms, audio=${media.length}, guesses=${extra.length}');
      try {
        var r = (await ctrl.runJavaScriptReturningResult('document.cookie')).toString();
        if (r.length >= 2 && r.startsWith('"') && r.endsWith('"')) {
          r = jsonDecode(r) as String;
        }
        cookies = r;
      } catch (_) {}
    } finally {
      host.value = null;
      try {
        await ctrl.loadRequest(Uri.parse('about:blank'));
      } catch (_) {}
    }

    final out = <Uri>[];
    for (final s in [...media, ...extra]) {
      out.add(Uri.parse(s));
      if (out.length >= 8) break;
    }
    return SniffResult(out, cookies);
  }
}
