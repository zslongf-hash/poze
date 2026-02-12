class AppConstants {
  static const String appName = '拍照姿势参考助手';
  static const String appVersion = '1.0.0';

  static const String databaseName = 'pose_reference.db';
  static const int databaseVersion = 1;

  static const String posesDatabasePath = 'assets/data/poses_database.json';
  static const String searchIndexPath = 'assets/data/search_index.json';

  static const String imagesPath = 'assets/images';

  static const int pageSize = 20;
  static const int maxCacheSize = 100;

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  static const String sharedPrefKeyTheme = 'theme_mode';
  static const String sharedPrefKeyFirstLaunch = 'first_launch';
}

class RouteConstants {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String browse = '/browse';
  static const String search = '/search';
  static const String detail = '/detail';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String stats = '/stats';
}

class TagConstants {
  static const List<String> styles = ['现代清新', '古风汉服'];

  static const List<String> poseTypes = [
    '站姿', '坐姿', '蹲姿', '卧姿', '动态', '互动'
  ];

  static const Map<String, List<String>> poseSubtypes = {
    '站姿': ['正面站', '侧面站', '背面站', '倚靠站', '单腿站', '交叉站', 'S型站'],
    '坐姿': ['正坐', '侧坐', '盘腿坐', '跪坐', '倚坐', '抱膝坐', '跷腿坐'],
    '蹲姿': ['正蹲', '侧蹲', '单膝跪', '双膝跪', '半蹲'],
    '卧姿': ['仰卧', '侧卧', '俯卧', '半躺', '倚躺'],
    '动态': ['行走', '旋转', '跳跃', '回眸', '甩发', '撩发'],
    '互动': ['与道具互动', '与环境互动', '手部动作', '抚脸', '托腮'],
  };

  static const List<String> shotSizes = [
    '特写', '近景', '中景', '全景', '远景', '大远景'
  ];

  static const List<String> angles = [
    '平视', '俯拍', '仰拍', '侧拍', '45度角', '正脸', '侧脸', '背影'
  ];

  static const List<String> expressions = [
    '微笑', '大笑', '冷艳', '甜美', '自然', '忧郁', '俏皮', '妩媚', '清纯', '酷飒'
  ];

  static const Map<String, List<String>> costumes = {
    '现代': ['连衣裙', 'T恤牛仔', '衬衫', '短裙', '长裙', '休闲装', '森系', '日系', '韩系'],
    '古风': ['齐胸襦裙', '齐腰襦裙', '宋制', '明制', '魏晋风', '唐装', '汉服混搭'],
  };

  static const List<String> props = [
    '无', '扇子', '油纸伞', '花束', '书本', '乐器', '茶具', '灯笼', '剑', '披帛', '面纱', '发簪'
  ];

  static const Map<String, List<String>> scenes = {
    '现代': ['街道', '咖啡厅', '书店', '花店', '公园', '海边', '草地', '树林', '建筑', '室内'],
    '古风': ['古建筑', '园林', '亭台', '竹林', '花间', '水边', '庭院', '室内古风'],
  };

  static const List<String> difficulties = [
    '入门', '简单', '中等', '较难', '专业'
  ];

  static const Map<String, Map<String, String>> styleSets = {
    '清新街拍系列1': {'theme': '都市清新', 'color': '明亮', 'mood': '活泼'},
    '清新街拍系列2': {'theme': '都市清新', 'color': '明亮', 'mood': '自然'},
    '清新街拍系列3': {'theme': '都市清新', 'color': '柔和', 'mood': '温柔'},
    '清新街拍系列4': {'theme': '都市清新', 'color': '清新', 'mood': '甜美'},
    '清新街拍系列5': {'theme': '都市清新', 'color': '淡雅', 'mood': '文艺'},
    '古风汉服系列': {'theme': '古典雅致', 'color': '古韵', 'mood': '优雅'},
  };
}
