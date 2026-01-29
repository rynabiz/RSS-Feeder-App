import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rss_service.dart';
import '../services/theme_service.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/glass_background.dart';

class FeedManagementScreen extends StatefulWidget {
  const FeedManagementScreen({Key? key}) : super(key: key);

  @override
  State<FeedManagementScreen> createState() => _FeedManagementScreenState();
}

class _FeedManagementScreenState extends State<FeedManagementScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  Future<void> _importOpml() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
      );

      if (result != null) {
        String content;
        if (kIsWeb) {
          // On web, bytes are available
          content = String.fromCharCodes(result.files.single.bytes!);
        } else {
          // On mobile/desktop, read from path
          final file = File(result.files.single.path!);
          content = await file.readAsString();
        }

        if (mounted) {
          await Provider.of<RssService>(
            context,
            listen: false,
          ).importFromOpml(content);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OPML Imported Successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing OPML: $e')));
      }
    }
  }

  Future<void> _exportOpml() async {
    try {
      final rssService = Provider.of<RssService>(context, listen: false);
      final xmlString = rssService.exportToOpml();

      if (kIsWeb) {
        // Web download approach (using universal_html requires adding dependency or simple anchor trick via dart:js_interop/legacy)
        // For simplicity, we can just show a dialog with text or try a basic download shim.
        // Let's print to console or show logic. A proper web download needs 'anchor' element creation.
        // Ignoring Web file save specific logic for this concise step, or using a simple heuristic.
        print("Exported XML: $xmlString");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Check console for XML (Web download not fully implemented)',
            ),
          ),
        );
      } else {
        // Mobile/Desktop: Pick a directory or save to Documents
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save OPML File',
          fileName: 'feeds_export.opml',
          type: FileType.custom,
          allowedExtensions: ['opml'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(xmlString);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Saved to $outputFile')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
      }
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_categoryController.text.isNotEmpty) {
                  Provider.of<RssService>(
                    context,
                    listen: false,
                  ).addCategory(_categoryController.text.trim());
                  _categoryController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddFeedDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Feed to $category'),
          content: TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'RSS Feed URL'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_urlController.text.isNotEmpty) {
                  Provider.of<RssService>(
                    context,
                    listen: false,
                  ).addFeed(category, _urlController.text.trim());
                  _urlController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Feed added')));
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rssService = Provider.of<RssService>(context);
    final theme = Provider.of<ThemeService>(context).currentTheme;
    final categories = rssService.categories;

    return Scaffold(
      backgroundColor: theme.baseColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Manage Feeds', style: TextStyle(color: theme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            tooltip: 'Add Category',
            onPressed: () => _showAddCategoryDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import') {
                _importOpml();
              } else if (value == 'export') {
                _exportOpml();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'import',
                  child: Text('Import OPML'),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Text('Export OPML'),
                ),
              ];
            },
          ),
        ],
      ),
      body: GlassBackground(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
          itemCount: categories.keys.length,
          itemBuilder: (context, index) {
            final categoryName = categories.keys.elementAt(index);
            final feedUrls = categories[categoryName]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: NeumorphicCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      categoryName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: theme.textColor,
                      ),
                    ),
                    collapsedIconColor: theme.textColor,
                    iconColor: theme.accentColor,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: theme.textColor,
                          ),
                          tooltip: 'Add Feed',
                          onPressed: () =>
                              _showAddFeedDialog(context, categoryName),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Delete Category',
                          onPressed: () =>
                              rssService.removeCategory(categoryName),
                        ),
                      ],
                    ),
                    children: [
                      if (feedUrls.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No feeds in this category"),
                        ),
                      ...feedUrls.map(
                        (url) => ListTile(
                          title: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textColor,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.amber,
                            ),
                            tooltip: 'Remove Feed',
                            onPressed: () =>
                                rssService.removeFeed(categoryName, url),
                          ),
                        ),
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
