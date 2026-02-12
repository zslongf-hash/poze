// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pose_tags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PoseTags _$PoseTagsFromJson(Map<String, dynamic> json) => PoseTags(
  poseMain: json['pose_main'] as String,
  poseDetail: json['pose_detail'] as String,
  angle: json['angle'] as String,
  expression: json['expression'] as String,
  composition: json['composition'] as String,
  scene: json['scene'] as String,
  fullBody: json['full_body'] as bool,
  facingCamera: json['facing_camera'] as bool,
  movement: json['movement'] as String,
);

Map<String, dynamic> _$PoseTagsToJson(PoseTags instance) => <String, dynamic>{
  'pose_main': instance.poseMain,
  'pose_detail': instance.poseDetail,
  'angle': instance.angle,
  'expression': instance.expression,
  'composition': instance.composition,
  'scene': instance.scene,
  'full_body': instance.fullBody,
  'facing_camera': instance.facingCamera,
  'movement': instance.movement,
};
