class DateTimeHelper {
  /// Extracts the year from a release date string (e.g., "2024-05-02" → "2024")
  static String getYear(String? releaseDate) {
    if (releaseDate == null || releaseDate.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(releaseDate);
      return date.year.toString();
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Formats a release date string to a more readable format like "May 2, 2024"
  static String formatFullDate(String? releaseDate) {
    if (releaseDate == null || releaseDate.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(releaseDate);
      return '${_monthName(date.month)} ${date.day}, ${date.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Converts numeric month to name
  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : 'Unknown';
  }
}
