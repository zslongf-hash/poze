import 'package:json_annotation/json_annotation.dart';

part 'pose_tag.g.dart';

@JsonSerializable()
class PoseTag {
  final String style;
  final String poseType;
  final String? shotSize;
  final String angle;
  final String expression;
  final String costume;
  final String prop;
  final String scene;
  final String? difficulty;
  final String gender;
  final String styleSet;
  final String styleTheme;
  final String styleColor;
  final String styleMood;

  PoseTag({
    required this.style,
    required this.poseType,
    this.shotSize,
    required this.angle,
    required this.expression,
    required this.costume,
    required this.prop,
    required this.scene,
    this.difficulty,
    required this.gender,
    required this.styleSet,
    required this.styleTheme,
    required this.styleColor,
    required this.styleMood,
  });

  factory PoseTag.fromJson(Map<String, dynamic> json) =>
      _$PoseTagFromJson(json);

  Map<String, dynamic> toJson() => _$PoseTagToJson(this);
}
