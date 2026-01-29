import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_background.dart';
import '../services/theme_service.dart';
import '../services/rss_service.dart';
import '../models/feed_item.dart';

class ArticleScreen extends StatelessWidget {
  final String url;
  final String title;
  final String? content;
  final String? imageUrl;
  final FeedItem? item;

  const ArticleScreen({
    Key? key,
    required this.url,
    required this.title,
    this.content,
    this.imageUrl,
    this.item,
  }) : super(key: key);

  Future<void> _launchOriginal() async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context).currentTheme;
    final rssService = Provider.of<RssService>(context);
    final isSaved = rssService.isSaved(url);
    return Scaffold(
      backgroundColor: theme.baseColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: theme.textColor, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textColor),
      ),
      body: GlassBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            120, // Increased top padding for AppBar
            16,
            100,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.surfaceColor, // Ensure readable background
              borderRadius: BorderRadius.circular(16),
              border: theme.glassBorderColor != null
                  ? Border.all(color: theme.glassBorderColor!)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                Html(
                  data: content ?? '<p>No content available.</p>',
                  style: {
                    "body": Style(
                      fontSize: FontSize(16),
                      color: theme.textColor,
                      lineHeight: LineHeight(1.6),
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "a": Style(
                      color: theme.accentColor,
                      textDecoration: TextDecoration.none,
                    ),
                    "img": Style(
                      width: Width(100, Unit.percent),
                      height: Height.auto(),
                    ),
                    "p": Style(
                      lineHeight: LineHeight(1.6),
                      // marginBottom was invalid, handled generally by block spacing
                    ),
                    "h1": Style(fontSize: FontSize(22), color: theme.textColor),
                    "h2": Style(fontSize: FontSize(20), color: theme.textColor),
                    "h3": Style(fontSize: FontSize(18), color: theme.textColor),
                  },
                  onLinkTap: (url, _, __) {
                    if (url != null) {
                      launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'save',
            onPressed: () {
              if (item != null) {
                rssService.toggleSaveArticle(item!);
              }
            },
            backgroundColor: theme.surfaceColor,
            foregroundColor: isSaved
                ? theme.accentColor
                : theme.secondaryTextColor,
            child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'view',
            onPressed: _launchOriginal,
            label: const Text('View Original'),
            icon: const Icon(Icons.open_in_browser),
            backgroundColor: theme.accentColor,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
