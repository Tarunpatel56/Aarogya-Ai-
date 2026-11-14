import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';

import '../../../theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    this.title = 'PDF Viewer',
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PDFViewController? _pdfController;

  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _verifyFile();
  }

  void _verifyFile() {
    final file = File(widget.filePath);
    if (!file.existsSync()) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'File not found at:\n${widget.filePath}';
          _isLoading = false;
        });
      }
      return;
    }
    if (file.lengthSync() < 100) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'The downloaded file appears to be invalid or empty. Please download again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWithExternalApp() async {
    try {
      final result = await OpenFilex.open(widget.filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open externally: ${result.message}'),
            backgroundColor: AppColors.sosRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.sosRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (_totalPages > 0)
              Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          // Open in external PDF viewer / share
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primaryTeal),
            tooltip: 'Open with external app',
            onPressed: _hasError ? null : _openWithExternalApp,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── PDF Viewer ──────────────────────────────────────────────────
          if (!_hasError)
            PDFView(
              filePath: widget.filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              fitEachPage: true,
              defaultPage: 0,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                if (mounted) {
                  setState(() {
                    _totalPages = pages ?? 0;
                    _isLoading = false;
                  });
                }
              },
              onError: (error) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = 'Could not render PDF: $error';
                    _isLoading = false;
                  });
                }
              },
              onPageError: (page, error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error on page $page: $error'),
                      backgroundColor: AppColors.warningOrange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              onViewCreated: (controller) {
                if (mounted) _pdfController = controller;
              },
              onPageChanged: (page, total) {
                if (mounted) {
                  setState(() {
                    _currentPage = (page ?? 0) + 1;
                    _totalPages = total ?? _totalPages;
                  });
                }
              },
            ),

          // ── Loading spinner ─────────────────────────────────────────────
          if (_isLoading && !_hasError)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Ayushman Card…',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          // ── Error view ──────────────────────────────────────────────────
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
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.sosRed, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Could Not Load PDF',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryTeal),
                          label: const Text('Go Back', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryTeal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _isLoading = true;
                            });
                            _verifyFile();
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                          label: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // ── Page navigation bottom bar ─────────────────────────────────────
      bottomNavigationBar: _totalPages > 1
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous page
                    IconButton(
                      onPressed: _currentPage > 1
                          ? () {
                              _pdfController?.setPage(_currentPage - 2);
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                      color: _currentPage > 1 ? AppColors.primaryTeal : AppColors.textMuted,
                    ),
                    // Page indicator pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.mintBorder),
                      ),
                      child: Text(
                        'Page $_currentPage / $_totalPages',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    // Next page
                    IconButton(
                      onPressed: _currentPage < _totalPages
                          ? () {
                              _pdfController?.setPage(_currentPage);
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      color: _currentPage < _totalPages ? AppColors.primaryTeal : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

