import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 收藏数据模型
class FavoriteItem {
  final String id;
  final String imagePath;
  final String title;
  final DateTime addedAt;

  FavoriteItem({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'title': title,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      title: json['title'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

/// 收藏管理器 - 使用 SharedPreferences 持久化存储
class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  static const String _storageKey = 'favorites';
  List<FavoriteItem> _favorites = [];
  bool _initialized = false;

  /// 初始化，从本地存储加载收藏数据
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_storageKey);
      
      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(favoritesJson);
        _favorites = decoded
            .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      _initialized = true;
    } catch (e) {
      _favorites = [];
      _initialized = true;
    }
  }

  /// 获取所有收藏
  List<FavoriteItem> get favorites => List.unmodifiable(_favorites);

  /// 检查是否已收藏
  bool isFavorite(String id) {
    return _favorites.any((item) => item.id == id);
  }

  /// 添加收藏
  Future<bool> addFavorite(FavoriteItem item) async {
    if (isFavorite(item.id)) return false;
    
    _favorites.add(item);
    await _saveToStorage();
    return true;
  }

  /// 移除收藏
  Future<bool> removeFavorite(String id) async {
    final index = _favorites.indexWhere((item) => item.id == id);
    if (index == -1) return false;
    
    _favorites.removeAt(index);
    await _saveToStorage();
    return true;
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(FavoriteItem item) async {
    if (isFavorite(item.id)) {
      return await removeFavorite(item.id);
    } else {
      return await addFavorite(item);
    }
  }

  /// 清空所有收藏
  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveToStorage();
  }

  /// 保存到本地存储
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = jsonEncode(
        _favorites.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, favoritesJson);
    } catch (e) {
      // 保存失败
    }
  }

  /// 获取收藏数量
  int get count => _favorites.length;
}
