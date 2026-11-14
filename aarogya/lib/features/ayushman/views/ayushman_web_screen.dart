import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class AyushmanWebScreen extends StatefulWidget {
  const AyushmanWebScreen({super.key});

  @override
  State<AyushmanWebScreen> createState() => _AyushmanWebScreenState();
}

class _AyushmanWebScreenState extends State<AyushmanWebScreen> {
  InAppWebViewController? _webViewController;
  final CookieManager _cookieManager = CookieManager.instance();

  double _loadingProgress = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDownloading = false;
  String _currentUrl = 'https://beneficiary.nha.gov.in/';

  final InAppWebViewSettings _webSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheEnabled: true,
    useShouldOverrideUrlLoading: false,
    supportMultipleWindows: false,
    allowsInlineMediaPlayback: true,
    useOnDownloadStart: true,
    javaScriptCanOpenWindowsAutomatically: true,
    userAgent:
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    allowFileAccessFromFileURLs: false,
    allowUniversalAccessFromFileURLs: false,
    disableDefaultErrorPage: false,
    supportZoom: true,
    builtInZoomControls: true,
    displayZoomControls: false,
  );

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DOWNLOAD HANDLER
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _handleDownload(
    InAppWebViewController controller,
    DownloadStartRequest request,
  ) async {
    final url = request.url.toString();

    if (_isDownloading) {
      _showSnack('Download already in progress. Please wait.', isError: true);
      return;
    }
    if (!mounted) return;
    setState(() => _isDownloading = true);
    _showDownloadDialog();

    try {
      // 1. Collect WebView session cookies
      final cookies = await _cookieManager.getCookies(url: request.url);
      final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');

      // 2. Build request headers mirroring what the browser sent
      final headers = <String, dynamic>{
        'Cookie': cookieHeader,
        'Referer': _currentUrl,
        'Accept': 'application/pdf,application/octet-stream,*/*;q=0.9',
        'Accept-Language': 'en-IN,en;q=0.9,hi;q=0.8',
        'User-Agent': _webSettings.userAgent ?? 'Mozilla/5.0',
      };

      // 3. Configure Dio
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(seconds: 30),
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (s) => s != null && s < 500,
      ));

      // 4. Determine save path
      final appDocDir = await getApplicationDocumentsDirectory();
      final ayushmanDir = Directory('${appDocDir.path}/ayushman_cards');
      if (!ayushmanDir.existsSync()) {
        ayushmanDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String filename = 'ayushman_card_$timestamp.pdf';

      // 4a. Try to get a better filename from Content-Disposition
      try {
        final headResp = await dio.head(url, options: Options(headers: headers));
        final cd = headResp.headers.value('content-disposition');
        if (cd != null && cd.isNotEmpty) {
          final extracted = _extractFilenameFromContentDisposition(cd);
          if (extracted != null && extracted.isNotEmpty) {
            filename = extracted;
          }
        }
      } catch (_) {
        // HEAD failed — timestamp name is fine
      }

      final savePath = '${ayushmanDir.path}/$filename';

      // 5. Download file
      await dio.download(
        url,
        savePath,
        options: Options(headers: headers),
        onReceiveProgress: (_, _r) {}, // progress tracked via dialog
      );

      // 6. Validate the downloaded file is a real PDF
      final file = File(savePath);
      if (!file.existsSync() || file.lengthSync() < 100) {
        if (file.existsSync()) file.deleteSync();
        throw Exception(
          'Downloaded file is empty or too small. '
          'The session may have expired — please log in again.',
        );
      }

      final raf = file.openSync();
      final headerBytes = raf.readSync(4);
      raf.closeSync();

      if (headerBytes.length < 4 || String.fromCharCodes(headerBytes) != '%PDF') {
        // Might be an HTML error page from NHA
        final content = file.readAsStringSync();
        file.deleteSync();
        if (content.toLowerCase().contains('session') ||
            content.toLowerCase().contains('login') ||
            content.toLowerCase().contains('expired')) {
          throw Exception(
            'Session expired on the NHA website. '
            'Please log in again and retry the download.',
          );
        }
        throw Exception('Server did not return a valid PDF. Please try again.');
      }

      if (!mounted) return;
      _closeDownloadDialog();
      _showSnack('Ayushman Card downloaded successfully!');

      // 7. Open PDF viewer
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            filePath: savePath,
            title: 'Ayushman Card',
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      _closeDownloadDialog();
      final String msg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        msg = 'Download timed out. Check your internet connection.';
      } else if (e.type == DioExceptionType.badResponse) {
        final code = e.response?.statusCode;
        msg = 'Server error $code. ${code == 403 ? "Session may have expired — please log in again." : ""}';
      } else if (e.type == DioExceptionType.cancel) {
        msg = 'Download cancelled.';
      } else {
        msg = 'Network error: ${e.message}';
      }
      _showSnack(msg, isError: true);
    } catch (e) {
      if (!mounted) return;
      _closeDownloadDialog();
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  /// Safely extract filename from a Content-Disposition header value.
  String? _extractFilenameFromContentDisposition(String cd) {
    // Pattern: filename="value" or filename=value
    final pattern = RegExp(r'''filename\s*=\s*["']?([^"';\r\n]+)["']?''');
    final match = pattern.firstMatch(cd);
    if (match == null) return null;
    var name = (match.group(1) ?? '').trim();
    if (name.isEmpty) return null;
    if (!name.toLowerCase().endsWith('.pdf')) name = '$name.pdf';
    // Remove characters not safe in filenames
    name = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
    return name;
  }

  void _showDownloadDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.mintBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: AppColors.primaryTeal,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Downloading Ayushman Card…',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait. Do not close this screen.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                backgroundColor: AppColors.mintBg,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _closeDownloadDialog() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor:
            isError ? AppColors.sosRed : AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ayushman Bharat Portal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              _currentUrl.length > 46
                  ? '${_currentUrl.substring(0, 46)}…'
                  : _currentUrl,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryTeal),
            tooltip: 'Reload',
            onPressed: () => _webViewController?.reload(),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'How to download',
            onPressed: _showHelpDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              backgroundColor: AppColors.mintBg,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
              minHeight: 3,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── WebView ────────────────────────────────────────────────
          if (!_hasError)
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://beneficiary.nha.gov.in/'),
                headers: {'Accept-Language': 'en-IN,en;q=0.9,hi;q=0.8'},
              ),
              initialSettings: _webSettings,
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                if (!mounted) return;
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _currentUrl = url?.toString() ?? _currentUrl;
                });
              },
              onProgressChanged: (controller, progress) {
                if (!mounted) return;
                setState(() => _loadingProgress = progress / 100);
              },
              onLoadStop: (controller, url) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                  _currentUrl = url?.toString() ?? _currentUrl;
                });
              },
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame == true) {
                  if (!mounted) return;
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage =
                        'Could not load the NHA website.\n\n'
                        '${error.description}\n\n'
                        'Please check your internet connection and try again.';
                  });
                }
              },
              onDownloadStartRequest: (controller, downloadStartRequest) {
                _handleDownload(controller, downloadStartRequest);
              },
            ),

          // ── Error overlay ──────────────────────────────────────────
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.sosLightBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: AppColors.sosRed,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Website Unavailable',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _webViewController?.reload();
                      },
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: const Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Download in-progress pill ──────────────────────────────
          if (_isDownloading)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Downloading Ayushman Card…',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // ── Bottom navigation bar ──────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _NavBtn(
                icon: Icons.arrow_back_ios_rounded,
                onPressed: () async {
                  if (await _webViewController?.canGoBack() == true) {
                    _webViewController?.goBack();
                  }
                },
              ),
              _NavBtn(
                icon: Icons.arrow_forward_ios_rounded,
                onPressed: () async {
                  if (await _webViewController?.canGoForward() == true) {
                    _webViewController?.goForward();
                  }
                },
              ),
              const Spacer(),
              _NavBtn(
                icon: Icons.home_rounded,
                label: 'NHA Home',
                onPressed: () => _webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri('https://beneficiary.nha.gov.in/'),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _NavBtn(
                icon: Icons.help_outline_rounded,
                label: 'Help',
                onPressed: _showHelpDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_rounded, color: AppColors.primaryTeal, size: 22),
            SizedBox(width: 8),
            Text(
              'How to Download',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpStep(
              step: '1',
              text: 'Enter your Aadhaar-linked mobile number on the NHA website.',
            ),
            _HelpStep(step: '2', text: 'Enter OTP to verify & log in.'),
            _HelpStep(
              step: '3',
              text: 'Select your name from the beneficiary list.',
            ),
            _HelpStep(
              step: '4',
              text: 'Tap "Download Card" or "Print/Download" button.',
            ),
            _HelpStep(
              step: '5',
              text:
                  'The PDF is automatically saved and opened inside the app.',
            ),
            SizedBox(height: 10),
            Text(
              'Note: The NHA website requires OTP-based login for every session. '
              'Your credentials are never stored by this app.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;

  const _NavBtn({
    required this.icon,
    this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textPrimary),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: AppColors.primaryTeal),
      label: Text(
        label!,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primaryTeal,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String step;
  final String text;

  const _HelpStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
