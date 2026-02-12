import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/managers/asset_image_provider.dart';
import '../../data/managers/favorites_manager.dart';
import '../../data/managers/image_preloader.dart';
import '../../data/managers/user_stats_manager.dart';
import '../../data/models/pose_tag.dart';

class DetailPage extends StatefulWidget {
  final String poseId;
  final String? imageList;

  const DetailPage({
    super.key,
    required this.poseId,
    this.imageList,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with TickerProviderStateMixin {
  bool _isFavorite = false;

  final AssetImageProvider _imageProvider = AssetImageProvider();
  final FavoritesManager _favoritesManager = FavoritesManager();
  final ImagePreloader _imagePreloader = ImagePreloader();
  final UserStatsManager _statsManager = UserStatsManager();

  String? _mainImagePath;
  int _currentIndex = 0;
  PoseTag? _currentTags;

  // 当前浏览的图片列表（用于左右滑动时限制范围）
  List<String> _currentImageList = [];

  // 选中的特征筛选条件
  final Map<String, String> _selectedFilters = {};

  // 动画控制器
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  double _dragOffset = 0;
  bool _isDragging = false;

  // Hero 动画标签
  String? _heroTag;

  @override
  void initState() {
    super.initState();
    _initialize();

    // 初始化动画控制器
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// 初始化数据
  Future<void> _initialize() async {
    await _imageProvider.initialize();
    await _favoritesManager.initialize();
    await _statsManager.initialize();
    _parsePoseId();
    _checkFavoriteStatus();
    _recordViewStats();
    _preloadAdjacentImages();
  }

  /// 记录浏览统计
  void _recordViewStats() {
    if (_mainImagePath != null) {
      // 提取分类和风格信息
      final encodedImage = _imageProvider.getImageEncoding(_mainImagePath!);
      final category = _extractCategoryFromPath(_mainImagePath!);
      final style = encodedImage?.encoding['style']?.name;
      final pose = encodedImage?.encoding['pose']?.name;

      _statsManager.recordView(
        _mainImagePath!,
        category: category,
        style: style,
        pose: pose,
      );
    }
  }

  /// 预加载相邻图片
  void _preloadAdjacentImages() {
    if (context.mounted && _currentImageList.isNotEmpty) {
      _imagePreloader.preloadAdjacentImages(
        context,
        _currentImageList,
        _currentIndex,
        preloadCount: 2,
      );
    }
  }



  /// 检查当前姿势的收藏状态
  void _checkFavoriteStatus() {
    if (_mainImagePath != null) {
      // 使用图片路径作为ID检查收藏状态
      setState(() {
        _isFavorite = _favoritesManager.isFavorite(_mainImagePath!);
      });
    }
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _parsePoseId() {
    try {
      // 解析图片列表（如果提供了）
      if (widget.imageList != null && widget.imageList!.isNotEmpty) {
        try {
          final decodedList = utf8.decode(base64Decode(widget.imageList!));
          _currentImageList = List<String>.from(jsonDecode(decodedList));
        } catch (e) {
          _currentImageList = [];
        }
      }

      if (widget.poseId.startsWith('path/')) {
        final encoded = widget.poseId.substring(5);
        final imagePath = utf8.decode(base64Decode(encoded));
        _mainImagePath = imagePath;
        _findIndexInCurrentList(imagePath);
      } else if (widget.poseId.startsWith('related_')) {
        _currentIndex = int.tryParse(widget.poseId.replaceFirst('related_', '')) ?? 0;
        _loadMainImage();
      } else if (widget.poseId.startsWith('search_')) {
        _currentIndex = int.tryParse(widget.poseId.replaceFirst('search_', '')) ?? 0;
        _loadMainImage();
      } else {
        _currentIndex = int.tryParse(widget.poseId) ?? 0;
        _loadMainImage();
      }
    } catch (e) {
      _currentIndex = 0;
      _loadMainImage();
    }
  }

  /// 在当前列表中查找图片索引
  void _findIndexInCurrentList(String imagePath) {
    if (_currentImageList.isNotEmpty) {
      // 如果有指定列表，在列表中查找
      final index = _currentImageList.indexOf(imagePath);
      _currentIndex = index >= 0 ? index : 0;
    } else {
      // 否则在全局列表中查找
      final allImages = _imageProvider.getAllImages(limit: _imageProvider.totalCount);
      final index = allImages.indexOf(imagePath);
      _currentIndex = index >= 0 ? index : 0;
    }
    _extractTagsFromPath(imagePath);
    if (mounted) {
      setState(() {});
    }
  }

  void _findIndexByPath(String imagePath) {
    final allImages = _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    final index = allImages.indexOf(imagePath);
    _currentIndex = index >= 0 ? index : 0;
    _extractTagsFromPath(imagePath);
    if (mounted) {
      setState(() {});
    }
  }

  void _loadMainImage() {
    final images = _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    if (images.isNotEmpty && _currentIndex < images.length) {
      setState(() {
        _mainImagePath = images[_currentIndex];
        _extractTagsFromPath(_mainImagePath!);
      });
    } else if (images.isNotEmpty) {
      setState(() {
        _mainImagePath = images.first;
        _currentIndex = 0;
        _extractTagsFromPath(_mainImagePath!);
      });
    }
  }

  void _extractTagsFromPath(String path) {
    final filename = path.split('/').last;
    final segments = path.split('/');
    
    String style = '现代清新';
    String poseType = '站姿_正面站';
    String angle = '平视';
    String expression = '微笑';
    String costume = '连衣裙';
    String scene = '街道';
    String prop = '无';
    String gender = '女性';
    String styleSet = '清新街拍系列1';
    String styleTheme = '都市清新';
    String styleColor = '明亮';
    String styleMood = '活泼';

    if (path.contains('/ancient/')) {
      style = '古风汉服';
      styleSet = '古风汉服系列';
      styleTheme = '古典雅致';
      styleColor = '古韵';
      styleMood = '优雅';
      costume = '齐胸襦裙';
      scene = '古建筑';
    }

    if (segments.any((s) => s.contains('站姿'))) {
      poseType = '站姿_正面站';
      if (segments.any((s) => s.contains('侧面站'))) {
        poseType = '站姿_侧面站';
      } else if (segments.any((s) => s.contains('背面站'))) {
        poseType = '站姿_背面站';
      } else if (segments.any((s) => s.contains('倚靠站'))) {
        poseType = '站姿_倚靠站';
      } else if (segments.any((s) => s.contains('交叉站'))) {
        poseType = '站姿_交叉站';
      } else if (segments.any((s) => s.contains('S型'))) {
        poseType = '站姿_S型站';
      } else if (segments.any((s) => s.contains('单腿'))) {
        poseType = '站姿_单腿站';
      }
    } else if (segments.any((s) => s.contains('坐姿'))) {
      poseType = '坐姿_正坐';
      if (segments.any((s) => s.contains('侧坐'))) {
        poseType = '坐姿_侧坐';
      } else if (segments.any((s) => s.contains('盘腿'))) {
        poseType = '坐姿_盘腿坐';
      } else if (segments.any((s) => s.contains('跪坐'))) {
        poseType = '坐姿_跪坐';
      } else if (segments.any((s) => s.contains('倚坐'))) {
        poseType = '坐姿_倚坐';
      } else if (segments.any((s) => s.contains('抱膝'))) {
        poseType = '坐姿_抱膝坐';
      } else if (segments.any((s) => s.contains('跷腿'))) {
        poseType = '坐姿_跷腿坐';
      }
    } else if (segments.any((s) => s.contains('蹲姿'))) {
      poseType = '蹲姿_正蹲';
      if (segments.any((s) => s.contains('侧蹲'))) {
        poseType = '蹲姿_侧蹲';
      } else if (segments.any((s) => s.contains('单膝'))) {
        poseType = '蹲姿_单膝跪';
      } else if (segments.any((s) => s.contains('双膝'))) {
        poseType = '蹲姿_双膝跪';
      } else if (segments.any((s) => s.contains('半蹲'))) {
        poseType = '蹲姿_半蹲';
      }
    } else if (segments.any((s) => s.contains('动态'))) {
      poseType = '动态_行走';
      if (segments.any((s) => s.contains('旋转'))) {
        poseType = '动态_旋转';
      } else if (segments.any((s) => s.contains('跳跃'))) {
        poseType = '动态_跳跃';
      } else if (segments.any((s) => s.contains('回眸'))) {
        poseType = '动态_回眸';
      } else if (segments.any((s) => s.contains('甩发'))) {
        poseType = '动态_甩发';
      } else if (segments.any((s) => s.contains('撩发'))) {
        poseType = '动态_撩发';
      }
    } else if (segments.any((s) => s.contains('互动'))) {
      poseType = '互动_与道具互动';
      if (segments.any((s) => s.contains('抚脸'))) {
        poseType = '互动_抚脸';
      } else if (segments.any((s) => s.contains('托腮'))) {
        poseType = '互动_托腮';
      }
    } else if (segments.any((s) => s.contains('卧姿'))) {
      poseType = '卧姿_仰卧';
      if (segments.any((s) => s.contains('侧卧'))) {
        poseType = '卧姿_侧卧';
      } else if (segments.any((s) => s.contains('俯卧'))) {
        poseType = '卧姿_俯卧';
      } else if (segments.any((s) => s.contains('半躺'))) {
        poseType = '卧姿_半躺';
      } else if (segments.any((s) => s.contains('倚躺'))) {
        poseType = '卧姿_倚躺';
      }
    }

    if (filename.contains('俯拍') || segments.any((s) => s.contains('俯拍'))) {
      angle = '俯拍';
    } else if (filename.contains('仰拍') || segments.any((s) => s.contains('仰拍'))) {
      angle = '仰拍';
    } else if (filename.contains('侧拍') || segments.any((s) => s.contains('侧拍'))) {
      angle = '侧拍';
    } else if (filename.contains('侧脸') || segments.any((s) => s.contains('侧脸'))) {
      angle = '侧脸';
    } else if (filename.contains('背影') || segments.any((s) => s.contains('背影'))) {
      angle = '背影';
    } else if (filename.contains('45度') || segments.any((s) => s.contains('45度'))) {
      angle = '45度角';
    }

    final expressions = ['微笑', '大笑', '冷艳', '甜美', '自然', '忧郁', '俏皮', '妩媚', '清纯', '酷飒'];
    for (final exp in expressions) {
      if (filename.contains(exp)) {
        expression = exp;
        break;
      }
    }

    setState(() {
      _currentTags = PoseTag(
        style: style,
        poseType: poseType,
        angle: angle,
        expression: expression,
        costume: costume,
        prop: prop,
        scene: scene,
        gender: gender,
        styleSet: styleSet,
        styleTheme: styleTheme,
        styleColor: styleColor,
        styleMood: styleMood,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          '姿势 ${_currentIndex + 1} / ${_imageProvider.totalCount}',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey.shade700),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red.shade400 : Colors.grey.shade600,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部 - 主要姿势图片展示
          Expanded(
            flex: 3,
            child: _buildPhotoSection(),
          ),
          // 中间 - 操作按钮区域
          _buildActionButtonsSection(),
          // 底部 - Dock栏样式缩略图列表
          _buildDockThumbnailBar(),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: _mainImagePath != null
          ? GestureDetector(
              onHorizontalDragStart: (_) {
                setState(() {
                  _isDragging = true;
                  _dragOffset = 0;
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragOffset += details.delta.dx;
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
                // 左右滑动切换图片 - 降低触发阈值，提高响应速度
                if (_dragOffset.abs() > 50 || details.primaryVelocity!.abs() > 200) {
                  if (_dragOffset > 0 || details.primaryVelocity! > 0) {
                    // 向右滑动 - 上一张
                    _showPreviousImage();
                  } else {
                    // 向左滑动 - 下一张
                    _showNextImage();
                  }
                } else {
                  // 回弹动画
                  _resetPosition();
                }
              },
              onVerticalDragEnd: (details) {
                // 上下滑动手势
                if (details.primaryVelocity! > 200) {
                  // 向下滑动 - 查看上一张
                  _showPreviousImage();
                } else if (details.primaryVelocity! < -200) {
                  // 向上滑动 - 收藏
                  _toggleFavorite();
                  // 显示收藏提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isFavorite ? '已收藏' : '已取消收藏'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              child: AnimatedBuilder(
                animation: _slideAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _isDragging ? _dragOffset : _slideAnimation.value.dx * MediaQuery.of(context).size.width,
                      0,
                    ),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Hero(
                        tag: 'pose_${_mainImagePath}',
                        child: Image.asset(
                          _mainImagePath!,
                          fit: BoxFit.contain,
                          // 使用缓存提高性能
                          cacheWidth: 1200,
                          cacheHeight: 1600,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : _buildPlaceholder(),
    );
  }

  void _resetPosition() {
    _slideAnimation = Tween<Offset>(
      begin: Offset(_dragOffset / MediaQuery.of(context).size.width, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _slideAnimationController.forward(from: 0);
  }



  void _showPreviousImage() {
    // 使用当前列表或全局列表
    final images = _currentImageList.isNotEmpty
        ? _currentImageList
        : _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    if (images.isEmpty) return;

    int newIndex = _currentIndex - 1;
    if (newIndex < 0) {
      newIndex = images.length - 1; // 循环到最后一张
    }

    setState(() {
      _currentIndex = newIndex;
      _mainImagePath = images[newIndex];
      _dragOffset = 0;
      _isFavorite = _favoritesManager.isFavorite(_mainImagePath!);
    });
    
    // 记录浏览统计并预加载相邻图片
    _recordViewStats();
    _preloadAdjacentImages();
  }

  void _showNextImage() {
    // 使用当前列表或全局列表
    final images = _currentImageList.isNotEmpty
        ? _currentImageList
        : _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    if (images.isEmpty) return;

    int newIndex = _currentIndex + 1;
    if (newIndex >= images.length) {
      newIndex = 0; // 循环到第一张
    }

    setState(() {
      _currentIndex = newIndex;
      _mainImagePath = images[newIndex];
      _dragOffset = 0;
      _isFavorite = _favoritesManager.isFavorite(_mainImagePath!);
    });
    
    // 记录浏览统计并预加载相邻图片
    _recordViewStats();
    _preloadAdjacentImages();
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite() async {
    if (_mainImagePath == null) return;

    // 使用图片路径作为唯一ID
    final id = _mainImagePath!;
    final title = '姿势 ${_currentIndex + 1}';

    if (_isFavorite) {
      // 取消收藏
      await _favoritesManager.removeFavorite(id);
      setState(() {
        _isFavorite = false;
      });
      // 同步更新统计
      await _statsManager.updateFavoritesCount(_favoritesManager.favorites.length);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已取消收藏'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } else {
      // 添加收藏
      final item = FavoriteItem(
        id: id,
        imagePath: _mainImagePath!,
        title: title,
        addedAt: DateTime.now(),
      );
      await _favoritesManager.addFavorite(item);
      setState(() {
        _isFavorite = true;
      });
      // 同步更新统计
      await _statsManager.updateFavoritesCount(_favoritesManager.favorites.length);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已添加到收藏'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildInfoSection() {
    // 获取图片的12位编码信息
    EncodedImage? encodedImage;
    if (_mainImagePath != null) {
      encodedImage = _imageProvider.getImageEncoding(_mainImagePath!);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 按钮放在上方
          _buildActionButtons(),
          const SizedBox(height: 16),
          // 12位编码标签放在按钮下方
          if (encodedImage != null) ...[
            _buildEncodingChips(encodedImage),
          ],
        ],
      ),
    );
  }

  /// 构建12位编码标签展示 - 支持点击筛选
  Widget _buildEncodingChips(EncodedImage image) {
    // 定义编码位的显示顺序和颜色
    final encodingConfig = [
      {'key': 'shot_size', 'label': '景别', 'color': Colors.red},
      {'key': 'composition', 'label': '构图', 'color': Colors.orange},
      {'key': 'angle', 'label': '角度', 'color': Colors.amber},
      {'key': 'pose', 'label': '姿态', 'color': Colors.green},
      {'key': 'action', 'label': '动作', 'color': Colors.teal},
      {'key': 'emotion', 'label': '情绪', 'color': Colors.blue},
      {'key': 'clothing', 'label': '服装', 'color': Colors.indigo},
      {'key': 'hair', 'label': '发型', 'color': Colors.purple},
      {'key': 'color', 'label': '颜色', 'color': Colors.pink},
      {'key': 'season', 'label': '季节', 'color': Colors.brown},
      {'key': 'scene', 'label': '场景', 'color': Colors.cyan},
      {'key': 'style', 'label': '风格', 'color': Colors.deepPurple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分隔线
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 12),
        // 标题和清除按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '照片特征',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            if (_selectedFilters.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFilters.clear();
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('清除', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // 显示已选筛选条件
        if (_selectedFilters.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedFilters.entries.map((entry) {
              final config = encodingConfig.firstWhere(
                (c) => c['key'] == entry.key,
                orElse: () => {'color': Colors.grey},
              );
              final color = config['color'] as Color;
              return Chip(
                label: Text(
                  entry.value,
                  style: const TextStyle(fontSize: 11),
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  setState(() {
                    _selectedFilters.remove(entry.key);
                  });
                },
                backgroundColor: color.withOpacity(0.2),
                side: BorderSide(color: color),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        // 显示编码标签（可点击）
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: encodingConfig.map((config) {
            final key = config['key'] as String;
            final color = config['color'] as Color;
            final value = image.encoding[key]?.name ?? '未知';
            final isSelected = _selectedFilters[key] == value;

            return ChoiceChip(
              label: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : color.withOpacity(0.9),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFilters[key] = value;
                  } else {
                    _selectedFilters.remove(key);
                  }
                });
              },
              selectedColor: color,
              backgroundColor: color.withOpacity(0.1),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showSimilarPoses,
            icon: const Icon(Icons.camera_alt),
            label: const Text('类似姿势'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade50,
              foregroundColor: Colors.pink.shade700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showRandomPose,
            icon: const Icon(Icons.shuffle),
            label: const Text('随机姿势'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade50,
              foregroundColor: Colors.purple.shade700,
            ),
          ),
        ),
      ],
    );
  }

  void _showSimilarPoses() {
    if (_mainImagePath == null) return;
    
    // 获取当前图片的编码信息
    final encodedImage = _imageProvider.getImageEncoding(_mainImagePath!);
    if (encodedImage == null) return;
    
    // 使用相似度评分系统查找相似图片
    final similarImages = _findSimilarImages(encodedImage);

    if (similarImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有找到类似的姿势')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildSimilarPosesSheet(similarImages),
    );
  }

  /// 使用相似度评分系统查找相似图片
  List<String> _findSimilarImages(EncodedImage source) {
    // 定义各特征的权重（总和为100）
    // 重点是服装，其次是姿态和拍摄角度
    const weights = {
      'clothing': 30,    // 服装类型权重最高
      'pose': 20,        // 姿态
      'angle': 15,       // 拍摄角度
      'action': 10,      // 动作类型
      'hair': 10,        // 发型
      'emotion': 8,      // 情绪
      'scene': 4,        // 场景
      'shot_size': 3,    // 景别
    };

    // 获取所有图片
    final allImages = _imageProvider.allImages;
    
    // 计算每张图片的相似度评分
    final scoredImages = <MapEntry<String, int>>[];
    
    for (final image in allImages) {
      // 跳过当前图片
      if (image.assetPath == _mainImagePath) continue;
      
      int score = 0;
      
      // 计算各特征的匹配得分
      for (final entry in weights.entries) {
        final key = entry.key;
        final weight = entry.value;
        
        final sourceValue = source.encoding[key]?.name;
        final targetValue = image.encoding[key]?.name;
        
        // 如果特征匹配，加上权重分
        if (sourceValue != null && sourceValue == targetValue) {
          score += weight;
        }
      }
      
      // 只保留相似度 >= 40% 的图片
      if (score >= 40) {
        scoredImages.add(MapEntry(image.assetPath, score));
      }
    }
    
    // 按相似度评分降序排序
    scoredImages.sort((a, b) => b.value.compareTo(a.value));
    
    // 返回前50张最相似的图片
    return scoredImages.take(50).map((e) => e.key).toList();
  }

  String _extractStylePrefix(String category) {
    // 从分类中提取风格前缀
    // 例如：edgy_style_casual_wear -> edgy_style
    // 例如：athleisure_sports_wear -> athleisure
    final parts = category.split('_');
    if (parts.length >= 2) {
      // 检查是否是 xxx_style 格式
      if (parts.length >= 3 && parts[parts.length - 2] == 'style') {
        return parts.sublist(0, parts.length - 2).join('_');
      }
      // 否则返回第一部分（如 athleisure）
      return parts[0];
    }
    return '';
  }

  String _extractCategoryFromPath(String path) {
    // 从路径中提取分类，例如：assets/images/pose_samples/edgy_style_casual_wear/xxx.jpg
    // 返回：edgy_style_casual_wear
    final segments = path.split('/');
    for (final segment in segments) {
      // 检查是否包含下划线，且符合分类命名格式
      if (segment.contains('_') &&
          (segment.contains('style') || segment.contains('wear') ||
           segment.contains('leisure') || segment.contains('minimalist'))) {
        return segment;
      }
    }
    // 如果无法提取，返回空字符串
    return '';
  }

  String _getStyleChineseName(String styleKey) {
    final styleMap = {
      'edgy_style': '前卫风格',
      'athleisure': '运动休闲',
      'party_wear': '派对装',
      'minimalist': '极简主义',
      'vintage_style': '复古风格',
      'street_style': '街头风格',
      'gothic_style': '哥特风格',
      'punk_style': '朋克风格',
      'urban_style': '都市风格',
      'bohemian_style': '波西米亚',
      'business_wear': '商务装',
      'sports_wear': '运动装',
      'summer_wear': '夏季装',
      'winter_wear': '冬季装',
      'casual_wear': '休闲装',
      'formal_wear': '正装',
      'ethnic_wear': '民族风',
      'retro_style': '复古风格',
      'romantic_style': '浪漫风格',
      'preppy_style': '学院风',
    };
    return styleMap[styleKey] ?? styleKey;
  }

  String _getClothingTypeChineseName(String typeKey) {
    final typeMap = {
      'casual_wear': '休闲装',
      'formal_wear': '正装',
      'sports_wear': '运动装',
      'summer_wear': '夏季装',
      'winter_wear': '冬季装',
      'party_wear': '派对装',
      'business_wear': '商务装',
    };
    return typeMap[typeKey] ?? typeKey;
  }

  void _showRandomPose() {
    List<String> candidateImages;

    // 如果有选中的筛选条件，在筛选结果中随机
    if (_selectedFilters.isNotEmpty) {
      candidateImages = _imageProvider.getImagesByEncoding(
        pose: _selectedFilters['pose'],
        clothing: _selectedFilters['clothing'],
        hair: _selectedFilters['hair'],
        emotion: _selectedFilters['emotion'],
        scene: _selectedFilters['scene'],
        style: _selectedFilters['style'],
        angle: _selectedFilters['angle'],
        action: _selectedFilters['action'],
        shotSize: _selectedFilters['shot_size'],
        limit: _imageProvider.totalCount,
      );

      if (candidateImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有符合筛选条件的照片')),
        );
        return;
      }
    } else {
      // 没有筛选条件，从所有图片中随机
      candidateImages = _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    }

    if (candidateImages.isEmpty) return;

    // 使用更随机的算法
    final random = DateTime.now().millisecondsSinceEpoch;
    final randomIndex = random % candidateImages.length;
    final randomImage = candidateImages[randomIndex];

    setState(() {
      _mainImagePath = randomImage;
      // 更新当前图片列表，dock栏会同步更新
      _currentImageList = List.from(candidateImages);
      // 设置随机图片的索引
      _currentIndex = randomIndex;
      // 更新收藏状态
      _isFavorite = _favoritesManager.isFavorite(_mainImagePath!);
    });

    // 记录浏览统计并预加载相邻图片
    _recordViewStats();
    _preloadAdjacentImages();
  }

  String _extractStyleFromPath(String path) {
    if (path.contains('/ancient/')) return 'ancient';
    return 'modern';
  }

  String _extractPoseTypeFromPath(String path) {
    if (path.contains('/standing/') || path.contains('standing')) return 'standing';
    if (path.contains('/sitting/') || path.contains('sitting')) return 'sitting';
    if (path.contains('/dynamic/') || path.contains('dynamic')) return 'dynamic';
    if (path.contains('/interaction/') || path.contains('interaction')) return 'interaction';
    if (path.contains('/lying/') || path.contains('lying')) return 'lying';
    if (path.contains('/squatting/') || path.contains('squatting')) return 'squatting';
    return 'standing';
  }

  Widget _buildSimilarPosesSheet(List<String> images) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '类似姿势 (${images.length}张)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imagePath = images[index];
                final globalIndex = _getGlobalIndex(imagePath);
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final encoded = base64Encode(utf8.encode(imagePath));
                    context.push('${RouteConstants.detail}/path/$encoded');
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.broken_image),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${globalIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getGlobalIndex(String imagePath) {
    final allImages = _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    final index = allImages.indexOf(imagePath);
    return index >= 0 ? index : 0;
  }

  Widget _buildRelatedSection() {
    final allImages = _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    final List<String> relatedImages = [];
    final List<int> relatedIndices = [];
    
    for (int i = 0; i < allImages.length; i++) {
      if (i != _currentIndex && relatedImages.length < 10) {
        relatedImages.add(allImages[i]);
        relatedIndices.add(i);
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '更多姿势',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push(RouteConstants.browse),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relatedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildRelatedItem(relatedImages[index], relatedIndices[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRelatedItem(String imagePath, int index) {
    return GestureDetector(
      onTap: () {
        context.pop();
        final encoded = base64Encode(utf8.encode(imagePath));
        context.push('${RouteConstants.detail}/path/$encoded');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: 140,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '姿势 ${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Icon(
          Icons.image,
          size: 80,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  /// 构建操作按钮区域（相似姿势 + 随机姿势）
  Widget _buildActionButtonsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 相似姿势按钮
          Expanded(
            child: _buildActionButton(
              icon: Icons.camera_alt_outlined,
              label: '相似姿势',
              gradientColors: [Colors.pink.shade300, Colors.pink.shade500],
              onTap: _showSimilarPoses,
            ),
          ),
          const SizedBox(width: 16),
          // 随机姿势按钮
          Expanded(
            child: _buildActionButton(
              icon: Icons.shuffle,
              label: '随机姿势',
              gradientColors: [Colors.purple.shade300, Colors.purple.shade500],
              onTap: _showRandomPose,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradientColors[1].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部Dock栏样式缩略图列表
  Widget _buildDockThumbnailBar() {
    // 使用当前列表或全局列表
    final displayImages = _currentImageList.isNotEmpty
        ? _currentImageList
        : _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动指示条
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '更多姿势',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${displayImages.length} 张',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // 缩略图列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                final imagePath = displayImages[index];
                final isSelected = index == _currentIndex;
                
                return GestureDetector(
                  onTap: () {
                    if (index != _currentIndex) {
                      setState(() {
                        _currentIndex = index;
                        _mainImagePath = imagePath;
                        _extractTagsFromPath(imagePath);
                        _isFavorite = _favoritesManager.isFavorite(_mainImagePath!);
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    width: isSelected ? 68 : 58,
                    height: isSelected ? 86 : 76,
                    margin: const EdgeInsets.only(right: 10, bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Colors.pink.shade400,
                              width: 3,
                            )
                          : Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.pink.shade400.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSelected ? 9 : 11),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        // 缩略图使用小尺寸缓存提高性能
                        cacheWidth: 200,
                        cacheHeight: 260,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
