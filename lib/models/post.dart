class Post {
  final int no;
  final int resto;
  final int time;
  final String? name; // will be null if `trip` provided, either name or trip will be provided
  final String? trip;
  final String? sub;
  final String? com;
  final String? filename;
  final String? ext;
  final int? filesize;
  final int? tim;
  final int? width;
  final int? height;
  final int? tnWidth;
  final int? tnHeight;
  final int? replies;
  final int? images;

  Post({
    required this.no,
    required this.resto,
    required this.time,
    this.name,
    this.trip,
    this.sub,
    this.com,
    this.filename,
    this.ext,
    this.filesize,
    this.tim,
    this.width,
    this.height,
    this.tnWidth,
    this.tnHeight,
    this.replies,
    this.images,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      no: json['no'],
      resto: json['resto'],
      time: json['time'],
      name: json['name'],
      trip: json['trip'],
      sub: json['sub'],
      com: json['com'],
      filename: json['filename'],
      ext: json['ext'],
      tim: json['tim'],
      filesize: json['fsize'],
      width: json['w'],
      height: json['h'],
      tnWidth: json['tn_w'],
      tnHeight: json['tn_h'],
      replies: json['replies'],
      images: json['images'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "no": no,
      "resto": resto,
      "time": time,
      "name": name,
      "trip": trip,
      "sub": sub,
      "com": com,
      "filename": filename,
      "ext": ext,
      "fsize": filesize,
      "w": width,
      "h": height,
      "tn_w": tnWidth,
      "tn_h": tnHeight,
      "tim": tim,
      "replies": replies,
      "images": images,
    }..removeWhere((key, value) => value == null);
  }
}
