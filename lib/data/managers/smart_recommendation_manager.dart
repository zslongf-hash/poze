import 'dart:math';
import 'asset_image_provider.dart';
import 'user_stats_manager.dart';
import '../models/pose_tag.dart';

/// 智能推荐管理器
/// 基于用户浏览历史和收藏数据提供个性化推荐
class SmartRecommendationManager {
  static final SmartRecommendationManager _instance =
      SmartRecommendationManager._internal();
  factory SmartRecommendationManager() => _instance;
  SmartRecommendationManager._internal();

  final AssetImageProvider _imageProvider = AssetImageProvider();
  final UserStatsManager _statsManager = UserStatsManager();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _imageProvider.initialize();
    await _statsManager.initialize();
    _isInitialized = true;
  }

  /// 获取个性化推荐姿势
  /// 基于用户浏览历史和偏好风格
  Future<List<RecommendedPose>> getPersonalizedRecommendations({int limit = 10}) async {
    await initialize();

    final topStyles = _statsManager.getTopStyles(limit: 3);
    final topCategories = _statsManager.getTopCategories(limit: 3);
    final recentPaths = _statsManager.getRecentViewedPaths(limit: 20);

    final allImages = _imageProvider.allImages;
    final scoredPoses = <RecommendedPose>[];

    for (final image in allImages) {
      // 跳过最近浏览过的
      if (recentPaths.contains(image.assetPath)) continue;

      int score = 0;
      String reason = '';

      // 基于风格偏好评分
      final imageStyle = image.encoding['style']?.name ?? '';
      if (topStyles.contains(imageStyle)) {
        score += 30;
        reason = '基于你喜欢的$imageStyle风格';
      }

      // 基于分类偏好评分
      final imageCategory = _extractCategoryFromEncoding(image);
      if (topCategories.contains(imageCategory)) {
        score += 20;
        if (reason.isEmpty) {
          reason = '与你常看的分类相似';
        }
      }

      // 基于浏览历史中的相似特征
      score += _calculateSimilarityScore(image, recentPaths);

      // 随机因子（让推荐不那么重复）
      score += Random().nextInt(10);

      if (score > 0) {
        scoredPoses.add(RecommendedPose(
          imagePath: image.assetPath,
          score: score,
          reason: reason.isEmpty ? '为你推荐' : reason,
          encoding: image,
        ));
      }
    }

    // 按分数排序并返回前N个
    scoredPoses.sort((a, b) => b.score.compareTo(a.score));
    return scoredPoses.take(limit).toList();
  }

  /// 获取"猜你喜欢"推荐
  Future<List<String>> getGuessYouLike({int limit = 6}) async {
    final recommendations = await getPersonalizedRecommendations(limit: limit);
    return recommendations.map((r) => r.imagePath).toList();
  }

  /// 获取基于当前姿势的推荐
  Future<List<String>> getRelatedRecommendations(
    String currentImagePath, {
    int limit = 6,
  }) async {
    await initialize();

    final currentEncoding = _imageProvider.getImageEncoding(currentImagePath);
    if (currentEncoding == null) return [];

    final allImages = _imageProvider.allImages;
    final scoredImages = <MapEntry<String, int>>[];

    for (final image in allImages) {
      if (image.assetPath == currentImagePath) continue;

      int score = _calculateEncodingSimilarity(currentEncoding, image);
      
      if (score >= 30) {
        scoredImages.add(MapEntry(image.assetPath, score));
      }
    }

    scoredImages.sort((a, b) => b.value.compareTo(a.value));
    return scoredImages.take(limit).map((e) => e.key).toList();
  }

  /// 获取今日推荐（混合策略）
  Future<List<String>> getDailyRecommendations({int limit = 8}) async {
    await initialize();

    final personalized = await getPersonalizedRecommendations(limit: limit ~/ 2);
    final allImages = _imageProvider.allImages;

    // 添加一些随机热门
    final random = Random();
    final randomPicks = <String>[];
    
    final availableImages = allImages
        .where((img) => !personalized.any((p) => p.imagePath == img.assetPath))
        .toList();

    for (int i = 0; i < (limit - personalized.length) && availableImages.isNotEmpty; i++) {
      final index = random.nextInt(availableImages.length);
      randomPicks.add(availableImages[index].assetPath);
      availableImages.removeAt(index);
    }

    return [
      ...personalized.map((p) => p.imagePath),
      ...randomPicks,
    ];
  }

  /// 计算与浏览历史的相似度分数
  int _calculateSimilarityScore(EncodedImage image, List<String> recentPaths) {
    int score = 0;
    int matchCount = 0;

    for (final path in recentPaths.take(5)) {
      final recentEncoding = _imageProvider.getImageEncoding(path);
      if (recentEncoding == null) continue;

      final similarity = _calculateEncodingSimilarity(recentEncoding, image);
      if (similarity > 40) {
        score += similarity ~/ 3;
        matchCount++;
      }
    }

    // 如果与多个历史记录相似，增加额外分数
    if (matchCount >= 3) score += 15;
    if (matchCount >= 5) score += 10;

    return score;
  }

  /// 计算两个编码的相似度
  int _calculateEncodingSimilarity(EncodedImage a, EncodedImage b) {
    const weights = {
      'style': 25,
      'clothing': 20,
      'pose': 15,
      'angle': 10,
      'emotion': 10,
      'scene': 8,
      'hair': 7,
      'action': 5,
    };

    int score = 0;
    for (final entry in weights.entries) {
      final key = entry.key;
      final weight = entry.value;

      final valueA = a.encoding[key]?.name;
      final valueB = b.encoding[key]?.name;

      if (valueA != null && valueA == valueB) {
        score += weight;
      }
    }

    return score;
  }

  /// 从编码中提取分类
  String _extractCategoryFromEncoding(EncodedImage image) {
    final style = image.encoding['style']?.name ?? '';
    final clothing = image.encoding['clothing']?.name ?? '';
    
    if (style.isNotEmpty && clothing.isNotEmpty) {
      return '${style}_$clothing';
    }
    return style.isNotEmpty ? style : clothing;
  }
}

/// 推荐的姿势
class RecommendedPose {
  final String imagePath;
  final int score;
  final String reason;
  final EncodedImage encoding;

  RecommendedPose({
    required this.imagePath,
    required this.score,
    required this.reason,
    required this.encoding,
  });
}
