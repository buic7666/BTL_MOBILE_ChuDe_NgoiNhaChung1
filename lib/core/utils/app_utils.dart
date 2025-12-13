class AppUtils {
  /// Format tiền tệ (VND)
  static String formatCurrency(double amount) {
    return '₫${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';
  }

  /// Format ngày tháng
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    if (format == 'dd/MM/yyyy') {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return date.toString().split(' ')[0];
  }

  /// Format thời gian
  static String formatTime(DateTime dateTime, {String format = 'HH:mm'}) {
    if (format == 'HH:mm') {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return dateTime.toString().substring(11, 16);
  }

  /// Format ngày giờ đầy đủ
  static String formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  /// Tính khoảng thời gian từ bây giờ
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d trước';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Kiểm tra email hợp lệ
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Kiểm tra mật khẩu hợp lệ (tối thiểu 6 ký tự)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Tạo mã invite ngẫu nhiên
  static String generateInviteCode({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = <String>[];
    for (var i = 0; i < length; i++) {
      random.add(chars[(random.length) % chars.length]);
    }
    return random.join();
  }

  /// Tạo mã OTP (One-Time Password) 6 chữ số
  static String generateOTP({int length = 6}) {
    const chars = '0123456789';
    final random = <String>[];
    for (var i = 0; i < length; i++) {
      random.add(chars[(DateTime.now().microsecond + i) % chars.length]);
    }
    return random.join();
  }
}
