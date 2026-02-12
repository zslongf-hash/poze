class PoseGuidance {
  final String title;
  final List<GuidanceSection> sections;
  final String cameraTip;
  final List<String> keywords;

  PoseGuidance({
    required this.title,
    required this.sections,
    required this.cameraTip,
    required this.keywords,
  });

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln('【$title】');
    buffer.writeln();
    for (final section in sections) {
      buffer.writeln('${section.icon} ${section.title}');
      buffer.writeln('${section.content}');
      buffer.writeln();
    }
    buffer.writeln('📷 $cameraTip');
    buffer.writeln();
    buffer.writeln('💡 关键词: ${keywords.join(' | ')}');
    return buffer.toString();
  }
}

class GuidanceSection {
  final String icon;
  final String title;
  final String content;

  GuidanceSection({
    required this.icon,
    required this.title,
    required this.content,
  });
}
