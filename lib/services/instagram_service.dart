import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/reel_item.dart';

class InstagramService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 334.0.0.22.100',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    ),
  );

  // Matches Instagram Reels/Posts as well as any short/long media links
  static final RegExp reelPattern = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?(?:instagram\.com\/(?:reel|p|tv)\/([a-zA-Z0-9_-]+)|(?:youtu\.be\/|youtube\.com\/(?:shorts\/|watch\?v=|embed\/|v\/))([a-zA-Z0-9_-]{11}))',
    caseSensitive: false,
  );

  /// Extract media ID/shortcode from input text or URL
  String? extractShortcode(String input) {
    final match = reelPattern.firstMatch(input.trim());
    if (match != null) {
      return match.group(1) ?? match.group(2);
    }
    // Also try any clean URL
    final uri = Uri.tryParse(input.trim());
    if (uri != null && uri.hasScheme) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video';
    }
    return null;
  }

  /// Fetch Reel details using Instagram API & embedded HTML fallback
  Future<ReelItem> fetchReelDetails(String url) async {
    final cleanInput = url.trim();
    final isSecondaryStream = cleanInput.contains('youtu.be') || cleanInput.contains('youtube.com');

    // Strategy 1: Fast Reliable Public Gateway (works seamlessly for both Instagram and alternate media streams)
    try {
      final item = await _fetchViaPublicGateway(cleanInput);
      if (item != null) return item;
    } catch (e) {
      log('Public gateway failed: $e');
    }

    if (!isSecondaryStream) {
      final shortcode = extractShortcode(cleanInput);
      if (shortcode != null) {
        final canonicalUrl = 'https://www.instagram.com/reel/$shortcode/';

        // Strategy 2: Instagram public embed API
        try {
          final item = await _fetchViaEmbedInfo(shortcode, canonicalUrl);
          if (item != null) return item;
        } catch (e) {
          log('Embed info strategy failed: $e');
        }

        // Strategy 3: Fast Public Instagram Page Scrape with JSON extraction
        try {
          final item = await _fetchViaHtmlScrape(shortcode, canonicalUrl);
          if (item != null) return item;
        } catch (e) {
          log('HTML Scrape strategy failed: $e');
        }
      }
    }

    throw Exception('Could not extract media. The video might be private, restricted, or temporarily unavailable.');
  }

  Future<ReelItem?> _fetchViaEmbedInfo(String shortcode, String canonicalUrl) async {
    final embedUrl = 'https://www.instagram.com/p/$shortcode/embed/captioned/';
    final response = await _dio.get<String>(
      embedUrl,
      options: Options(responseType: ResponseType.plain),
    );

    if (response.statusCode != 200 || response.data == null) return null;
    final html = response.data!;

    // Find video url
    final videoMatch = RegExp(r'video_url&quot;:&quot;([^&]+)&quot;').firstMatch(html) ??
        RegExp(r'"video_url"\s*:\s*"([^"]+)"').firstMatch(html) ??
        RegExp(r'<video[^>]+src="([^">]+)"').firstMatch(html);

    if (videoMatch == null) return null;

    String videoUrl = videoMatch.group(1)!;
    videoUrl = videoUrl.replaceAll(r'\/', '/').replaceAll('&amp;', '&');

    // Thumbnail
    final thumbMatch = RegExp(r'display_url&quot;:&quot;([^&]+)&quot;').firstMatch(html) ??
        RegExp(r'"display_url"\s*:\s*"([^"]+)"').firstMatch(html);
    String thumbUrl = '';
    if (thumbMatch != null) {
      thumbUrl = thumbMatch.group(1)!.replaceAll(r'\/', '/').replaceAll('&amp;', '&');
    }

    // Username
    final userMatch = RegExp(r'"username"\s*:\s*"([^"]+)"').firstMatch(html) ??
        RegExp(r'username&quot;:&quot;([^&]+)&quot;').firstMatch(html);
    final username = userMatch != null ? userMatch.group(1)! : 'Creator';

    return ReelItem(
      id: shortcode,
      title: 'Video by @$username',
      author: username,
      authorUrl: 'https://www.instagram.com/$username',
      thumbnailUrl: thumbUrl,
      videoUrl: videoUrl,
      duration: '0:30',
      originalUrl: canonicalUrl,
    );
  }

  Future<ReelItem?> _fetchViaHtmlScrape(String shortcode, String canonicalUrl) async {
    final response = await _dio.get<String>(
      canonicalUrl,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'User-Agent': 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
        },
      ),
    );

    if (response.statusCode != 200 || response.data == null) return null;
    final html = response.data!;

    final videoOg = RegExp(r'<meta\s+property="og:video"\s+content="([^"]+)"').firstMatch(html) ??
        RegExp(r'<meta\s+property="og:video:secure_url"\s+content="([^"]+)"').firstMatch(html);

    if (videoOg == null) return null;
    final videoUrl = videoOg.group(1)!.replaceAll('&amp;', '&');

    final imageOg = RegExp(r'<meta\s+property="og:image"\s+content="([^"]+)"').firstMatch(html);
    final thumbUrl = imageOg != null ? imageOg.group(1)!.replaceAll('&amp;', '&') : '';

    final titleOg = RegExp(r'<meta\s+property="og:title"\s+content="([^"]+)"').firstMatch(html);
    final fullTitle = titleOg != null ? titleOg.group(1)! : 'Media Video';

    String author = 'Creator';
    if (fullTitle.contains('•')) {
      author = fullTitle.split('•').first.replaceAll(RegExp(r'Instagram\s*:\s*'), '').trim();
    }

    return ReelItem(
      id: shortcode,
      title: fullTitle,
      author: author,
      authorUrl: 'https://www.instagram.com/$author',
      thumbnailUrl: thumbUrl,
      videoUrl: videoUrl,
      duration: '0:30',
      originalUrl: canonicalUrl,
    );
  }

  Future<ReelItem?> _fetchViaPublicGateway(String targetUrl) async {
    const gatewayUrl = 'https://api.cobalt.tools/api/json';
    try {
      final resp = await _dio.post(
        gatewayUrl,
        data: {
          'url': targetUrl,
          'videoQuality': '1080',
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        if (data['url'] != null) {
          final id = extractShortcode(targetUrl) ?? 'video_${DateTime.now().millisecondsSinceEpoch}';
          return ReelItem(
            id: id,
            title: data['filename'] ?? 'High Definition Video',
            author: 'Creator',
            authorUrl: targetUrl,
            thumbnailUrl: '',
            videoUrl: data['url'],
            duration: 'HD',
            originalUrl: targetUrl,
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
