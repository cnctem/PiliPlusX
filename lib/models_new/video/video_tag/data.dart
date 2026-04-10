class VideoTagItem {
  int? tagId;
  String? tagName;
  String? tagType;
  String? musicId;

  VideoTagItem({
    this.tagId,
    this.tagName,
    this.tagType,
    this.musicId,
  });

  factory VideoTagItem.fromJson(Map<String, dynamic> json) => VideoTagItem(
    tagId: json["tag_id"],
    tagName: json["tag_name"],
    tagType: json["tag_type"],
    musicId: json["music_id"],
  );
}
