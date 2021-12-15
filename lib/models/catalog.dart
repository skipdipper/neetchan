class Catalog {
  final int no;
  final int resto;
  final int time;
  final String? name; // boards like /c often omit this in favour of trip
  final String? trip;
  final String? sub;
  final String? com;
  final String? filename;
  final String? ext;
  final int? filesize;
  final int? tim;
  final int replies;
  final int? images;
  final int? lastModified;
  late String? board;
  late int? accessedOn;

  Catalog({
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
    required this.tim,
    required this.replies,
    this.images,
    this.lastModified,
    // additional meta data: this is required
    required this.board,
    this.accessedOn,
  });

  // Saving Bookmark when open link from another thread
  Catalog.temp({
    required this.no,
    required this.resto,
    this.time = 0,
    this.name,
    this.trip,
    this.sub,
    this.com,
    this.filename,
    this.ext,
    this.filesize,
    this.tim,
    this.replies = 0,
    this.images,
    this.lastModified,
    required this.board,
    this.accessedOn,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      no: json['no'],
      resto: json['resto'],
      time: json['time'],
      name: json['name'],
      trip: json['trip'],
      sub: json['sub'],
      com: json['com'],
      filename: json['filename'],
      ext: json['ext'],
      filesize: json['fsize'],
      tim: json['tim'] ?? 0,
      replies: json['replies'] ?? 0,
      images: json['images'],
      lastModified: json['last_modified'],
      // only used for logging, initially null before manually adding
      board: json['board'],
      accessedOn: json['accessedOn'],
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
      "tim": tim,
      "replies": replies,
      "images": images,
      "last_modified": lastModified,
      "board": board,
      "accessedOn": accessedOn,
    }..removeWhere((key, value) => value == null);
  }
}
