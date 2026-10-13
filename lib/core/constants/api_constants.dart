class ApiConstants {
  // Default URL Google Apps Script Web App (Dapat diganti via Layar Pengaturan)
  static const String defaultBaseUrl =
      'https://script.google.com/macros/s/AKfycbx_SAMPLE_DEPLOYMENT_URL_G_SHEET/exec';

  // Timeout dalam milidetik (Google Apps Script terkadang butuh 5-15 detik saat cold start)
  static const Duration timeoutDuration = Duration(seconds: 25);

  // Storage Keys
  static const String keyApiUrl = 'custom_gas_api_url';
  static const String keyUserSession = 'user_session_data';
  static const String keyDemoMode = 'demo_mode_enabled';
}
