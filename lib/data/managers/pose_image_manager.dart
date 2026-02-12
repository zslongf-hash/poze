import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PoseImageManager {
  static final PoseImageManager _instance = PoseImageManager._internal();
  factory PoseImageManager() => _instance;
  PoseImageManager._internal();

  List<String> _sampleImages = [];
  Map<String, List<String>> _categoryImages = {};

  Future<void> initialize() async {
    // 直接使用 assets 中的照片，这是最可靠的方式
    await _scanSampleAssets();
  }

  Future<void> _scanAllSubclustersAssets() async {
    try {
      // 根据平台选择不同的路径
      String allSubclustersPath;
      
      // 检查是否在桌面平台
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // 桌面平台使用固定路径
        allSubclustersPath = '/Users/jason/Documents/TRAE-app/post/post/res/assert/all_subclusters';
      } else {
        // 移动平台使用应用文档目录
        final directory = await getApplicationDocumentsDirectory();
        allSubclustersPath = '${directory.path}/all_subclusters';
      }
      
      final allSubclustersDir = Directory(allSubclustersPath);
      
      if (allSubclustersDir.existsSync()) {
        // 扫描所有子目录
        await _scanDirectory(allSubclustersDir, '');
        
        print('已加载 ${_sampleImages.length} 张样本图片');
        print('分类数量: ${_categoryImages.length}');
        print('分类: ${_categoryImages.keys}');
      } else {
        print('all_subclusters 文件夹不存在: $allSubclustersPath');
        // 在移动平台上，如果 all_subclusters 不存在，尝试使用 assets 中的照片
        if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
          await _scanSampleAssets();
        } else {
          _fallbackScanAssets();
        }
      }
    } catch (e) {
      print('加载样本清单失败: $e');
      _fallbackScanAssets();
    }
  }

  Future<void> _scanSampleAssets() async {
    try {
      final manifestString = await rootBundle.loadString('assets/images/asset_manifest.json');
      final manifest = _parseManifest(manifestString);
      
      for (var file in manifest['files'] as List) {
        final assetPath = file['asset_path'] as String;
        _sampleImages.add(assetPath);
        
        final category = file['category'] as String;
        _categoryImages.putIfAbsent(category, () => []).add(assetPath);
      }
      
      print('已加载 $_sampleImages 张样本图片');
      print('分类: $_categoryImages');
    } catch (e) {
      print('加载样本清单失败: $e');
      _fallbackScanAssets();
    }
  }
  
  Map<String, dynamic> _parseManifest(String jsonString) {
    final List<Map<String, String>> files = [];
    
    int startIndex = 0;
    while (startIndex < jsonString.length) {
      final assetMatch = RegExp(r'"asset_path":\s*"([^"]+)"').firstMatch(jsonString.substring(startIndex));
      final categoryMatch = RegExp(r'"category":\s*"([^"]+)"').firstMatch(jsonString.substring(startIndex));
      
      if (assetMatch == null) break;
      
      final assetPath = assetMatch.group(1)!;
      final category = categoryMatch?.group(1) ?? 'unknown';
      
      files.add({
        'asset_path': assetPath,
        'category': category,
      });
      
      startIndex += assetMatch.start + assetMatch.group(0)!.length;
    }
    
    return {
      'files': files,
      'total': files.length,
    };
  }

  Future<void> _scanDirectory(Directory directory, String parentCategory) async {
    final entities = directory.listSync();
    
    for (final entity in entities) {
      if (entity is Directory) {
        // 构建分类名称
        final dirName = entity.path.split('/').last;
        final category = parentCategory.isEmpty ? dirName : '$parentCategory/$dirName';
        
        // 递归扫描子目录
        await _scanDirectory(entity, category);
      } else if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
        // 构建文件路径
        final filePath = entity.path;
        
        // 提取分类名称
        final pathParts = filePath.split('/');
        final categoryIndex = pathParts.indexOf('all_subclusters');
        
        if (categoryIndex != -1 && pathParts.length > categoryIndex + 2) {
          // 分类路径: all_subclusters/category_subclusters/subcategory
          final categoryPart = pathParts[categoryIndex + 1].replaceAll('_subclusters', '');
          final subcategoryPart = pathParts[categoryIndex + 2];
          final category = '$categoryPart/$subcategoryPart';
          
          // 添加到列表
          _sampleImages.add(filePath);
          _categoryImages.putIfAbsent(category, () => []).add(filePath);
        }
      }
    }
  }

  void _fallbackScanAssets() {
    // 保留原有的 fallback 逻辑，以便在 all_subclusters 文件夹不存在时使用
    final categories = [
      '现代清新_站姿',
      '现代清新_坐姿',
      '现代清新_动态', 
      '现代清新_互动',
      '古风汉服_站姿',
      '古风汉服_坐姿',
      '古风汉服_动态',
      '古风汉服_互动',
    ];
    
    for (var category in categories) {
      for (int i = 1; i <= 10; i++) {
        final prefix = category.contains('现代清新') 
            ? category.replaceAll('现代清新_', 'modern_')
            : category.replaceAll('古风汉服_', 'ancient_');
        final assetPath = 'assets/images/pose_samples/${prefix}_$i.jpg';
        _sampleImages.add(assetPath);
        _categoryImages.putIfAbsent(category, () => []).add(assetPath);
      }
    }
  }

  String getImagePath(String category, {bool preferInternal = true}) {
    if (_categoryImages.containsKey(category)) {
      final images = _categoryImages[category]!;
      if (images.isNotEmpty) {
        return images.first;
      }
    }
    
    if (_sampleImages.isNotEmpty) {
      return _sampleImages.first;
    }
    
    return '';
  }

  List<String> getImagesByCategory(String category, {int limit = 20}) {
    if (_categoryImages.containsKey(category)) {
      return _categoryImages[category]!.take(limit).toList();
    }
    
    return _sampleImages.take(limit).toList();
  }

  List<String> get allSampleImages => _sampleImages;
  Map<String, List<String>> get categoryImages => _categoryImages;
}
