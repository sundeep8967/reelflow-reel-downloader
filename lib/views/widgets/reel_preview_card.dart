import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/reel_item.dart';

class ReelPreviewCard extends StatefulWidget {
  final ReelItem reel;
  final VoidCallback onDownload;
  final bool isDownloading;
  final double downloadProgress;
  final String downloadStatus;

  const ReelPreviewCard({
    super.key,
    required this.reel,
    required this.onDownload,
    required this.isDownloading,
    required this.downloadProgress,
    required this.downloadStatus,
  });

  @override
  State<ReelPreviewCard> createState() => _ReelPreviewCardState();
}

class _ReelPreviewCardState extends State<ReelPreviewCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant ReelPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reel.videoUrl != widget.reel.videoUrl) {
      _controller?.dispose();
      _isInitialized = false;
      _initVideo();
    }
  }

  void _initVideo() {
    if (widget.reel.videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.videoUrl),
      )..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _controller?.setLooping(true);
            _controller?.play();
          }
        }).catchError((err) {
          debugPrint('Video player init error: $err');
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white;
    final borderColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.08)
        : CupertinoColors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video player preview area
          AspectRatio(
            aspectRatio: 9 / 12,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isInitialized && _controller != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller!),
                        if (!_controller!.value.isPlaying)
                          Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Icon(
                              CupertinoIcons.play_fill,
                              color: CupertinoColors.white,
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  )
                else if (widget.reel.thumbnailUrl.isNotEmpty)
                  Image.network(
                    widget.reel.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  )
                else
                  _buildPlaceholder(),

                // Duration badge
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.reel.duration,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details & Download controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF09433),
                            Color(0xFFE6683C),
                            Color(0xFFDC2743),
                            Color(0xFFCC2366),
                            Color(0xFFBC1888),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.reel.author.isNotEmpty
                            ? widget.reel.author[0].toUpperCase()
                            : 'I',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.reel.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Text(
                            'Instagram Reel',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.reel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 16),

                // Download Progress
                if (widget.isDownloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: widget.downloadProgress > 0 ? widget.downloadProgress : null,
                      backgroundColor: CupertinoColors.systemGrey5,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        CupertinoColors.activeGreen,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      widget.downloadStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: BorderRadius.circular(14),
                    color: CupertinoColors.activeGreen,
                    disabledColor: CupertinoColors.activeGreen.withValues(alpha: 0.5),
                    onPressed: widget.isDownloading ? null : widget.onDownload,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isDownloading)
                          const CupertinoActivityIndicator(color: CupertinoColors.white)
                        else
                          const Icon(CupertinoIcons.arrow_down_circle_fill, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.isDownloading ? 'Saving...' : 'Download Reel',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: CupertinoColors.black,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.play_circle, color: CupertinoColors.white, size: 48),
          SizedBox(height: 8),
          Text(
            'Reel Preview',
            style: TextStyle(color: CupertinoColors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
