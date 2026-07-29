class MsgAtContent {
  String? business;
  String? image;
  String? sourceContent;
  String? nativeUri;

  MsgAtContent({
    this.business,
    this.image,
    this.sourceContent,
    this.nativeUri,
  });

  factory MsgAtContent.fromJson(Map<String, dynamic> json) => MsgAtContent(
    business: json['business'] as String?,
    image: json['image'] as String?,
    sourceContent: json['source_content'] as String?,
    nativeUri: json['native_uri'] as String?,
  );
}
