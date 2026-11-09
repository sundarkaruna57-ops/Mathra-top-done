import 'package:flutter/material.dart';
import 'package:pipes/data/services/link_sniffer.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Keeps the hidden WebView of [LinkSniffer] alive while it is working.
/// Put directly inside a Stack, underneath the pages. Practically invisible.
class SniffHost extends StatelessWidget {
  const SniffHost({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WebViewController?>(
      valueListenable: LinkSniffer.host,
      builder: (context, controller, _) {
        if (controller == null) {
          return const Positioned(left: 0, top: 0, width: 0, height: 0, child: SizedBox.shrink());
        }
        return Positioned(
          left: 0,
          top: 0,
          width: 360,
          height: 640,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.01,
              child: WebViewWidget(controller: controller),
            ),
          ),
        );
      },
    );
  }
}
