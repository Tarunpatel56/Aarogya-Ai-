import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/phone_launcher_util.dart';

class GovernmentPortalWebViewScreen extends StatefulWidget {
  final String title;
  final String titleHi;
  final String portalUrl;
  final String? helplineNumber;
  final String? helplineName;

  const GovernmentPortalWebViewScreen({
    super.key,
    required this.title,
    required this.titleHi,
    required this.portalUrl,
    this.helplineNumber,
    this.helplineName,
  });

  @override
  State<GovernmentPortalWebViewScreen> createState() =>
      _GovernmentPortalWebViewScreenState();
}

class _GovernmentPortalWebViewScreenState
    extends State<GovernmentPortalWebViewScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0.0;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final isHindi = Get.locale?.languageCode == 'hi';
    final effectiveTitle = isHindi ? widget.titleHi : widget.title;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              effectiveTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              isHindi ? 'आधिकारिक सरकारी पोर्टल' : 'Official Government Portal',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (widget.helplineNumber != null)
            IconButton(
              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
              tooltip: '${widget.helplineName ?? "Helpline"}: ${widget.helplineNumber}',
              onPressed: () => PhoneLauncherUtil.launchPhone(widget.helplineNumber),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _webViewController?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: isHindi ? 'ब्राउज़र में खोलें' : 'Open in Browser',
            onPressed: () => PhoneLauncherUtil.launchWeb(widget.portalUrl),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintAccent),
                ),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.portalUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          supportZoom: true,
          builtInZoomControls: true,
          displayZoomControls: false,
          userAgent:
              'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        ),
        onWebViewCreated: (controller) => _webViewController = controller,
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100.0;
            _isLoading = progress < 100;
          });
        },
        onLoadStop: (controller, url) {
          setState(() => _isLoading = false);
        },
      ),
    );
  }
}
