// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pose_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PoseTag _$PoseTagFromJson(Map<String, dynamic> json) => PoseTag(
  style: json['style'] as String,
  poseType: json['poseType'] as String,
  shotSize: json['shotSize'] as String?,
  angle: json['angle'] as String,
  expression: json['expression'] as String,
  costume: json['costume'] as String,
  prop: json['prop'] as String,
  scene: json['scene'] as String,
  difficulty: json['difficulty'] as String?,
  gender: json['gender'] as String,
  styleSet: json['styleSet'] as String,
  styleTheme: json['styleTheme'] as String,
  styleColor: json['styleColor'] as String,
  styleMood: json['styleMood'] as String,
);

Map<String, dynamic> _$PoseTagToJson(PoseTag instance) => <String, dynamic>{
  'style': instance.style,
  'poseType': instance.poseType,
  'shotSize': instance.shotSize,
  'angle': instance.angle,
  'expression': instance.expression,
  'costume': instance.costume,
  'prop': instance.prop,
  'scene': instance.scene,
  'difficulty': instance.difficulty,
  'gender': instance.gender,
  'styleSet': instance.styleSet,
  'styleTheme': instance.styleTheme,
  'styleColor': instance.styleColor,
  'styleMood': instance.styleMood,
};
