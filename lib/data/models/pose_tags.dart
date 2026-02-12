import 'package:json_annotation/json_annotation.dart';

part 'pose_tags.g.dart';

/// 拍摄姿势标签模型
@JsonSerializable()
class PoseTags {
  /// 主要姿势类型
  /// standing: 站姿
  /// sitting: 坐姿
  /// squatting: 蹲姿
  /// lying: 卧姿
  /// dynamic: 动态
  /// interaction: 互动
  @JsonKey(name: 'pose_main')
  final String poseMain;

  /// 具体姿势描述
  @JsonKey(name: 'pose_detail')
  final String poseDetail;

  /// 拍摄角度
  final String angle;

  /// 表情
  final String expression;

  /// 构图类型
  final String composition;

  /// 场景
  final String scene;

  /// 是否全身照
  @JsonKey(name: 'full_body')
  final bool fullBody;

  /// 是否面向镜头
  @JsonKey(name: 'facing_camera')
  final bool facingCamera;

  /// 动态程度
  /// 静态、微动、动态
  final String movement;

  PoseTags({
    required this.poseMain,
    required this.poseDetail,
    required this.angle,
    required this.expression,
    required this.composition,
    required this.scene,
    required this.fullBody,
    required this.facingCamera,
    required this.movement,
  });

  factory PoseTags.fromJson(Map<String, dynamic> json) =>
      _$PoseTagsFromJson(json);

  Map<String, dynamic> toJson() => _$PoseTagsToJson(this);

  /// 获取主要姿势类型的中文显示
  String get poseMainDisplay {
    final displayMap = {
      'standing': '站姿',
      'sitting': '坐姿',
      'squatting': '蹲姿',
      'lying': '卧姿',
      'dynamic': '动态',
      'interaction': '互动',
    };
    return displayMap[poseMain] ?? poseMain;
  }

  /// 获取所有标签列表
  List<String> get allTags {
    return [
      poseMainDisplay,
      poseDetail,
      angle,
      expression,
      composition,
      scene,
      movement,
      if (fullBody) '全身' else '半身',
      if (facingCamera) '正面' else '侧面/背面',
    ];
  }
}
