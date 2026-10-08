import 'package:fv_core/fv_core.dart';
import 'package:jaspr/jaspr.dart';

// `@client` components only accept primitive or codec-backed parameters.
// These extension types register codecs for fv_core models, so islands can
// take an `IndexFile` (etc.) parameter directly without fv_core depending on
// Jaspr. Jaspr's builder discovers them; nothing needs to import this file.

extension type IndexData(IndexFile file) implements IndexFile {
  @decoder
  static IndexData decode(Map<String, Object?> json) => IndexData(IndexFile.fromJson(json));

  @encoder
  Map<String, Object?> encode() => file.toJson();
}

extension type DetailData(ProjectDetail detail) implements ProjectDetail {
  @decoder
  static DetailData decode(Map<String, Object?> json) => DetailData(ProjectDetail.fromJson(json));

  @encoder
  Map<String, Object?> encode() => detail.toJson();
}

extension type RoadmapData(RoadmapFile file) implements RoadmapFile {
  @decoder
  static RoadmapData decode(Map<String, Object?> json) => RoadmapData(RoadmapFile.fromJson(json));

  @encoder
  Map<String, Object?> encode() => file.toJson();
}
