import 'package:flutter/material.dart';
import '../../data/managers/asset_image_provider.dart';

/// 图片预加载管理器
/// 用于提前加载图片，提升滑动切换的流畅度
class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  factory ImagePreloader() => _instance;
  ImagePreloader._internal();

  final AssetImageProvider _imageProvider = AssetImageProvider();
  
  // 预加载队列
  final Set<String> _preloadingUrls = {};
  
  // 缓存的图片尺寸配置
  static const int _thumbnailSize = 200;
  static const int _fullImageWidth = 1200;
  static const int _fullImageHeight = 1600;

  /// 预加载单张图片（缩略图尺寸）
  Future<void> preloadThumbnail(BuildContext context, String imagePath) async {
    if (_preloadingUrls.contains(imagePath)) return;

    _preloadingUrls.add(imagePath);

    try {
      final imageProvider = AssetImage(imagePath);
      await precacheImage(
        imageProvider,
        context,
        size: Size(_thumbnailSize.toDouble(), _thumbnailSize * 1.3),
      );
    } catch (e) {
      // 预加载失败不处理
    } finally {
      _preloadingUrls.remove(imagePath);
    }
  }

  /// 预加载单张图片（全尺寸）
  Future<void> preloadFullImage(BuildContext context, String imagePath) async {
    if (_preloadingUrls.contains(imagePath)) return;

    _preloadingUrls.add(imagePath);

    try {
      final imageProvider = AssetImage(imagePath);
      await precacheImage(
        imageProvider,
        context,
        size: Size(_fullImageWidth.toDouble(), _fullImageHeight.toDouble()),
      );
    } catch (e) {
      // 预加载失败不处理
    } finally {
      _preloadingUrls.remove(imagePath);
    }
  }

  /// 预加载相邻图片（用于详情页滑动）
  Future<void> preloadAdjacentImages(
    BuildContext context,
    List<String> imageList,
    int currentIndex, {
    int preloadCount = 2,
  }) async {
    if (imageList.isEmpty) return;

    // 预加载前后的图片
    for (int i = 1; i <= preloadCount; i++) {
      // 后一张
      final nextIndex = (currentIndex + i) % imageList.length;
      if (nextIndex != currentIndex) {
        preloadFullImage(context, imageList[nextIndex]);
      }
      
      // 前一张
      final prevIndex = (currentIndex - i + imageList.length) % imageList.length;
      if (prevIndex != currentIndex && prevIndex != nextIndex) {
        preloadFullImage(context, imageList[prevIndex]);
      }
    }
  }

  /// 预加载列表中的多张图片（用于网格页面）
  Future<void> preloadImageList(
    BuildContext context,
    List<String> imagePaths, {
    int maxConcurrent = 3,
  }) async {
    final futures = <Future>[];
    
    for (int i = 0; i < imagePaths.length && i < maxConcurrent * 2; i++) {
      futures.add(preloadThumbnail(context, imagePaths[i]));
      
      // 控制并发数
      if (futures.length >= maxConcurrent) {
        await Future.wait(futures);
        futures.clear();
      }
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// 清除预加载缓存
  void clearPreloadCache() {
    _preloadingUrls.clear();
  }
}
