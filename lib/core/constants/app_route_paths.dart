class AppRoutePaths {
  static const String login = '/login';
  static const String home = '/home';
  static const String resetPassword = '/reset-password';
}

class AppDeepLinkPaths {
  static const String scheme = 'agrovetai';
  static const String authConfirmHost = 'auth-confirm';
  static const String resetPasswordHost = 'reset-password';

  static const String authConfirm = '$scheme://$authConfirmHost';
  static const String resetPassword = '$scheme://$resetPasswordHost';
}
