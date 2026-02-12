import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/managers/asset_image_provider.dart';
import '../widgets/pose_grid_item.dart';

class BrowsePage extends StatefulWidget {
  final Map<String, String>? filters;

  const BrowsePage({
    super.key,
    this.filters,
  });

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final AssetImageProvider _imageProvider = AssetImageProvider();
  bool _isLoading = true;
  int _currentLimit = 30;

  // 当前筛选条件
  final Map<String, String> _activeFilters = {};

  // 12位编码筛选配置
  final List<Map<String, dynamic>> _filterConfigs = [
    {
      'key': 'pose',
      'title': '姿态',
      'icon': Icons.accessibility,
      'options': ['站姿', '坐姿', '蹲姿', '卧姿', '跪姿'],
    },
    {
      'key': 'clothing',
      'title': '服装',
      'icon': Icons.checkroom,
      'options': ['长袖', '短袖', '长裤', '短裤', '长裙', '短裙', '连衣裙', '外套'],
    },
    {
      'key': 'hair',
      'title': '发型',
      'icon': Icons.face,
      'options': ['长发', '短发', '盘发', '马尾', '卷发', '直发'],
    },
    {
      'key': 'emotion',
      'title': '情绪',
      'icon': Icons.sentiment_satisfied,
      'options': ['开心', '忧郁', '自信', '温柔', '酷飒', '知性', '性感', '优雅'],
    },
    {
      'key': 'scene',
      'title': '场景',
      'icon': Icons.location_on,
      'options': ['室内纯色', '室内布景', '街道', '公园', '海边', '自然', '工作室'],
    },
    {
      'key': 'style',
      'title': '风格',
      'icon': Icons.style,
      'options': ['前卫', '运动休闲', '复古', '极简', '商务', '优雅', '甜美', '街头'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadImages();

    // 应用传入的筛选条件
    if (widget.filters != null) {
      _activeFilters.addAll(widget.filters!);
    }
  }

  Future<void> _loadImages() async {
    await _imageProvider.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('浏览姿势 (${_imageProvider.totalCount}张)'),
        actions: [
          // 清除筛选按钮
          if (_activeFilters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  _activeFilters.clear();
                  _currentLimit = 30;
                });
              },
              tooltip: '清除筛选',
            ),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          _buildFilterBar(),
          // 图片网格
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBrowseGrid(),
          ),
        ],
      ),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 筛选分类标签
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterConfigs.map((config) {
                final key = config['key'] as String;
                final title = config['title'] as String;
                final hasFilter = _activeFilters.containsKey(key);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(
                      config['icon'] as IconData,
                      size: 16,
                      color: hasFilter ? Colors.pink : Colors.grey,
                    ),
                    label: Text(
                      hasFilter ? '${config['title']}:${_activeFilters[key]}' : title,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasFilter ? Colors.pink : Colors.black87,
                      ),
                    ),
                    onPressed: () => _showFilterOptions(config),
                    backgroundColor: hasFilter
                        ? Colors.pink.withOpacity(0.1)
                        : Colors.grey.shade100,
                    side: hasFilter
                        ? const BorderSide(color: Colors.pink)
                        : BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
          // 已选筛选条件展示
          if (_activeFilters.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _activeFilters.entries.map((entry) {
                return Chip(
                  label: Text(
                    '${_getFilterTitle(entry.key)}: ${entry.value}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _activeFilters.remove(entry.key);
                      _currentLimit = 30;
                    });
                  },
                  backgroundColor: Colors.pink.withOpacity(0.1),
                  side: const BorderSide(color: Colors.pink),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getFilterTitle(String key) {
    final config = _filterConfigs.firstWhere(
      (c) => c['key'] == key,
      orElse: () => {'title': key},
    );
    return config['title'] as String;
  }

  void _showFilterOptions(Map<String, dynamic> config) {
    final key = config['key'] as String;
    final title = config['title'] as String;
    final options = config['options'] as List<String>;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '选择$title',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_activeFilters.containsKey(key))
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _activeFilters.remove(key);
                          _currentLimit = 30;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('清除'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((option) {
                  final isSelected = _activeFilters[key] == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        if (isSelected) {
                          _activeFilters.remove(key);
                        } else {
                          _activeFilters[key] = option;
                        }
                        _currentLimit = 30;
                      });
                      Navigator.pop(context);
                    },
                    selectedColor: Colors.pink.withOpacity(0.2),
                    checkmarkColor: Colors.pink,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrowseGrid() {
    final images = _getFilteredImages();

    if (images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _activeFilters.isEmpty ? '暂无可用照片' : '没有符合条件的照片',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (_activeFilters.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _activeFilters.clear();
                    _currentLimit = 30;
                  });
                },
                child: const Text('清除筛选条件'),
              ),
            ],
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMore();
        }
        return true;
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imagePath = images[index];
          final displayIndex = _getGlobalIndex(imagePath);
          return PoseGridItem(
            imagePath: imagePath,
            title: '${displayIndex + 1}',
            heroTag: 'pose_$imagePath',
            onTap: () {
              // 传递当前筛选后的图片列表和当前索引
              final encodedList = base64Encode(utf8.encode(jsonEncode(images)));
              final encodedPath = base64Encode(utf8.encode(imagePath));
              context.push('${RouteConstants.detail}/path/$encodedPath?list=$encodedList');
            },
          );
        },
      ),
    );
  }

  void _loadMore() {
    final allImages = _getFilteredImages();
    if (allImages.length >= _currentLimit &&
        _currentLimit < _imageProvider.totalCount) {
      setState(() {
        _currentLimit += 30;
      });
    }
  }

  int _getGlobalIndex(String imagePath) {
    final allImages = _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    final index = allImages.indexOf(imagePath);
    return index >= 0 ? index : 0;
  }

  List<String> _getFilteredImages() {
    if (_activeFilters.isEmpty) {
      return _imageProvider.getAllImages(limit: _currentLimit);
    }

    // 使用12位编码系统进行筛选
    return _imageProvider.getImagesByEncoding(
      pose: _activeFilters['pose'],
      clothing: _activeFilters['clothing'],
      hair: _activeFilters['hair'],
      emotion: _activeFilters['emotion'],
      scene: _activeFilters['scene'],
      style: _activeFilters['style'],
      limit: _currentLimit,
    );
  }
}
