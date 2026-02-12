import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/managers/asset_image_provider.dart';
import '../widgets/pose_grid_item.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [];
  final List<String> _hotTags = [
    '休闲装', '正装', '运动装', '夏季装', '冬季装', '派对装', '复古', '前卫'
  ];
  
  final AssetImageProvider _imageProvider = AssetImageProvider();

  @override
  void initState() {
    super.initState();
    _imageProvider.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索姿势、风格、服装...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _performSearch(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
            child: const Text('搜索'),
          ),
        ],
      ),
      body: _searchController.text.isEmpty
          ? _buildSearchSuggestions()
          : _buildSearchResults(),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最近搜索',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            '热门标签',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hotTags.map((tag) {
              return FilterChip(
                label: Text(tag),
                onSelected: (selected) {
                  _searchController.text = tag;
                  _performSearch(tag);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            '按分类浏览',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildCategoryList(),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = [
      {'icon': Icons.style, 'title': '风格', 'subtitle': '前卫风格、运动休闲、复古风格、街头风格'},
      {'icon': Icons.checkroom, 'title': '服装类型', 'subtitle': '休闲装、正装、运动装、夏季装、冬季装'},
    ];

    return Column(
      children: categories.map((category) {
        return ListTile(
          leading: Icon(category['icon'] as IconData),
          title: Text(category['title'] as String),
          subtitle: Text(category['subtitle'] as String),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(RouteConstants.browse);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    final sampleImages = _getSampleImages();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sampleImages.length,
      itemBuilder: (context, index) {
        final imagePath = sampleImages[index];
        final encoded = base64Encode(utf8.encode(imagePath));
        return PoseGridItem(
          imagePath: imagePath,
          title: '搜索结果 ${index + 1}',
          onTap: () => context.push('${RouteConstants.detail}/path/$encoded'),
        );
      },
    );
  }

  List<String> _getSampleImages() {
    return _imageProvider.getAllImages(limit: 12);
  }

  void _performSearch(String query) {
    setState(() {
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      }
    });
  }
}
