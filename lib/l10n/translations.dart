import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;

  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ??
        AppStrings(const Locale('en'));
  }

  String get languageCode => locale.languageCode;

  String _get(Map<String, String> map) {
    return map[locale.languageCode] ?? map['en'] ?? '';
  }

  // ─── Onboarding ───
  String get onboardingWelcome => _get({
        'en': 'Welcome to\n\u03A9MMON',
        'id': 'Selamat Datang di\n\u03A9MMON',
        'ms': 'Selamat Datang ke\n\u03A9MMON'
      });

  String get onboardingSubtitle => _get({
        'en': 'Open Mikrotik Monitor',
        'id': 'Open Mikrotik Monitor',
        'ms': 'Open Mikrotik Monitor',
      });

  String get onboardingDescription => _get({
        'en':
            'Monitor and manage your MikroTik hotspot from your phone. Generate vouchers, track users, and view real-time statistics.',
        'id':
            'Pantau dan kelola hotspot MikroTik dari ponsel Anda. Buat voucher, lacak pengguna, dan lihat statistik real-time.',
        'ms':
            'Pantau dan urus hotspot MikroTik dari telefon anda. Buat voucher, jejak pengguna, dan lihat statistik masa nyata.',
      });

  String get skip => _get({'en': 'Skip', 'id': 'Lewati', 'ms': 'Langkau'});
  String get next => _get({'en': 'Next', 'id': 'Lanjut', 'ms': 'Seterusnya'});
  String get back => _get({'en': 'Back', 'id': 'Kembali', 'ms': 'Kembali'});
  String get continue_ =>
      _get({'en': 'Continue', 'id': 'Lanjutkan', 'ms': 'Teruskan'});

  // ─── Features ───
  String get whatYouCanDo => _get({
        'en': 'What You Can Do',
        'id': 'Yang Bisa Dilakukan',
        'ms': 'Apa Yang Boleh Dilakukan'
      });

  // ─── Warning ───
  String get importantNotice => _get({
        'en': 'Important Notice',
        'id': 'Pemberitahuan Penting',
        'ms': 'Notis Penting'
      });

  String get agreeBackup => _get({
        'en': 'I have backed up my router and understand the risks',
        'id': 'Saya telah mencadangkan router dan memahami risikonya',
        'ms': 'Saya telah membuat sandar router dan memahami risiko',
      });

  // ─── Get Started ───
  String get readyToStart => _get(
      {'en': 'Ready to Start!', 'id': 'Siap Memulai!', 'ms': 'Sedia Bermula!'});

  String get connectDescription => _get({
        'en':
            'Connect your MikroTik router or try the app with demo data first.',
        'id':
            'Hubungkan router MikroTik Anda atau coba aplikasi dengan data demo terlebih dahulu.',
        'ms':
            'Sambungkan router MikroTik anda atau cuba aplikasi dengan data demo dahulu.',
      });

  String get connectToRouter => _get({
        'en': 'Connect to Router',
        'id': 'Hubungkan ke Router',
        'ms': 'Sambung ke Router'
      });
  String get tryDemoData => _get({
        'en': 'Try with Demo Data',
        'id': 'Coba dengan Data Demo',
        'ms': 'Cuba dengan Data Demo'
      });

  // ─── Quick Setup ───
  String get quickSetup => _get({
        'en': 'Quick Setup',
        'id': 'Pengaturan Cepat',
        'ms': 'Persediaan Pantas'
      });

  String get quickSetupDescription => _get({
        'en':
            'Set your preferences for currency and location. You can change these later in Settings.',
        'id':
            'Atur preferensi mata uang dan lokasi. Anda bisa mengubahnya nanti di Pengaturan.',
        'ms':
            'Tetapkan pilihan mata wang dan lokasi. Anda boleh mengubahnya kemudian dalam Tetapan.',
      });

  String get country => _get({'en': 'Country', 'id': 'Negara', 'ms': 'Negara'});
  String get currency =>
      _get({'en': 'Currency', 'id': 'Mata Uang', 'ms': 'Mata Wang'});
  String get companyName => _get({
        'en': 'Business Name (optional)',
        'id': 'Nama Usaha (opsional)',
        'ms': 'Nama Perniagaan (pilihan)'
      });
  String get language =>
      _get({'en': 'Language', 'id': 'Bahasa', 'ms': 'Bahasa'});
  String get saveAndContinue => _get({
        'en': 'Save & Continue',
        'id': 'Simpan & Lanjutkan',
        'ms': 'Simpan & Teruskan'
      });

  // ─── Welcome / Login ───
  String get welcomeBack => _get({
        'en': 'Welcome Back!',
        'id': 'Selamat Datang Kembali!',
        'ms': 'Selamat Datang Kembali!'
      });

  String get selectRouter => _get({
        'en': 'Select a router to connect',
        'id': 'Pilih router untuk terhubung',
        'ms': 'Pilih router untuk disambungkan',
      });

  String get enterDetails => _get({
        'en': 'Enter your router details',
        'id': 'Masukkan detail router Anda',
        'ms': 'Masukkan butiran router anda',
      });

  String get myRouters =>
      _get({'en': 'My Routers', 'id': 'Router Saya', 'ms': 'Router Saya'});
  String get connectNewRouter => _get({
        'en': 'Connect to New Router',
        'id': 'Hubungkan Router Baru',
        'ms': 'Sambung ke Router Baru'
      });
  String get noRoutersSaved => _get({
        'en': 'No routers saved yet',
        'id': 'Belum ada router tersimpan',
        'ms': 'Tiada router disimpan lagi'
      });

  String get addRouterBelow => _get({
        'en': 'Add your router below to get started',
        'id': 'Tambahkan router di bawah untuk memulai',
        'ms': 'Tambahkan router anda di bawah untuk bermula',
      });

  String get routerIP =>
      _get({'en': 'Router IP', 'id': 'Router IP', 'ms': 'Router IP'});
  String get port => _get({'en': 'Port', 'id': 'Port', 'ms': 'Port'});
  String get username =>
      _get({'en': 'Username', 'id': 'Nama Pengguna', 'ms': 'Nama Pengguna'});
  String get password =>
      _get({'en': 'Password', 'id': 'Kata Sandi', 'ms': 'Kata Laluan'});
  String get connectAndSave => _get({
        'en': 'Connect & Save',
        'id': 'Hubungkan & Simpan',
        'ms': 'Sambung & Simpan'
      });
  String get connecting => _get(
      {'en': 'Connecting...', 'id': 'Menghubungkan...', 'ms': 'Menyambung...'});
  String get enterApp =>
      _get({'en': 'ENTER APP', 'id': 'MASUK APLIKASI', 'ms': 'MASUK APLIKASI'});

  // ─── Dashboard ───
  String get dashboard =>
      _get({'en': 'Dashboard', 'id': 'Dasbor', 'ms': 'Papan Pemuka'});
  String get searchUsers => _get(
      {'en': 'Search users', 'id': 'Cari pengguna', 'ms': 'Cari pengguna'});

  // ─── Users ───
  String get hotspotUsers => _get({
        'en': 'Hotspot Users',
        'id': 'Pengguna Hotspot',
        'ms': 'Pengguna Hotspot'
      });
  String get activeUsers => _get(
      {'en': 'Active Users', 'id': 'Pengguna Aktif', 'ms': 'Pengguna Aktif'});
  String get hotspotHosts =>
      _get({'en': 'Hotspot Hosts', 'id': 'Host Hotspot', 'ms': 'Host Hotspot'});
  String get userProfiles => _get({
        'en': 'User Profiles',
        'id': 'Profil Pengguna',
        'ms': 'Profil Pengguna'
      });

  // ─── Vouchers ───
  String get generateVouchers => _get(
      {'en': 'Generate Vouchers', 'id': 'Buat Voucher', 'ms': 'Cipta Voucher'});
  String get vouchers =>
      _get({'en': 'Vouchers', 'id': 'Voucher', 'ms': 'Voucher'});

  // ─── Revenue ───
  String get revenue =>
      _get({'en': 'Revenue', 'id': 'Pendapatan', 'ms': 'Pendapatan'});

  // ─── Settings ───
  String get settings =>
      _get({'en': 'Settings', 'id': 'Pengaturan', 'ms': 'Tetapan'});
  String get activityLogs =>
      _get({'en': 'Activity Logs', 'id': 'Log Aktiviti', 'ms': 'Log Aktiviti'});

  // ─── Common ───
  String get cancel => _get({'en': 'Cancel', 'id': 'Batal', 'ms': 'Batal'});
  String get delete => _get({'en': 'Delete', 'id': 'Hapus', 'ms': 'Padam'});
  String get save => _get({'en': 'Save', 'id': 'Simpan', 'ms': 'Simpan'});
  String get edit => _get({'en': 'Edit', 'id': 'Ubah', 'ms': 'Edit'});
  String get refresh =>
      _get({'en': 'Refresh', 'id': 'Segarkan', 'ms': 'Muat Semula'});
  String get retry =>
      _get({'en': 'Retry', 'id': 'Coba Lagi', 'ms': 'Cuba Lagi'});
  String get close => _get({'en': 'Close', 'id': 'Tutup', 'ms': 'Tutup'});
  String get ok => _get({'en': 'OK', 'id': 'OK', 'ms': 'OK'});
  String get loading =>
      _get({'en': 'Loading...', 'id': 'Memuat...', 'ms': 'Memuatkan...'});

  // ─── What's New ───
  String get whatsNew =>
      _get({"en": "What's New", 'id': 'Yang Baru', 'ms': 'Apa Yang Baru'});
  String get gotIt =>
      _get({'en': 'Got it!', 'id': 'Mengerti!', 'ms': 'Faham!'});
}
