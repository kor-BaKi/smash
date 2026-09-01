class ActivityPhotoInfo {
  final int id;
  final String url;
  final String uploadedBy;
  final String createdAt;

  ActivityPhotoInfo({
    required this.id,
    required this.url,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory ActivityPhotoInfo.fromJson(Map<String, dynamic> json) {
    return ActivityPhotoInfo(
      id: json['id'],
      url: json['url'],
      uploadedBy: json['uploadedBy'],
      createdAt: json['createdAt'],
    );
  }
}
