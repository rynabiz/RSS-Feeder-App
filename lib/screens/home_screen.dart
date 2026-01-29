import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/feed_item.dart';
import '../services/rss_service.dart';
import '../services/ad_service.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/glass_background.dart';
import 'article_screen.dart';
import 'feed_management_screen.dart';
import 'saved_articles_screen.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use RssService from Provider, not local instance
  // final RssService _rssService = RssService();
  List<FeedItem> _feedItems = [];
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  int _articleClickCount = 0;

  @override
  void initState() {
    super.initState();
    // Load feeds once when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeeds();
    });
    _loadBannerAd();
  }

  Future<void> _loadFeeds() async {
    setState(() => _isLoading = true);
    try {
      // Access provider to get URLs and fetch
      final rssService = Provider.of<RssService>(context, listen: false);
      // We assume fetchFeeds is now an instance method on RssService that uses its internal URLs
      // But in my previous edit to RssService, I made fetchFeeds use _feedUrls.
      // So calling rssService.fetchFeeds() returns List<FeedItem>.
      final items = await rssService.fetchFeeds();

      if (mounted) {
        setState(() {
          _feedItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd();
    if (_bannerAd != null) {
      _bannerAd!.load().then((_) {
        if (mounted) {
          setState(() {
            _isBannerAdReady = true;
          });
        }
      });
    }
  }

  void _onArticleTap(FeedItem item) {
    _articleClickCount++;
    if (_articleClickCount % 5 == 0) {
      // Show interstitial every 5 clicks
      AdService.showInterstitialAd();
    }

    if (item.link != null) {
      // Mark as read
      Provider.of<RssService>(context, listen: false).markAsRead(item.link!);

      // Reader Mode (Works on Web & Mobile)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleScreen(
            url: item.link!,
            title: item.title ?? 'Article',
            content: item.content,
            imageUrl: item.imageUrl,
            item: item,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to RssService for read status updates
    final rssService = Provider.of<RssService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final theme = themeService.currentTheme;

    // Create a sorted copy of the items
    final sortedItems = List<FeedItem>.from(_feedItems);
    sortedItems.sort((a, b) {
      bool isReadA = rssService.isRead(a.link);
      bool isReadB = rssService.isRead(b.link);

      // Unread comes first (isRead == false < isRead == true)
      if (isReadA != isReadB) {
        return isReadA ? 1 : -1;
      }

      // If same read status, keep original order (assumed date-sorted from service)
      return 0;
    });

    return Scaffold(
      backgroundColor: theme.baseColor,
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        backgroundColor: theme.baseColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.baseColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'RSS Feeder',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your News, Your Way',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.textColor),
              title: Text(
                'Manage Feeds',
                style: TextStyle(color: theme.textColor),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedManagementScreen(),
                  ),
                ).then((_) => _loadFeeds());
              },
            ),
            ListTile(
              leading: Icon(Icons.bookmark, color: theme.textColor),
              title: Text(
                'Saved Articles',
                style: TextStyle(color: theme.textColor),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedArticlesScreen(),
                  ),
                );
              },
            ),
            ExpansionTile(
              leading: Icon(Icons.palette, color: theme.textColor),
              title: Text('Theme', style: TextStyle(color: theme.textColor)),
              children: [
                ListTile(
                  title: Text(
                    'Glass',
                    style: TextStyle(color: theme.textColor),
                  ),
                  trailing: theme.name == 'Glass'
                      ? Icon(Icons.check, color: theme.accentColor)
                      : null,
                  onTap: () => themeService.setTheme('Glass'),
                ),
                ListTile(
                  title: Text(
                    'Neumorphism',
                    style: TextStyle(color: theme.textColor),
                  ),
                  trailing: theme.name == 'Neumorphism'
                      ? Icon(Icons.check, color: theme.accentColor)
                      : null,
                  onTap: () => themeService.setTheme('Neumorphism'),
                ),
                ListTile(
                  title: Text(
                    'Cream',
                    style: TextStyle(color: theme.textColor),
                  ),
                  trailing: theme.name == 'Cream'
                      ? Icon(Icons.check, color: theme.accentColor)
                      : null,
                  onTap: () => themeService.setTheme('Cream'),
                ),
                ListTile(
                  title: Text('Dark', style: TextStyle(color: theme.textColor)),
                  trailing: theme.name == 'Dark'
                      ? Icon(Icons.check, color: theme.accentColor)
                      : null,
                  onTap: () => themeService.setTheme('Dark'),
                ),
              ],
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          'My Feed',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent, // Glass effect covers this
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textColor),
            onPressed: () {
              _loadFeeds();
            },
          ),
        ],
      ),
      body: GlassBackground(
        child: Column(
          children: [
            // Category Tabs
            SizedBox(
              height: 120, // Space for App Bar + Tabs
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _buildCategoryChip(context, 'All', rssService),
                      ...rssService.categories.keys.map(
                        (cat) => _buildCategoryChip(context, cat, rssService),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A5568),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFeeds,
                      color: const Color(0xFF4A5568),
                      child: ListView.builder(
                        itemCount: sortedItems.length,
                        padding: const EdgeInsets.only(
                          top: 16,
                          bottom: 100, // Extra padding for FAB or bottom area
                        ),
                        itemBuilder: (context, index) {
                          final item = sortedItems[index];
                          return _buildFeedItem(
                            item,
                          ); // Keyed by item URL if possible?
                        },
                      ),
                    ),
            ),
            if (_isBannerAdReady)
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    // Access theme
    final theme = Provider.of<ThemeService>(context).currentTheme;
    final rssService = Provider.of<RssService>(
      context,
      listen: false,
    ); // No need to listen here if list rebuilds
    final isRead = rssService.isRead(item.link);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: NeumorphicCard(
        child: InkWell(
          onTap: () => _onArticleTap(item),
          child: AnimatedOpacity(
            // Grey out (reduce opacity) if read
            opacity: isRead ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                if (item.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ColorFiltered(
                      // Optional: Desaturate image if read
                      colorFilter: isRead
                          ? const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
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
                  ),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title ?? 'No Title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isRead
                              ? theme
                                    .secondaryTextColor // Lighter if read
                              : theme.textColor,
                          decoration: isRead ? TextDecoration.none : null,
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
                            fontWeight: FontWeight.w500,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        item.description ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme
                              .secondaryTextColor, // Description usually lighter
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String category,
    RssService rssService,
  ) {
    // Access theme
    final theme = Provider.of<ThemeService>(context).currentTheme;
    final isSelected = rssService.selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () {
          rssService.selectCategory(category);
          _loadFeeds();
        },
        child: NeumorphicCard(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            category,
            style: TextStyle(
              color: isSelected ? theme.accentColor : theme.textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
