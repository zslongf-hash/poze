// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pose.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pose _$PoseFromJson(Map<String, dynamic> json) => Pose(
  id: json['id'] as String,
  filename: json['filename'] as String,
  sourcePath: json['sourcePath'] as String,
  tags: PoseTag.fromJson(json['tags'] as Map<String, dynamic>),
  thumbnailPath: json['thumbnailPath'] as String?,
  setThumbnailPath: json['setThumbnailPath'] as String?,
);

Map<String, dynamic> _$PoseToJson(Pose instance) => <String, dynamic>{
  'id': instance.id,
  'filename': instance.filename,
  'sourcePath': instance.sourcePath,
  'tags': instance.tags,
  'thumbnailPath': instance.thumbnailPath,
  'setThumbnailPath': instance.setThumbnailPath,
};
