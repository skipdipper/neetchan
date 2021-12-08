import 'dart:math';

String getDateTimeSince(int time) {
  DateTime input = DateTime.fromMillisecondsSinceEpoch(time * 1000);
  Duration diff = DateTime.now().difference(input);

  if (diff.inDays > 1) {
    return '${diff.inDays} days ago';
  } else if (diff.inDays == 1) {
    return '${diff.inDays} day ago';
  } else if (diff.inHours > 1) {
    return '${diff.inHours} hrs ago';
  } else if (diff.inHours == 1) {
    return '${diff.inHours} hr ago';
  } else if (diff.inMinutes > 1) {
    return '${diff.inMinutes} mins ago';
  } else if (diff.inMinutes == 1) {
    return '${diff.inMinutes} min ago';
  } else if (diff.inSeconds > 1) {
    return '${diff.inSeconds} secs ago';
  } else if (diff.inSeconds == 1) {
    return '${diff.inSeconds} sec ago';
  } else {
    return 'just now';
  }
}

String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
}
