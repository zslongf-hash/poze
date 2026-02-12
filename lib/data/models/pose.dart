import 'package:json_annotation/json_annotation.dart';
import 'pose_tag.dart';

part 'pose.g.dart';

@JsonSerializable()
class Pose {
  final String id;
  final String filename;
  final String sourcePath;
  final PoseTag tags;
  final String? thumbnailPath;
  final String? setThumbnailPath;

  Pose({
    required this.id,
    required this.filename,
    required this.sourcePath,
    required this.tags,
    this.thumbnailPath,
    this.setThumbnailPath,
  });

  factory Pose.fromJson(Map<String, dynamic> json) =>
      _$PoseFromJson(json);

  Map<String, dynamic> toJson() => _$PoseToJson(this);
}
