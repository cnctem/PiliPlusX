class MsgLikeContent {
  String? business;
  String? title;
  String? image;
  String? nativeUri;

  MsgLikeContent({
    this.business,
    this.title,
    this.image,
    this.nativeUri,
  });

  factory MsgLikeContent.fromJson(Map<String, dynamic> json) {
    return MsgLikeContent(
      business: json['business'] as String?,
      title: json['title'] as String?,
      image: json['image'] as String?,
      nativeUri: json['native_uri'] as String?,
    );
  }
}
