import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_item.dart';

class RssService extends ChangeNotifier {
  static const String _readPrefsKey = 'read_articles';
  // Use a new key for the complex structure to avoid conflicts/crashes with old data types
  static const String _categoriesPrefsKey = 'rss_categories_v1';
  static const String _savedArticlesPrefsKey = 'saved_articles_v1';
  // Legacy key for migration
  static const String _oldPrefsKey = 'rss_feed_urls';

  // Map of Category Name -> List of Feed URLs
  Map<String, List<String>> _categories = {};
  Map<String, List<String>> get categories => Map.unmodifiable(_categories);

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Set<String> _readArticles = {};
  List<FeedItem> _savedArticles = [];
  List<FeedItem> get savedArticles => List.unmodifiable(_savedArticles);

  RssService() {
    _initFeeds();
  }

  bool isSaved(String? link) {
    if (link == null) return false;
    return _savedArticles.any((item) => item.link == link);
  }

  Future<void> toggleSaveArticle(FeedItem item) async {
    if (item.link == null) return;

    if (isSaved(item.link)) {
      _savedArticles.removeWhere((i) => i.link == item.link);
    } else {
      _savedArticles.add(item);
    }
    notifyListeners();
    await _saveSavedArticles();
  }

  Future<void> _saveSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _savedArticles
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(_savedArticlesPrefsKey, jsonList);
  }

  bool isRead(String? url) {
    if (url == null) return false;
    return _readArticles.contains(url);
  }

  Future<void> markAsRead(String url) async {
    if (!_readArticles.contains(url)) {
      _readArticles.add(url);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readPrefsKey, _readArticles.toList());
    }
  }

  Future<void> addCategory(String name) async {
    if (!_categories.containsKey(name)) {
      _categories[name] = [];
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> removeCategory(String name) async {
    if (_categories.containsKey(name)) {
      _categories.remove(name);
      if (_selectedCategory == name) {
        _selectedCategory = 'All';
      }
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> addFeed(String category, String url) async {
    if (_categories.containsKey(category) &&
        !_categories[category]!.contains(url)) {
      _categories[category]!.add(url);
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> removeFeed(String category, String url) async {
    if (_categories.containsKey(category)) {
      _categories[category]!.remove(url);
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> _initFeeds() async {
    final prefs = await SharedPreferences.getInstance();

    // Load read articles
    final savedRead = prefs.getStringList(_readPrefsKey);
    if (savedRead != null) {
      _readArticles = savedRead.toSet();
    }

    // Load Saved Articles
    final savedArticlesJson = prefs.getStringList(_savedArticlesPrefsKey);
    if (savedArticlesJson != null) {
      _savedArticles = savedArticlesJson
          .map((str) => FeedItem.fromJson(jsonDecode(str)))
          .toList();
    }

    // Load Categories
    final savedCategoriesJson = prefs.getString(_categoriesPrefsKey);
    if (savedCategoriesJson != null) {
      try {
        final decoded = jsonDecode(savedCategoriesJson) as Map<String, dynamic>;
        _categories = decoded.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        );
      } catch (e) {
        print("Error parsing categories: $e");
        _loadDefaultFeeds();
      }
    } else {
      // Check for legacy migration
      final oldList = prefs.getStringList(_oldPrefsKey);
      if (oldList != null && oldList.isNotEmpty) {
        _categories = {'General': oldList};
        await _saveCategories();
      } else {
        _loadDefaultFeeds();
      }
    }
    notifyListeners();
  }

  void _loadDefaultFeeds() {
    _categories = {
      'News': ['https://feeds.bbci.co.uk/news/world/rss.xml'],
      'Tech': [
        'https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml',
        'https://www.theverge.com/rss/index.xml',
      ],
    };
    _saveCategories();
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoriesPrefsKey, jsonEncode(_categories));
  }

  Future<List<FeedItem>> fetchFeeds() async {
    List<String> urlsToFetch = [];

    if (_selectedCategory == 'All') {
      // Flatten all categories
      for (var list in _categories.values) {
        urlsToFetch.addAll(list);
      }
    } else {
      if (_categories.containsKey(_selectedCategory)) {
        urlsToFetch.addAll(_categories[_selectedCategory]!);
      }
    }

    if (urlsToFetch.isEmpty) return [];

    // 1. Fetch all feeds in parallel
    final responses = await Future.wait(
      urlsToFetch.map((url) => _fetchSingleFeedContent(url)),
    );

    // 2. Filter out nulls and prepare for parsing
    final rawContents = responses.whereType<String>().toList();

    if (rawContents.isEmpty) return [];

    // 3. Parse in background (compute) to avoid UI jank
    final allItems = await compute(_parseRssContent, rawContents);

    // 4. Sort by date descending
    allItems.sort(
      (a, b) =>
          (b.pubDate ?? DateTime.now()).compareTo(a.pubDate ?? DateTime.now()),
    );

    return allItems;
  }

  /// Helper to fetch content for a single URL (returns null on failure)
  Future<String?> _fetchSingleFeedContent(String url) async {
    try {
      if (kIsWeb) {
        final fetchUrl = Uri.parse(
          'https://api.allorigins.win/get?url=${Uri.encodeComponent(url)}&disableCache=true',
        );
        final response = await http.get(fetchUrl);
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['contents'] as String?;
        }
      } else {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return response.body;
        }
      }
    } catch (e) {
      print('Error fetching feed $url: $e');
    }
    return null;
  }

  // Top-level function for compute
  static List<FeedItem> _parseRssContent(List<String> rawContents) {
    List<FeedItem> items = [];
    for (String xmlBody in rawContents) {
      try {
        final document = XmlDocument.parse(xmlBody);
        final xmlItems = document.findAllElements('item');

        for (var item in xmlItems) {
          final title = item.getElement('title')?.text;
          final description = item.getElement('description')?.text;
          final link = item.getElement('link')?.text;
          final pubDateString = item.getElement('pubDate')?.text;

          String? imageUrl =
              item.getElement('media:content')?.getAttribute('url') ??
              item.getElement('enclosure')?.getAttribute('url');

          // Fallback image extraction
          if (imageUrl == null && description != null) {
            final RegExp regExp = RegExp(r'<img[^>]+src="([^">]+)"');
            final match = regExp.firstMatch(description);
            if (match != null) imageUrl = match.group(1);
          }

          // Note: kIsWeb is constant, but inside compute/isolate, we should avoid closure captures if possible.
          // However, for image proxying, we might need to handle it post-parsing or pass a flag.
          // Since we are parsing raw strings, we just extract the URL here.
          // If we need to proxy for web, we can do it after receiving the list back in the main thread
          // OR we can trust the static kIsWeb if the platform supports it in isolates (web does: main thread).
          // For safety, let's fixup image URLs in the main method after compute or just here if platform allows.
          // We will do a generic fix here assuming standard http.

          DateTime? pubDate;
          if (pubDateString != null) {
            try {
              pubDate = HttpDate.parse(pubDateString);
            } catch (_) {
              try {
                // Try varied formats
                pubDate = DateFormat(
                  "EEE, dd MMM yyyy HH:mm:ss Z",
                ).parse(pubDateString);
              } catch (e) {
                // ignore
              }
            }
          }

          String? content = item.getElement('content:encoded')?.text;
          if (content == null || content.trim().isEmpty) {
            content = description;
          }

          // Clean description
          String? cleanDesc;
          if (description != null) {
            cleanDesc = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          }

          items.add(
            FeedItem(
              title: title,
              description: cleanDesc,
              link: link,
              imageUrl: imageUrl,
              content: content,
              pubDate: pubDate,
            ),
          );
        }
      } catch (e) {
        print('Error parsing XML chunk: $e');
      }
    }
    return items;
  }

  // ... existing methods

  String exportToOpml() {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'opml',
      attributes: {'version': '1.0'},
      nest: () {
        builder.element(
          'head',
          nest: () {
            builder.element('title', nest: 'RSS Feeder Export');
          },
        );
        builder.element(
          'body',
          nest: () {
            _categories.forEach((category, urls) {
              builder.element(
                'outline',
                attributes: {'text': category, 'title': category},
                nest: () {
                  for (var url in urls) {
                    builder.element(
                      'outline',
                      attributes: {
                        'type': 'rss',
                        'text':
                            url, // Title is often unknown, using URL as fallback text
                        'xmlUrl': url,
                      },
                    );
                  }
                },
              );
            });
          },
        );
      },
    );
    return builder.buildDocument().toXmlString(pretty: true);
  }

  Future<void> importFromOpml(String opmlContent) async {
    try {
      final document = XmlDocument.parse(opmlContent);
      final body = document.findAllElements('body').firstOrNull;
      if (body == null) return;

      // Temporary map to hold new structure
      Map<String, List<String>> newCategories = {};

      // 1. Look for top-level outlines that are categories (have children)
      final categoryOutlines = body
          .findElements('outline')
          .where(
            (element) => element.children.any(
              (child) => child is XmlElement && child.name.local == 'outline',
            ),
          );

      for (var catOutline in categoryOutlines) {
        final catName =
            catOutline.getAttribute('text') ??
            catOutline.getAttribute('title') ??
            'Unnamed Category';
        List<String> urls = [];

        final feedOutlines = catOutline.findElements('outline');
        for (var feed in feedOutlines) {
          final url = feed.getAttribute('xmlUrl');
          if (url != null && url.isNotEmpty) {
            urls.add(url);
          }
        }
        if (urls.isNotEmpty) {
          newCategories[catName] = urls;
        }
      }

      // 2. Look for top-level outlines that are just feeds (no children or type="rss")
      final topLevelFeeds = body
          .findElements('outline')
          .where(
            (element) => !element.children.any(
              (child) => child is XmlElement && child.name.local == 'outline',
            ),
          );
      List<String> uncategorized = [];
      for (var feed in topLevelFeeds) {
        final url = feed.getAttribute('xmlUrl');
        if (url != null && url.isNotEmpty) {
          uncategorized.add(url);
        }
      }

      if (uncategorized.isNotEmpty) {
        if (newCategories.containsKey('General')) {
          newCategories['General']!.addAll(uncategorized);
        } else {
          newCategories['General'] = uncategorized;
        }
      }

      // Merge or Overwrite? Let's Merge.
      // Actually, user might want to restore. Let's add non-duplicates.
      newCategories.forEach((cat, urls) {
        if (!_categories.containsKey(cat)) {
          _categories[cat] = [];
        }
        for (var url in urls) {
          if (!_categories[cat]!.contains(url)) {
            _categories[cat]!.add(url);
          }
        }
      });

      await _saveCategories();
      notifyListeners();
    } catch (e) {
      print("Error parsing OPML: $e");
      rethrow; // Let UI handle error
    }
  }
}
