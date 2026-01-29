import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rss_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_background.dart';
import '../widgets/neumorphic_card.dart';
import 'article_screen.dart';
import 'package:intl/intl.dart';

class SavedArticlesScreen extends StatelessWidget {
  const SavedArticlesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context).currentTheme;
    final rssService = Provider.of<RssService>(context);
    final savedArticles = rssService.savedArticles;

    return Scaffold(
      backgroundColor: theme.baseColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Saved Articles', style: TextStyle(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textColor),
      ),
      body: GlassBackground(
        child: savedArticles.isEmpty
            ? Center(
                child: Text(
                  'No saved articles yet',
                  style: TextStyle(color: theme.secondaryTextColor),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                itemCount: savedArticles.length,
                itemBuilder: (context, index) {
                  final item = savedArticles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: NeumorphicCard(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleScreen(
                                url: item.link ?? '',
                                title: item.title ?? 'No Title',
                                content: item.content,
                                imageUrl: item.imageUrl,
                                item:
                                    item, // Pass full item for context if needed
                              ),
                            ),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.imageUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title ?? 'No Title',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  if (item.pubDate != null)
                                    Text(
                                      DateFormat.yMMMd().format(item.pubDate!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.bookmark_remove,
                                color: theme.accentColor,
                              ),
                              onPressed: () {
                                rssService.toggleSaveArticle(item);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
