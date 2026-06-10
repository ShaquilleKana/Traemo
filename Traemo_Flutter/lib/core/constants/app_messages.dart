abstract final class AppMessages {
  static const loginSuccess = 'Selamat datang kembali!';
  static const loginFailed =
      'Email atau kata sandi yang Anda masukkan tidak sesuai.';
  static const registerSuccess = 'Selamat! Akun Anda berhasil dibuat.';
  static const registerFailed = 'Pendaftaran gagal. Silakan coba lagi.';
  static const logoutSuccess = 'Anda telah keluar dari akun.';
  static const logoutDialogTitle = 'Keluar dari Akun';
  static const logoutDialogMessage =
      'Apakah Anda yakin ingin keluar dari akun ini?\n\n'
      'Anda perlu masuk kembali untuk mengakses data keuangan Anda.';
  static const cancel = 'Batal';
  static const logout = 'Keluar';

  static const transactionSaved = 'Transaksi berhasil disimpan.';
  static const multiTransactionSaved = 'Semua transaksi berhasil dicatat.';
  static String multiTransactionSavedCount(int count) =>
      '$count transaksi berhasil disimpan.';
  static const transactionUpdated = 'Perubahan transaksi berhasil disimpan.';
  static const transactionCancelled = 'Transaksi dibatalkan.';

  static const clearChatSuccess = 'Percakapan berhasil dibersihkan.';
  static const exportSuccess = 'File Excel berhasil disimpan.';
  static const exportFailed = 'Gagal membuat file Excel.';
  static const noDataToExport = 'Belum ada transaksi yang dapat diekspor.';

  static const emptyInput = 'Silakan masukkan pesan terlebih dahulu.';
  static const incompleteForm = 'Lengkapi data yang masih kosong.';
  static const validationReview = 'Mohon periksa kembali data yang dimasukkan.';
  static const nameRequired = 'Nama lengkap wajib diisi.';
  static const emailAlreadyUsed =
      'Email sudah terdaftar. Gunakan email lain atau masuk ke akun Anda.';
  static const invalidEmail = 'Format email tidak valid.';
  static const passwordTooShort = 'Kata sandi minimal 8 karakter.';
  static const passwordConfirmationMismatch =
      'Konfirmasi kata sandi tidak sesuai.';
  static const invalidClarification =
      'Maaf, saya belum memahami jawaban tersebut.';
  static const aiParsingFailed =
      'Maaf, saya belum dapat memahami transaksi tersebut.';
  static const apiConnectionFailed = 'Tidak dapat terhubung ke server.';
  static const serverError = 'Terjadi kesalahan pada server.';
  static const dashboardLoadFailed = 'Data dashboard tidak dapat dimuat.';
  static const historyLoadFailed = 'Riwayat transaksi tidak dapat dimuat.';

  static const dashboardRefresh = 'Memperbarui data keuangan...';
  static const dataSynchronization = 'Menyinkronkan data...';
  static const longRunningProcess = 'Mohon tunggu sebentar...';
  static const aiProcessing = 'Sedang memahami pesan Anda...';
  static const aiAnalyzingTransaction = 'Sedang menganalisis transaksi...';

  static const reminderEnabled = 'Reminder aktif setiap pukul';
  static const reminderDisabled = 'Reminder dinonaktifkan';
}
