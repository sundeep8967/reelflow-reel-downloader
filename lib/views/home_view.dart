import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/reel_item.dart';
import '../services/instagram_service.dart';
import '../services/download_service.dart';
import 'widgets/dynamic_island_toast.dart';
import 'widgets/reel_preview_card.dart';
import 'widgets/history_sheet.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final TextEditingController _urlController = TextEditingController();
  final InstagramService _instagramService = InstagramService();
  final DownloadService _downloadService = DownloadService();

  bool _isFetching = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  ReelItem? _currentReel;
  List<ReelItem> _history = [];
  String _saveDirectory = 'Loading...';

  static const MethodChannel _shareChannel =
      MethodChannel('com.reelapp.instagram_reel_downloader/share');

  // Toast / Island Notification
  String _toastMessage = '';
  IconData _toastIcon = CupertinoIcons.checkmark_alt_circle_fill;
  Color _toastColor = CupertinoColors.activeGreen;
  bool _showToast = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupShareChannel();
    _loadHistory();
    _loadSaveDirectory();
    _checkClipboardForReel();
  }

  Future<void> _loadSaveDirectory() async {
    final dir = await _downloadService.getSaveDirectoryPath();
    if (mounted) {
      setState(() {
        _saveDirectory = dir;
      });
    }
  }

  void _setupShareChannel() {
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final sharedText = call.arguments as String?;
        if (sharedText != null && sharedText.isNotEmpty) {
          _handleIncomingSharedText(sharedText);
        }
      }
    });

    _checkInitialSharedText();
  }

  Future<void> _checkInitialSharedText() async {
    try {
      final initialText =
          await _shareChannel.invokeMethod<String>('getInitialSharedText');
      if (initialText != null && initialText.isNotEmpty) {
        _handleIncomingSharedText(initialText);
      }
    } catch (_) {}
  }

  void _handleIncomingSharedText(String rawText) {
    // Extract url from shared text (Instagram share usually includes "Watch this reel by... https://www.instagram.com/reel/xyz...")
    final match = InstagramService.reelPattern.firstMatch(rawText);
    String targetUrl = rawText.trim();
    if (match != null) {
      targetUrl = match.group(0)!;
    }

    setState(() {
      _urlController.text = targetUrl;
    });

    _triggerToast('Received shared Reel!',
        icon: CupertinoIcons.arrow_down_circle_fill,
        color: CupertinoColors.activeBlue);

    _fetchReel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForReel();
    }
  }

  Future<void> _loadHistory() async {
    final history = await _downloadService.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  void _triggerToast(String msg, {IconData? icon, Color? color}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = msg;
      _toastIcon = icon ?? CupertinoIcons.checkmark_alt_circle_fill;
      _toastColor = color ?? CupertinoColors.activeGreen;
      _showToast = true;
    });

    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }

  Future<void> _checkClipboardForReel() async {
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipData?.text ?? '';
      if (text.contains('instagram.com/reel/') || text.contains('instagram.com/p/')) {
        if (_urlController.text.trim() != text.trim()) {
          _triggerToast('Reel URL detected in clipboard!',
              icon: CupertinoIcons.doc_on_clipboard,
              color: CupertinoColors.activeBlue);
        }
      }
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipData?.text ?? '';
    if (text.isNotEmpty) {
      setState(() {
        _urlController.text = text.trim();
      });
      _triggerToast('Pasted from clipboard', icon: CupertinoIcons.checkmark_circle_fill);
      _fetchReel();
    }
  }

  Future<void> _fetchReel() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _triggerToast('Please enter an Instagram link',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          color: CupertinoColors.systemOrange);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isFetching = true;
      _currentReel = null;
    });
    _triggerToast('Fetching Reel...',
        icon: CupertinoIcons.sparkles,
        color: CupertinoColors.activeBlue);

    try {
      final reel = await _instagramService.fetchReelDetails(url);
      if (mounted) {
        setState(() {
          _currentReel = reel;
          _isFetching = false;
        });
        _triggerToast('Reel loaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
        _triggerToast(
          e.toString().replaceAll('Exception: ', ''),
          icon: CupertinoIcons.clear_circled_solid,
          color: CupertinoColors.destructiveRed,
        );
      }
    }
  }

  Future<void> _downloadReel() async {
    if (_currentReel == null || _isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Starting...';
    });

    try {
      await _downloadService.downloadReel(
        reel: _currentReel!,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _downloadStatus = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        _triggerToast('Saved to Downloads!',
            icon: CupertinoIcons.arrow_down_circle_fill,
            color: CupertinoColors.activeGreen);

        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        _triggerToast(
          'Download failed: ${e.toString()}',
          icon: CupertinoIcons.exclamationmark_circle_fill,
          color: CupertinoColors.destructiveRed,
        );
      }
    }
  }

  Future<void> _pickSaveDirectory() async {
    try {
      final selectedDirectory = await FilePickerPlatform.instance.getDirectoryPath(
        dialogTitle: 'Select Download Folder for Reels',
        initialDirectory: _saveDirectory,
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        await _downloadService.setSaveDirectoryPath(selectedDirectory);
        await _loadSaveDirectory();
        _triggerToast('Folder updated!',
            icon: CupertinoIcons.folder_badge_plus);
      }
    } catch (e) {
      _triggerToast('Could not open folder picker: $e',
          icon: CupertinoIcons.exclamationmark_circle_fill,
          color: CupertinoColors.destructiveRed);
    }
  }

  void _showEditLocationOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Download Folder'),
        message: Text('Current: $_saveDirectory'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickSaveDirectory();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder_badge_plus, size: 20),
                SizedBox(width: 8),
                Text('Choose Folder...'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _downloadService.resetSaveDirectory();
              await _loadSaveDirectory();
              _triggerToast('Reset to default Download folder',
                  icon: CupertinoIcons.arrow_counterclockwise);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_counterclockwise, size: 18),
                SizedBox(width: 8),
                Text('Reset to Default'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showHistoryModal() {
    final navigator = Navigator.of(context);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => HistorySheet(
        history: _history,
        onClear: () async {
          await _downloadService.clearHistory();
          _loadHistory();
          navigator.pop();
          _triggerToast('History cleared', icon: CupertinoIcons.trash_fill);
        },
        onSelect: (item) {
          setState(() {
            _currentReel = item;
            _urlController.text = item.originalUrl;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? CupertinoColors.black
        : const Color(0xFFF2F2F7);

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDark ? CupertinoColors.black : CupertinoColors.white)
            .withValues(alpha: 0.85),
        middle: const Text(
          'ReelFlow',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showHistoryModal,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(CupertinoIcons.square_stack_3d_up, size: 24),
              if (_history.isNotEmpty)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: CupertinoColors.activeBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_history.length}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // Header badge row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF09433),
                            Color(0xFFE6683C),
                            Color(0xFFDC2743),
                            Color(0xFFCC2366),
                            Color(0xFFBC1888),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.camera_fill,
                              color: CupertinoColors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'INSTAGRAM REELS',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Big iOS Title
                const Text(
                  'Fast Video\nDownloader',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Paste any Instagram Reel URL to preview and download in full HD.',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 24),

                // iOS Grouped Input Section
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.08)
                          : CupertinoColors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.link,
                        color: CupertinoColors.secondaryLabel,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _urlController,
                          placeholder: 'https://www.instagram.com/reel/...',
                          placeholderStyle: TextStyle(
                            color: isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.tertiaryLabel,
                            fontSize: 14,
                          ),
                          decoration: null,
                          style: const TextStyle(fontSize: 15),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _fetchReel(),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        onPressed: _pasteFromClipboard,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.doc_on_clipboard,
                              size: 14,
                              color: CupertinoColors.activeBlue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Paste',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Primary Fetch Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: BorderRadius.circular(16),
                    color: CupertinoColors.activeBlue,
                    disabledColor: CupertinoColors.activeBlue.withValues(alpha: 0.5),
                    onPressed: _isFetching ? null : _fetchReel,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isFetching)
                          const CupertinoActivityIndicator(color: CupertinoColors.white)
                        else
                          const Icon(CupertinoIcons.arrow_down_to_line,
                              size: 20, color: CupertinoColors.white),
                        const SizedBox(width: 8),
                        Text(
                          _isFetching ? 'Fetching Reel...' : 'Get Reel',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Preview Card if loaded
                if (_currentReel != null) ...[
                  ReelPreviewCard(
                    reel: _currentReel!,
                    onDownload: _downloadReel,
                    isDownloading: _isDownloading,
                    downloadProgress: _downloadProgress,
                    downloadStatus: _downloadStatus,
                  ),
                  const SizedBox(height: 24),
                ],

                // Save Location Card (iOS Grouped Style)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.08)
                          : CupertinoColors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.folder_fill,
                          color: CupertinoColors.activeBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Save Location',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.label,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _saveDirectory,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: _showEditLocationOptions,
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tips / Quick guide
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E).withValues(alpha: 0.6)
                        : CupertinoColors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.05)
                          : CupertinoColors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(CupertinoIcons.lightbulb_fill,
                              color: CupertinoColors.systemYellow, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'How to Download Reels',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildTipStep('1', 'Open Instagram and navigate to the Reel you want.'),
                      _buildTipStep('2', 'Tap the Share icon (paper airplane) and choose "Copy link".'),
                      _buildTipStep('3', 'Return here, tap "Paste", then press "Get Reel" and download.'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Dynamic Island Floating Toast
          DynamicIslandToast(
            message: _toastMessage,
            icon: _toastIcon,
            iconColor: _toastColor,
            isVisible: _showToast,
          ),
        ],
      ),
    );
  }

  Widget _buildTipStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: CupertinoColors.secondaryLabel,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
