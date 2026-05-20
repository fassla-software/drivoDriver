class ImageHelper {
  static String? getImage(String? path) {
    if (path == null || path.isEmpty) return null;

    if (path.startsWith('http')) return path;

  return 'https://drivoeg.com/storage/app/public/customer/profile/$path';
  }
}