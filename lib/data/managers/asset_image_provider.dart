import 'dart:convert';
import 'package:flutter/services.dart';

/// 12位编码图片数据模型
class EncodedImage {
  final String assetPath;
  final String filename;
  final String sequence;
  final String fullCode;
  final Map<String, EncodingItem> encoding;

  EncodedImage({
    required this.assetPath,
    required this.filename,
    required this.sequence,
    required this.fullCode,
    required this.encoding,
  });

  factory EncodedImage.fromJson(Map<String, dynamic> json) {
    final encoding = <String, EncodingItem>{};
    final encodingData = json['encoding'] as Map<String, dynamic>;
    
    for (final key in encodingData.keys) {
      final item = encodingData[key] as Map<String, dynamic>;
      encoding[key] = EncodingItem(
        code: item['code'] as String,
        name: item['name'] as String,
      );
    }

    return EncodedImage(
      assetPath: json['asset_path'] as String,
      filename: json['filename'] as String,
      sequence: json['sequence'] as String,
      fullCode: json['full_code'] as String,
      encoding: encoding,
    );
  }

  /// 获取特定位的编码
  String? getEncodingValue(String position) {
    return encoding[position]?.name;
  }

  /// 获取特定位的编码代码
  String? getEncodingCode(String position) {
    return encoding[position]?.code;
  }
}

class EncodingItem {
  final String code;
  final String name;

  EncodingItem({required this.code, required this.name});
}

class AssetImageProvider {
  static final AssetImageProvider _instance = AssetImageProvider._internal();
  factory AssetImageProvider() => _instance;
  AssetImageProvider._internal();

  List<EncodedImage> _allImages = [];
  List<String> _allImagePaths = [];
  bool _initialized = false;

  // 12位编码索引
  Map<String, Map<String, List<String>>> _encodingIndex = {};
  
  // 编码定义
  Map<String, Map<String, String>> _encodingDefinitions = {};

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final manifestString = await rootBundle.loadString('assets/images/asset_manifest.json');
      _parseManifest(manifestString);
      _initialized = true;
      print('=== AssetImageProvider ===');
      print('已加载 ${_allImages.length} 张图片');
      print('12位编码索引已构建');
      print('=======================');
    } catch (e) {
      print('加载manifest失败: $e');
      _initialized = true;
    }
  }

  void _parseManifest(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final List<dynamic> images = json['files'] ?? [];
      
      // 加载编码定义
      _encodingDefinitions = (json['encoding_definitions'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String)
        ))
      ) ?? {};

      for (var img in images) {
        try {
          final encodedImage = EncodedImage.fromJson(img);
          _allImages.add(encodedImage);
          _allImagePaths.add(encodedImage.assetPath);
          _buildEncodingIndex(encodedImage);
        } catch (e) {
          print('解析图片数据失败: $e');
        }
      }
    } catch (e) {
      print('解析manifest失败: $e');
    }
  }

  /// 构建12位编码索引
  void _buildEncodingIndex(EncodedImage image) {
    for (final position in image.encoding.keys) {
      final code = image.encoding[position]!.code;
      final name = image.encoding[position]!.name;
      
      _encodingIndex.putIfAbsent(position, () => {});
      _encodingIndex[position]!.putIfAbsent(code, () => []).add(image.assetPath);
      _encodingIndex[position]!.putIfAbsent(name, () => []).add(image.assetPath);
    }
  }

  /// 根据12位编码筛选图片
  /// 
  /// 参数说明（每个参数对应12位编码的一位）：
  /// - shotSize: 景别 (a-f)
  /// - composition: 构图 (a-h)
  /// - angle: 拍摄角度 (a-j)
  /// - pose: 人物姿态 (a-e)
  /// - action: 动作类型 (a-n)
  /// - emotion: 情绪 (a-n)
  /// - clothing: 服装类型 (a-l)
  /// - hair: 发型 (a-h)
  /// - color: 服装颜色 (a-n)
  /// - season: 季节 (a-e)
  /// - scene: 场景 (a-l)
  /// - style: 风格 (a-p)
  List<String> getImagesByEncoding({
    String? shotSize,
    String? composition,
    String? angle,
    String? pose,
    String? action,
    String? emotion,
    String? clothing,
    String? hair,
    String? color,
    String? season,
    String? scene,
    String? style,
    int limit = 50,
  }) {
    List<String> result = [];
    bool hasFilter = false;

    // 定义筛选条件
    final filters = {
      'shot_size': shotSize,
      'composition': composition,
      'angle': angle,
      'pose': pose,
      'action': action,
      'emotion': emotion,
      'clothing': clothing,
      'hair': hair,
      'color': color,
      'season': season,
      'scene': scene,
      'style': style,
    };

    // 遍历所有筛选条件
    for (final entry in filters.entries) {
      final position = entry.key;
      final value = entry.value;
      
      if (value != null && value.isNotEmpty) {
        hasFilter = true;
        final matches = _encodingIndex[position]?[value] ?? [];
        
        if (result.isEmpty) {
          result = matches.toList();
        } else {
          result = result.where((path) => matches.contains(path)).toList();
        }
        
        // 如果结果为空，提前返回
        if (result.isEmpty) return [];
      }
    }

    // 如果没有筛选条件，返回所有图片
    if (!hasFilter) {
      return _allImagePaths.take(limit).toList();
    }

    return result.take(limit).toList();
  }

  /// 获取所有可用的编码选项
  Map<String, List<String>> getAllEncodingOptions() {
    final result = <String, List<String>>{};
    
    for (final position in _encodingDefinitions.keys) {
      result[position] = _encodingDefinitions[position]!.values.toList()..sort();
    }
    
    return result;
  }

  /// 获取特定位的所有选项
  List<String> getEncodingOptions(String position) {
    return _encodingDefinitions[position]?.values.toList() ?? [];
  }

  /// 获取图片的编码信息
  EncodedImage? getImageEncoding(String assetPath) {
    try {
      return _allImages.firstWhere((img) => img.assetPath == assetPath);
    } catch (e) {
      return null;
    }
  }

  /// 获取编码定义
  Map<String, String>? getEncodingDefinitions(String position) {
    return _encodingDefinitions[position];
  }

  /// 获取所有图片路径
  List<String> getAllImages({int limit = 20}) {
    return _allImagePaths.take(limit).toList();
  }

  /// 根据单个编码位筛选图片（简化版）
  List<String> getImagesBySingleEncoding(String position, String value, {int limit = 20}) {
    final matches = _encodingIndex[position]?[value] ?? [];
    return matches.take(limit).toList();
  }

  /// 获取编码统计信息
  Map<String, Map<String, int>> getEncodingStatistics() {
    final stats = <String, Map<String, int>>{};
    
    for (final position in _encodingIndex.keys) {
      stats[position] = {};
      for (final code in _encodingIndex[position]!.keys) {
        stats[position]![code] = _encodingIndex[position]![code]!.length;
      }
    }
    
    return stats;
  }

  int get totalCount => _allImages.length;

  bool get isInitialized => _initialized;

  List<EncodedImage> get allImages => _allImages;

  /// 获取已加载的编码图片数量
  int get encodedImageCount => _allImages.length;
}
