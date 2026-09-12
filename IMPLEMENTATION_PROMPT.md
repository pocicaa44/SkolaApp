# Panduan Implementasi: Alur Verifikasi OTP Email untuk Reset Password

Dokumen ini berisi panduan teknis lengkap, arsitektur, dan langkah-langkah implementasi untuk menambahkan **Halaman Verifikasi Kode OTP (Email)** sebelum diarahkan ke **Halaman Input Password Baru**.

---

## 1. Alur Kerja Pengguna (User Flow)

```mermaid
flowchart TD
    A[Halaman Login] -->|Klik 'Lupa Password?'| B[Halaman Lupa Password (ForgotPasswordView)]
    B -->|Input Email & Klik 'Kirim Kode OTP'| C[Supabase: resetPasswordForEmail]
    C -->|Sukses terkirim| D[Navigasi ke Halaman Verifikasi OTP (VerifyOtpView)]
    D -->|User Menerima Kode 6 Digit di Email| E[Input 6 Digit Kode OTP]
    E -->|Klik 'Verifikasi' / Auto-submit| F[Supabase: verifyOTP OtpType.recovery]
    F -->|Kode Valid & Sesi Recovery Aktif| G[Navigasi ke Halaman Reset Password (ResetPasswordView)]
    F -->|Kode Salah / Kadaluarsa| D
    D -->|Klik 'Kirim Ulang Kode'| C
    G -->|Input Password Baru min. 8 Karakter & Simpan| H[Supabase: updateUser]
    H -->|Berhasil & Sign Out Sesi Recovery| I[Kembali ke Halaman Login dengan Pesan Sukses]
```

---

## 2. Prasyarat & Konfigurasi Supabase

Sebelum menjalankan kode di aplikasi Flutter, pastikan konfigurasi di **Supabase Dashboard** telah disesuaikan:

1. Buka **Supabase Dashboard** > **Authentication** > **Email Templates**.
2. Pilih template **Reset Password**.
3. Pastikan template menyertakan token/kode OTP numerik 6 digit dengan variabel:
   ```html
   <h2>Reset Password</h2>
   <p>Gunakan kode OTP berikut untuk mengatur ulang kata sandi akun Anda:</p>
   <h1 style="font-size: 32px; letter-spacing: 5px; font-weight: bold; color: #2563EB;">{{ .Token }}</h1>
   <p>Kode ini berlaku selama 1 jam. Jangan bagikan kode ini kepada siapapun.</p>
   ```
4. Pastikan masa berlaku OTP (OTP Expiry) diatur dengan aman (default: 3600 detik / 1 jam).

---

## 3. Arsitektur & Struktur File

Sesuai pola arsitektur MVP (Model-View-Presenter) yang digunakan pada `SkolaApp`:

```
lib/
├── data/
│   └── repositories/
│       └── auth_repository.dart                # [MODIFY] Tambah verifyRecoveryOtp()
├── features/
│   └── auth/
│       ├── forgot_password_contract.dart       # [MODIFY] Tambah VerifyOtpViewContract & PresenterContract
│       ├── forgot_password_presenter.dart      # [MODIFY] Tambah VerifyOtpPresenter
│       ├── forgot_password_view.dart           # [MODIFY] Navigasi ke VerifyOtpView saat email terkirim
│       ├── verify_otp_view.dart                # [NEW] Halaman UI Masukkan Kode OTP 6 Digit
│       ├── reset_password_view.dart            # [MODIFY] Validasi alur setelah OTP diverifikasi
│       └── widgets/
│           └── otp_input_field.dart            # [NEW] Widget 6-digit PIN / OTP Input dengan auto-focus
```

---

## 4. Langkah-Langkah Implementasi

### Langkah 1: Tambahkan Metode `verifyRecoveryOtp` pada Data Layer
**File:** `lib/data/repositories/auth_repository.dart`

Tambahkan metode untuk memverifikasi token OTP pemulihan sandi menggunakan Supabase Auth:

```dart
/// Verifikasi kode OTP pemulihan sandi yang dikirimkan ke email
Future<AuthResponse> verifyRecoveryOtp({
  required String email,
  required String token,
}) async {
  return await _supabase.auth.verifyOTP(
    email: email.trim(),
    token: token.trim(),
    type: OtpType.recovery,
  );
}
```

---

### Langkah 2: Definisikan Kontrak MVP
**File:** `lib/features/auth/forgot_password_contract.dart`

Tambahkan kontrak view dan presenter untuk fitur verifikasi OTP:

```dart
// --- Kontrak untuk Halaman Verifikasi OTP ---
abstract class VerifyOtpViewContract extends BaseView {
  void onOtpVerified();
  void onOtpResent();
  void updateResendCountdown(int secondsRemaining);
}

abstract class VerifyOtpPresenterContract {
  Future<void> verifyOtp({
    required String email,
    required String otp,
  });
  Future<void> resendOtp(String email);
  void startResendTimer();
  void disposeTimer();
}
```

---

### Langkah 3: Implementasikan `VerifyOtpPresenter`
**File:** `lib/features/auth/forgot_password_presenter.dart`

Buat presenter yang mengelola logika verifikasi kode OTP dan hitung mundur kirim ulang:

```dart
/// Presenter untuk halaman Verifikasi Kode OTP
class VerifyOtpPresenter extends BasePresenter<VerifyOtpViewContract>
    implements VerifyOtpPresenterContract {
  final AuthRepository _authRepo;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  VerifyOtpPresenter({AuthRepository? authRepo})
      : _authRepo = authRepo ?? AuthRepository();

  @override
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final cleanOtp = otp.trim();
    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      view?.showError('Masukkan 6 digit kode OTP yang valid.');
      return;
    }

    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final response = await _authRepo.verifyRecoveryOtp(
        email: email,
        token: cleanOtp,
      );

      if (response.session != null || _authRepo.currentUser != null) {
        if (isViewAttached) {
          view?.showSuccess('Kode OTP berhasil diverifikasi.');
          view?.onOtpVerified();
        }
      } else {
        if (isViewAttached) {
          view?.showError('Verifikasi gagal. Silakan coba lagi.');
        }
      }
    } on AuthException catch (e) {
      if (isViewAttached) {
        final lower = e.message.toLowerCase();
        if (lower.contains('expired') || lower.contains('invalid')) {
          view?.showError('Kode OTP salah atau telah kadaluarsa.');
        } else {
          view?.showError(e.message);
        }
      }
    } catch (e) {
      if (isViewAttached) {
        if (!kIsWeb && e is SocketException) {
          view?.showError('Gagal terhubung ke server. Periksa koneksi internet.');
        } else {
          view?.showError('Terjadi kesalahan saat memverifikasi OTP.');
        }
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  Future<void> resendOtp(String email) async {
    if (_secondsRemaining > 0) return;

    if (!isViewAttached) return;
    view?.showLoading();

    try {
      await _authRepo.resetPasswordForEmail(email: email);
      startResendTimer();
      if (isViewAttached) {
        view?.showSuccess('Kode OTP baru telah dikirimkan ke email Anda.');
        view?.onOtpResent();
      }
    } on AuthException catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal mengirim ulang OTP: ${e.message}');
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Terjadi kesalahan saat mengirim ulang kode.');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  void startResendTimer() {
    _countdownTimer?.cancel();
    _secondsRemaining = 60;
    view?.updateResendCountdown(_secondsRemaining);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        view?.updateResendCountdown(_secondsRemaining);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void disposeTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void detachView() {
    disposeTimer();
    super.detachView();
  }
}
```

---

### Langkah 4: Buat Komponen Input OTP 6 Digit
**File:** `lib/features/auth/widgets/otp_input_field.dart`

Buat widget input 6 digit terpisah dengan kotak-kotak berjarak dan transisi fokus otomatis:
- Menampilkan 6 input box berukuran seragam.
- Hanya menerima angka (digit `0-9`).
- Otomatis berpindah ke kotak berikutnya saat 1 digit diketik, dan kembali saat tombol backspace ditekan.
- Memiliki callback `onCompleted(String code)` saat seluruh 6 digit terisi.
- Menggunakan token desain dari `AppTheme` (`AppTheme.primary`, `AppTheme.surface`, `AppTheme.border`, `AppTheme.radiusInput`).

---

### Langkah 5: Buat Halaman Verifikasi OTP (`VerifyOtpView`)
**File:** `lib/features/auth/verify_otp_view.dart`

Spesifikasi Halaman:
1. **AppBar**: Judul "Verifikasi Kode OTP", tombol kembali.
2. **Header Visual**:
   - Ikon `Icons.mark_email_unread_outlined` dengan latar belakang `AppTheme.primarySurface`.
   - Judul: "Masukkan Kode OTP".
   - Subtitle: "Kode 6 digit telah dikirimkan ke email **user@email.com**. Masukkan kode tersebut untuk melanjutkan."
3. **Input OTP**: Komponen `OtpInputField` 6 digit.
4. **Tombol Verifikasi**:
   - Teks: "Verifikasi Kode".
   - Tampilan loading jika proses verifikasi sedang berjalan.
5. **Kirim Ulang (Resend)**:
   - Teks interaktif: "Tidak menerima kode? **Kirim Ulang**" dengan indikator waktu tunggu (cooldown) 60 detik jika timer masih aktif.
6. **Aksi setelah Sukses**:
   - Saat `onOtpVerified` dipanggil, navigasikan langsung ke halaman `ResetPasswordView(email: widget.email)` menggunakan `Navigator.pushReplacement()`.

---

### Langkah 6: Hubungkan Halaman `ForgotPasswordView`
**File:** `lib/features/auth/forgot_password_view.dart`

Perbarui metode `onRecoveryEmailSent(String email)`:
- Jangan hanya menampilkan pesan sukses statis.
- Otomatis arahkan (atau sediakan navigasi langsung) ke `VerifyOtpView(email: cleanEmail)`.

Contoh implementasi transisi:
```dart
@override
void onRecoveryEmailSent(String email) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => VerifyOtpView(email: email),
    ),
  );
}
```

---

### Langkah 7: Perbarui `ResetPasswordView`
**File:** `lib/features/auth/reset_password_view.dart`

- Pastikan sesi pemulihan aktif terdeteksi setelah `verifyRecoveryOtp` berhasil.
- Pengguna memasukkan kata sandi baru (minimal 8 karakter) dan konfirmasi kata sandi.
- Setelah berhasil disimpan:
  1. Panggil `updateUserPassword(newPassword)`.
  2. Panggil `signOut()` untuk membersihkan sesi sementara pemulihan.
  3. Arahkan pengguna kembali ke `LoginView` dengan pesan:
     *"Password berhasil diperbarui! Silakan masuk menggunakan kata sandi baru Anda."*

---

## 5. Standar Desain & Styling (Mengikuti `AppTheme`)

Semua komponen baru wajib mematuhi aturan tema yang ada:
- **Warna Utama**: `AppTheme.primary` (#2563EB), `AppTheme.primarySurface` (#EFF6FF).
- **Latar Belakang**: `AppTheme.background` (#F8FAFC), `AppTheme.surface` (#FFFFFF).
- **Border**: `AppTheme.border` (#E2E8F0) dengan border fokus `AppTheme.primary`.
- **Radius**: `AppTheme.radiusInput` (10.0), `AppTheme.radiusButton` (10.0), `AppTheme.radiusCard` (14.0).
- **Responsivitas**: Batasi lebar form maksimum pada web/tablet dengan `ConstrainedBox(constraints: BoxConstraints(maxWidth: 440))` di tengah layar (`Center`).

---

## 6. Penanganan Skenario Kegagalan (Edge Cases)

| Skenario | Penanganan Sistem |
|---|---|
| **Kode OTP Salah / Kadaluarsa** | Tampilkan SnackBar error: *"Kode OTP salah atau telah kadaluarsa."* dan reset fokus input. |
| **Terlalu Sering Meminta Kirim Ulang** | Batasi tombol kirim ulang dengan timer cooldown 60 detik. Tangkap error *rate limit* jika ada. |
| **Koneksi Internet Terputus** | Tangkap `SocketException` dan tampilkan pesan: *"Gagal terhubung ke server. Periksa koneksi internet."* |
| **Sesi Recovery Hilang Sebelum Submit Password** | Cek `currentUser != null`. Jika null, arahkan kembali ke `ForgotPasswordView` dengan notifikasi sesi habis. |
| **Password Baru Kurang dari 8 Karakter** | Validasi di sisi klien (`validator`) sebelum memicu request jaringan. |

---

## 7. Rencana Pengujian (Testing Plan)

1. **Unit Test Presenter**:
   - Uji `VerifyOtpPresenter.verifyOtp` saat OTP valid (memanggil view `onOtpVerified`).
   - Uji `VerifyOtpPresenter.verifyOtp` saat kode kurang dari 6 digit atau non-numerik.
   - Uji penanganan error saat kode salah/kadaluarsa.
   - Uji fungsi kirim ulang dan timer countdown.
2. **Widget Test**:
   - Pastikan 6 digit box ter-render dengan baik.
   - Uji otomatisasi fokus antar kotak input OTP.
   - Uji validasi disable/enable tombol saat loading.
3. **Analisis Statis**:
   - Jalankan `flutter analyze` untuk memastikan tidak ada issue, lint warning, atau error tipe.
