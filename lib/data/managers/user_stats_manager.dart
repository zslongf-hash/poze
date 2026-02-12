import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户使用统计数据模型
class UserStats {
  final int totalViews;
  final int totalFavorites;
  final Map<String, int> categoryViews;
  final Map<String, int> styleViews;
  final Map<String, int> poseViews;
  final List<ViewHistoryItem> recentViews;
  final DateTime lastUpdated;

  UserStats({
    this.totalViews = 0,
    this.totalFavorites = 0,
    Map<String, int>? categoryViews,
    Map<String, int>? styleViews,
    Map<String, int>? poseViews,
    List<ViewHistoryItem>? recentViews,
    DateTime? lastUpdated,
  })  : categoryViews = categoryViews ?? {},
        styleViews = styleViews ?? {},
        poseViews = poseViews ?? {},
        recentViews = recentViews ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'totalViews': totalViews,
        'totalFavorites': totalFavorites,
        'categoryViews': categoryViews,
        'styleViews': styleViews,
        'poseViews': poseViews,
        'recentViews': recentViews.map((e) => e.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        totalViews: json['totalViews'] ?? 0,
        totalFavorites: json['totalFavorites'] ?? 0,
        categoryViews: Map<String, int>.from(json['categoryViews'] ?? {}),
        styleViews: Map<String, int>.from(json['styleViews'] ?? {}),
        poseViews: Map<String, int>.from(json['poseViews'] ?? {}),
        recentViews: (json['recentViews'] as List?)
                ?.map((e) => ViewHistoryItem.fromJson(e))
                .toList() ??
            [],
        lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
      );

  UserStats copyWith({
    int? totalViews,
    int? totalFavorites,
    Map<String, int>? categoryViews,
    Map<String, int>? styleViews,
    Map<String, int>? poseViews,
    List<ViewHistoryItem>? recentViews,
    DateTime? lastUpdated,
  }) =>
      UserStats(
        totalViews: totalViews ?? this.totalViews,
        totalFavorites: totalFavorites ?? this.totalFavorites,
        categoryViews: categoryViews ?? Map.from(this.categoryViews),
        styleViews: styleViews ?? Map.from(this.styleViews),
        poseViews: poseViews ?? Map.from(this.poseViews),
        recentViews: recentViews ?? List.from(this.recentViews),
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// 浏览历史项
class ViewHistoryItem {
  final String imagePath;
  final DateTime viewedAt;
  final String? category;
  final String? style;

  ViewHistoryItem({
    required this.imagePath,
    required this.viewedAt,
    this.category,
    this.style,
  });

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'viewedAt': viewedAt.toIso8601String(),
        'category': category,
        'style': style,
      };

  factory ViewHistoryItem.fromJson(Map<String, dynamic> json) => ViewHistoryItem(
        imagePath: json['imagePath'] ?? '',
        viewedAt: DateTime.tryParse(json['viewedAt'] ?? '') ?? DateTime.now(),
        category: json['category'],
        style: json['style'],
      );
}

/// 用户统计管理器
class UserStatsManager {
  static const String _storageKey = 'user_stats';
  static const int _maxHistoryItems = 100;

  static final UserStatsManager _instance = UserStatsManager._internal();
  factory UserStatsManager() => _instance;
  UserStatsManager._internal();

  UserStats _stats = UserStats();
  bool _isInitialized = false;

  UserStats get stats => _stats;

  /// 初始化
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        _stats = UserStats.fromJson(json);
      } catch (e) {
        _stats = UserStats();
      }
    }

    _isInitialized = true;
  }

  /// 记录浏览
  Future<void> recordView(
    String imagePath, {
    String? category,
    String? style,
    String? pose,
  }) async {
    await initialize();

    final newCategoryViews = Map<String, int>.from(_stats.categoryViews);
    final newStyleViews = Map<String, int>.from(_stats.styleViews);
    final newPoseViews = Map<String, int>.from(_stats.poseViews);
    final newRecentViews = List<ViewHistoryItem>.from(_stats.recentViews);

    // 更新分类统计
    if (category != null) {
      newCategoryViews[category] = (newCategoryViews[category] ?? 0) + 1;
    }

    // 更新风格统计
    if (style != null) {
      newStyleViews[style] = (newStyleViews[style] ?? 0) + 1;
    }

    // 更新姿势统计
    if (pose != null) {
      newPoseViews[pose] = (newPoseViews[pose] ?? 0) + 1;
    }

    // 添加到浏览历史
    newRecentViews.insert(
      0,
      ViewHistoryItem(
        imagePath: imagePath,
        viewedAt: DateTime.now(),
        category: category,
        style: style,
      ),
    );

    // 限制历史记录数量
    if (newRecentViews.length > _maxHistoryItems) {
      newRecentViews.removeRange(_maxHistoryItems, newRecentViews.length);
    }

    _stats = _stats.copyWith(
      totalViews: _stats.totalViews + 1,
      categoryViews: newCategoryViews,
      styleViews: newStyleViews,
      poseViews: newPoseViews,
      recentViews: newRecentViews,
      lastUpdated: DateTime.now(),
    );

    await _saveStats();
  }

  /// 更新收藏数
  Future<void> updateFavoritesCount(int count) async {
    await initialize();
    _stats = _stats.copyWith(
      totalFavorites: count,
      lastUpdated: DateTime.now(),
    );
    await _saveStats();
  }

  /// 获取最常查看的风格（用于智能推荐）
  List<String> getTopStyles({int limit = 3}) {
    final sorted = _stats.styleViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// 获取最常查看的分类
  List<String> getTopCategories({int limit = 3}) {
    final sorted = _stats.categoryViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// 获取最近浏览的图片路径
  List<String> getRecentViewedPaths({int limit = 10}) {
    return _stats.recentViews
        .take(limit)
        .map((e) => e.imagePath)
        .toList();
  }

  /// 清除统计数据
  Future<void> clearStats() async {
    _stats = UserStats();
    await _saveStats();
  }

  /// 保存统计数据
  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_stats.toJson());
    await prefs.setString(_storageKey, jsonString);
  }
}
