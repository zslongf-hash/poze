import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/managers/asset_image_provider.dart';
import '../../data/managers/smart_recommendation_manager.dart';
import '../../data/managers/user_stats_manager.dart';
import '../../data/managers/image_preloader.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/pose_grid_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isInitialized = false;

  final AssetImageProvider _imageProvider = AssetImageProvider();
  final SmartRecommendationManager _recommendationManager = SmartRecommendationManager();
  final UserStatsManager _statsManager = UserStatsManager();
  final ImagePreloader _imagePreloader = ImagePreloader();

  final List<Map<String, dynamic>> _recommendedPoses = [];
  List<String> _smartRecommendations = [];
  UserStats _userStats = UserStats();

  // 12位编码风格配置（代码 -> 显示信息）
  static const Map<String, Map<String, dynamic>> _styleConfig = {
    'a': {'name': '前卫', 'icon': Icons.auto_fix_high, 'color': Colors.purple},
    'b': {'name': '运动休闲', 'icon': Icons.sports_handball, 'color': Colors.orange},
    'c': {'name': '复古', 'icon': Icons.history, 'color': Colors.brown},
    'd': {'name': '极简', 'icon': Icons.minimize, 'color': Colors.grey},
    'e': {'name': '波西米亚', 'icon': Icons.waves, 'color': Colors.teal},
    'f': {'name': '商务', 'icon': Icons.business, 'color': Colors.indigo},
    'g': {'name': '民族', 'icon': Icons.public, 'color': Colors.green},
    'h': {'name': '哥特', 'icon': Icons.dark_mode, 'color': Colors.black87},
    'i': {'name': '朋克', 'icon': Icons.electric_bolt, 'color': Colors.red},
    'j': {'name': '街头', 'icon': Icons.streetview, 'color': Colors.blue},
    'k': {'name': '学院', 'icon': Icons.school, 'color': Colors.amber},
    'l': {'name': '浪漫', 'icon': Icons.favorite, 'color': Colors.pink},
    'm': {'name': '优雅', 'icon': Icons.emoji_events, 'color': Colors.deepPurple},
    'n': {'name': '甜美', 'icon': Icons.cake, 'color': Colors.lightBlue},
    'o': {'name': '日系', 'icon': Icons.wb_cloudy, 'color': Colors.cyan},
    'p': {'name': '韩系', 'icon': Icons.star, 'color': Colors.deepOrange},
  };

  // 服装类型映射
  static const Map<String, Map<String, dynamic>> _clothingTypes = {
    'casual_wear': {
      'name': '休闲装',
      'icon': Icons.weekend,
      'color': Colors.green,
    },
    'formal_wear': {
      'name': '正装',
      'icon': Icons.business,
      'color': Colors.indigo,
    },
    'sports_wear': {
      'name': '运动装',
      'icon': Icons.fitness_center,
      'color': Colors.red,
    },
    'summer_wear': {
      'name': '夏季装',
      'icon': Icons.wb_sunny,
      'color': Colors.amber,
    },
    'winter_wear': {
      'name': '冬季装',
      'icon': Icons.ac_unit,
      'color': Colors.cyan,
    },
    'party_wear': {
      'name': '派对装',
      'icon': Icons.nightlife,
      'color': Colors.pink,
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshImages();
    }
  }

  Future<void> _initialize() async {
    await _imageProvider.initialize();
    await _statsManager.initialize();
    await _recommendationManager.initialize();
    _loadSampleImages();
    _loadSmartRecommendations();
    _loadUserStats();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// 加载智能推荐
  Future<void> _loadSmartRecommendations() async {
    final recommendations = await _recommendationManager.getGuessYouLike(limit: 6);
    if (mounted) {
      setState(() {
        _smartRecommendations = recommendations;
      });
      // 预加载推荐图片
      if (recommendations.isNotEmpty) {
        _imagePreloader.preloadImageList(context, recommendations.take(3).toList());
      }
    }
  }

  /// 加载用户统计
  Future<void> _loadUserStats() async {
    if (mounted) {
      setState(() {
        _userStats = _statsManager.stats;
      });
    }
  }

  void _refreshImages() {
    if (mounted) {
      setState(() {});
    }
  }

  void _loadSampleImages() {
    // 使用12位编码系统，从所有图片中随机取样
    final allImages = _imageProvider.getAllImages(limit: 24);

    int count = 0;
    for (var imagePath in allImages) {
      if (count >= 12) break;
      final globalIndex = _getGlobalIndex(imagePath);
      _recommendedPoses.add({
        'path': imagePath,
        'title': '${globalIndex + 1}',
      });
      count++;
    }
    
    if (mounted) setState(() {});
  }

  int _getGlobalIndex(String imagePath) {
    final allImages = _imageProvider.getAllImages(limit: _imageProvider.totalCount);
    final index = allImages.indexOf(imagePath);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RouteConstants.search),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(RouteConstants.settings),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            context.push(RouteConstants.browse);
          } else if (index == 2) {
            context.push(RouteConstants.favorites);
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserStatsSection(),
          _buildSmartRecommendationSection(),
          _buildQuickAccessSection(),
          _buildEncodingFilterSection(),
          _buildCategorySection(),
          _buildRecommendedSection(),
        ],
      ),
    );
  }

  /// 用户统计展示区域
  Widget _buildUserStatsSection() {
    if (_userStats.totalViews == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.push(RouteConstants.stats),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade400, Colors.purple.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.shade200.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '你的摄影之旅',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.7),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '已浏览 ${_userStats.totalViews} 个姿势 · 收藏 ${_userStats.totalFavorites} 个',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 智能推荐区域
  Widget _buildSmartRecommendationSection() {
    if (_smartRecommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.amber.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '猜你喜欢',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  await _loadSmartRecommendations();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('换一批', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _smartRecommendations.length,
              itemBuilder: (context, index) {
                final imagePath = _smartRecommendations[index];
                final encoded = base64Encode(utf8.encode(imagePath));
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: PoseGridItem(
                    imagePath: imagePath,
                    title: '推荐 ${index + 1}',
                    heroTag: 'pose_$imagePath',
                    onTap: () => context.push('${RouteConstants.detail}/path/$encoded'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 12位编码快速筛选区域
  Widget _buildEncodingFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '快速筛选',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showEncodingFilterDialog(),
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('更多筛选', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 常用筛选标签
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('站姿', Icons.accessibility, Colors.green, {'pose': '站姿'}),
              _buildFilterChip('坐姿', Icons.chair, Colors.blue, {'pose': '坐姿'}),
              _buildFilterChip('长袖', Icons.checkroom, Colors.indigo, {'clothing': '长袖'}),
              _buildFilterChip('短袖', Icons.checkroom, Colors.teal, {'clothing': '短袖'}),
              _buildFilterChip('长发', Icons.face, Colors.purple, {'hair': '长发'}),
              _buildFilterChip('短发', Icons.face, Colors.orange, {'hair': '短发'}),
              _buildFilterChip('开心', Icons.sentiment_satisfied, Colors.yellow, {'emotion': '开心'}),
              _buildFilterChip('酷飒', Icons.sentiment_neutral, Colors.grey, {'emotion': '酷飒'}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color, Map<String, String> filters) {
    return FilterChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onSelected: (selected) {
        if (selected) {
          _navigateToBrowseWithFilters(filters);
        }
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _navigateToBrowseWithFilters(Map<String, String> filters) {
    context.push(RouteConstants.browse, extra: filters);
  }

  void _showEncodingFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _EncodingFilterSheet(
          scrollController: scrollController,
          onApply: (filters) {
            Navigator.pop(context);
            _navigateToBrowseWithFilters(filters);
          },
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    // 获取实际的风格统计
    final stats = _imageProvider.getEncodingStatistics();
    final styleStats = stats['style'] ?? {};

    // 过滤出有照片的风格，并按数量排序
    final activeStyles = styleStats.entries
        .where((e) => e.value > 0 && _styleConfig.containsKey(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 取前8个热门风格，如果不足8个则显示所有
    final topStyles = activeStyles.take(8).toList();

    if (topStyles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '热门风格',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '共${topStyles.length}种',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 使用Wrap自适应布局
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topStyles.map((entry) {
              final styleCode = entry.key;
              final count = entry.value;
              final styleInfo = _styleConfig[styleCode]!;
              final styleName = styleInfo['name'] as String;
              // 获取该风格的第一张图片作为封面
              final coverImage = _getStyleCoverImage(styleCode);
              return _buildQuickAccessCard(
                icon: styleInfo['icon'] as IconData,
                title: styleName,
                subtitle: '$count张',
                color: styleInfo['color'] as Color,
                coverImage: coverImage,
                onTap: () => _navigateToBrowseWithFilters({'style': styleName}),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 获取风格封面图片
  String? _getStyleCoverImage(String styleCode) {
    final images = _imageProvider.getImagesBySingleEncoding('style', styleCode, limit: 1);
    return images.isNotEmpty ? images.first : null;
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? coverImage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, // 固定宽度
        height: 100, // 固定高度
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: coverImage != null
              ? DecorationImage(
                  image: AssetImage(coverImage),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4),
                    BlendMode.darken,
                  ),
                )
              : null,
          gradient: coverImage == null
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: coverImage != null
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (coverImage == null) ...[
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '服装类型',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _clothingTypes.entries.map((entry) {
              final typeKey = entry.key;
              final typeInfo = entry.value;
              return _buildClothingChip(
                typeInfo['name'] as String,
                typeInfo['icon'] as IconData,
                typeInfo['color'] as Color,
                typeKey,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingChip(String title, IconData icon, Color color, String typeKey) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(title, style: const TextStyle(fontSize: 13)),
      onPressed: () => _navigateToBrowse(clothingType: typeKey),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildRecommendedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '精选姿势',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push(RouteConstants.browse),
                child: const Text('更多 ▸', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _recommendedPoses.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _recommendedPoses.length,
                  itemBuilder: (context, index) {
                    final pose = _recommendedPoses[index];
                    final imagePath = pose['path'] as String;
                    final encoded = base64Encode(utf8.encode(imagePath));
                    return PoseGridItem(
                      imagePath: imagePath,
                      title: pose['title'] as String,
                      heroTag: 'pose_$imagePath',
                      onTap: () => context.push('${RouteConstants.detail}/path/$encoded'),
                    );
                  },
                ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.image,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            _isInitialized ? '暂无可用照片' : '正在加载...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _navigateToBrowse({
    String? style,
    String? clothingType,
    String? filterBy,
  }) {
    context.push(RouteConstants.browse, extra: {
      if (style != null) 'style': style,
      if (clothingType != null) 'clothingType': clothingType,
      if (filterBy != null) 'filterBy': filterBy,
    });
  }
}

/// 12位编码筛选底部弹窗
class _EncodingFilterSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Map<String, String>) onApply;

  const _EncodingFilterSheet({
    required this.scrollController,
    required this.onApply,
  });

  @override
  State<_EncodingFilterSheet> createState() => _EncodingFilterSheetState();
}

class _EncodingFilterSheetState extends State<_EncodingFilterSheet> {
  final Map<String, String> _selectedFilters = {};

  final Map<String, Map<String, dynamic>> _filterOptions = {
    'shot_size': {'title': '景别', 'icon': Icons.camera, 'options': ['特写', '近景', '中景', '全景', '远景', '大远景']},
    'pose': {'title': '姿态', 'icon': Icons.accessibility, 'options': ['站姿', '坐姿', '蹲姿', '卧姿', '跪姿']},
    'clothing': {'title': '服装', 'icon': Icons.checkroom, 'options': ['长袖', '短袖', '长裤', '短裤', '长裙', '短裙', '连衣裙', '外套']},
    'hair': {'title': '发型', 'icon': Icons.face, 'options': ['长发', '短发', '盘发', '马尾', '卷发', '直发']},
    'emotion': {'title': '情绪', 'icon': Icons.sentiment_satisfied, 'options': ['开心', '忧郁', '自信', '温柔', '酷飒', '知性']},
    'scene': {'title': '场景', 'icon': Icons.location_on, 'options': ['室内纯色', '室内布景', '街道', '公园', '海边', '自然']},
    'style': {'title': '风格', 'icon': Icons.style, 'options': ['前卫', '运动休闲', '复古', '极简', '商务', '优雅']},
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '高级筛选',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilters.clear();
                    });
                  },
                  child: const Text('重置'),
                ),
              ],
            ),
          ),
          // 筛选内容
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final key = _filterOptions.keys.elementAt(index);
                final option = _filterOptions[key]!;
                return _buildFilterSection(
                  key,
                  option['title'] as String,
                  option['icon'] as IconData,
                  option['options'] as List<String>,
                );
              },
            ),
          ),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () => widget.onApply(_selectedFilters),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('应用筛选 (${_selectedFilters.length})'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String key, String title, IconData icon, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.pink),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = _selectedFilters[key] == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFilters[key] = option;
                  } else {
                    _selectedFilters.remove(key);
                  }
                });
              },
              selectedColor: Colors.pink.withOpacity(0.2),
              checkmarkColor: Colors.pink,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
