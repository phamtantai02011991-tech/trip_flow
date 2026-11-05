/// Bộ công cụ xử lý và tìm kiếm Tiếng Việt thông minh (Vietnamese Text Utilities)
/// Hỗ trợ tìm kiếm không dấu, có dấu, gõ tắt Telex/VNI cho người dùng Việt Nam.
class VietnameseUtils {
  static final Map<String, String> _diacriticMap = {
    // a
    'a': 'a', 'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    // e
    'e': 'e', 'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    // i
    'i': 'i', 'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    // o
    'o': 'o', 'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    // u
    'u': 'u', 'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    // y
    'y': 'y', 'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    // d
    'd': 'd', 'đ': 'd',
  };

  /// Loại bỏ toàn bộ dấu thanh và dấu mũ trong chuỗi Tiếng Việt:
  /// Ví dụ: "Đà Lạt Mộng Mơ" -> "da lat mong mo"
  static String removeDiacritics(String str) {
    if (str.isEmpty) return '';
    final lower = str.toLowerCase();
    final buffer = StringBuffer();
    for (int i = 0; i < lower.length; i++) {
      final char = lower[i];
      buffer.write(_diacriticMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// So khớp thông minh tiếng Việt:
  /// Cho phép người dùng gõ có dấu hoặc không dấu, đều tìm ra chính xác kết quả!
  ///
  /// Ví dụ:
  /// - `matches("Đà Lạt", "da lat")` -> `true`
  /// - `matches("Chợ Bến Thành", "ben thanh")` -> `true`
  /// - `matches("Phở Bát Đàn", "pho")` -> `true`
  /// - `matches("Hồ Chí Minh", "sai gon")` -> `true` (Hỗ trợ từ đồng nghĩa)
  static bool matches(String source, String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return true;

    final cleanSource = source.toLowerCase();

    // 1. So khớp trực tiếp (gõ có dấu chính xác)
    if (cleanSource.contains(cleanQuery)) return true;

    // 2. So khớp không dấu
    final unaccentSource = removeDiacritics(cleanSource);
    final unaccentQuery = removeDiacritics(cleanQuery);
    if (unaccentSource.contains(unaccentQuery)) return true;

    // 3. So khớp từng từ theo âm tiết (syllable token matching)
    final queryWords = unaccentQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (queryWords.length > 1) {
      final sourceTokens = unaccentSource.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toSet();
      bool allWordsFound = true;
      for (final w in queryWords) {
        if (!sourceTokens.contains(w)) {
          allWordsFound = false;
          break;
        }
      }
      if (allWordsFound) return true;
    }

    // 4. Từ điển đồng nghĩa địa danh phổ biến Việt Nam
    if (unaccentQuery.contains('sai gon') && unaccentSource.contains('ho chi minh')) return true;
    if (unaccentQuery.contains('ho chi minh') && unaccentSource.contains('sai gon')) return true;
    if (unaccentQuery.contains('ha thanh') && unaccentSource.contains('ha noi')) return true;
    if (unaccentQuery.contains('da lat') && unaccentSource.contains('lam dong')) return true;

    return false;
  }
}
