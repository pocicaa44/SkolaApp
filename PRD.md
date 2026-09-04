# PRD --- Skola App

> **Dokumen ini adalah Product Requirements Document (PRD) untuk AI
> Agent.**
>
> Gunakan dokumen ini sebagai sumber kebenaran utama untuk memahami
> tujuan, scope, business rules, alur pengguna, dan batasan implementasi
> Skola App.
>
> **Status:** Product Requirements --- Draft Matang / Ready for
> Technical Planning\
> **Platform:** Flutter --- Android, iOS, Web\
> **Backend:** Supabase\
> **Target utama:** Guru / Tenaga Pendidik\
> **Admin:** Administrasi sekolah

------------------------------------------------------------------------

## 1. Product Overview

### 1.1 Nama Produk

**Skola App**

### 1.2 Ringkasan

Skola App adalah aplikasi informasi dan administrasi pembelajaran
sekolah yang berfokus pada digitalisasi proses yang dilakukan Guru
selama kegiatan belajar mengajar, terutama:

-   Pengelolaan jadwal mengajar.
-   Pengelolaan sesi pembelajaran berdasarkan jadwal.
-   Presensi siswa.
-   Jurnal pembelajaran.
-   Review hasil pembelajaran oleh Admin sekolah.

Aplikasi harus membuat proses administrasi pembelajaran menjadi lebih
terstruktur tanpa membuat Guru terbebani oleh proses administrasi yang
tidak perlu.

### 1.3 Prinsip Utama Produk

1.  **Guru adalah pengguna utama.**
2.  **Admin menyediakan dan mengelola master data serta melakukan
    review.**
3.  **Sekolah menentukan konfigurasi Jam Pelajaran (JP).**
4.  Guru tidak memasukkan waktu mulai/selesai secara manual.
5.  Ketersediaan JP harus tersinkronisasi antar jadwal Guru berdasarkan
    **hari + kelas**.
6.  Presensi bersifat per-sesi pembelajaran.
7.  Jurnal bersifat opsional dan juga per-sesi.
8.  Jadwal recurring merupakan template yang berulang; setiap
    pengulangannya menghasilkan sesi baru.
9.  Data historis pembelajaran tidak boleh hilang hanya karena jadwal
    recurring diubah/dihapus.
10. Jangan melakukan overengineering. Implementasi harus sesuai
    kebutuhan produk dan MVP.

------------------------------------------------------------------------

# 2. Problem Statement

Administrasi pembelajaran seperti jadwal, presensi, dan jurnal sering
dilakukan secara manual atau tersebar di beberapa media.

Hal tersebut dapat menyebabkan:

-   Guru harus melakukan pencatatan berulang.
-   Risiko kesalahan pencatatan presensi.
-   Jadwal dapat bertabrakan.
-   Pembagian JP sulit dipantau.
-   Data hasil pembelajaran sulit direview.
-   Riwayat pembelajaran kurang terstruktur.
-   Administrasi sekolah membutuhkan data yang sudah tersusun untuk
    melakukan review.

Skola App bertujuan menyediakan satu sistem terintegrasi untuk proses
tersebut.

------------------------------------------------------------------------

# 3. Product Goals

## 3.1 Primary Goals

1.  Memudahkan Guru membuat dan menggunakan jadwal mengajar.
2.  Mencegah bentrokan penggunaan JP untuk kelas yang sama.
3.  Mengotomatisasi status sesi berdasarkan waktu JP.
4.  Memudahkan Guru melakukan presensi siswa.
5.  Memudahkan Guru mencatat jurnal pembelajaran.
6.  Menyediakan data pembelajaran yang dapat direview Admin.
7.  Menjaga data historis presensi dan jurnal tetap konsisten.

## 3.2 Success Criteria

Produk dianggap berhasil apabila:

-   Guru dapat membuat jadwal tanpa memasukkan waktu manual.
-   Sistem hanya menampilkan JP yang tersedia untuk kombinasi hari +
    kelas.
-   Dua Guru tidak dapat menggunakan JP yang sama untuk kelas yang sama.
-   Sesi otomatis terbuka dan tertutup berdasarkan konfigurasi JP.
-   Guru tidak dapat menyelesaikan presensi apabila masih ada siswa
    `Belum diisi`.
-   Setiap siswa memiliki tepat satu status presensi per sesi.
-   Jurnal dapat dicatat secara opsional.
-   Admin dapat mereview hasil presensi dan jurnal Guru.
-   Data historis tetap tersedia meskipun jadwal recurring diubah atau
    dihapus.

------------------------------------------------------------------------

# 4. User Roles

## 4.1 Teacher / Guru

Guru adalah pengguna utama aplikasi.

Guru dapat:

-   Login.
-   Melengkapi profil.
-   Menentukan maksimal 2 mata pelajaran yang diampu dari master data.
-   Membuat jadwal mengajar.
-   Memilih kelas dari master data.
-   Memilih hari.
-   Memilih JP yang tersedia.
-   Mengedit jadwal.
-   Menghapus jadwal.
-   Melihat jadwal miliknya.
-   Membuka sesi pembelajaran ketika sesi otomatis `OPEN`.
-   Mengisi presensi siswa.
-   Mengedit presensi selama sesi `OPEN`.
-   Mengisi jurnal pembelajaran secara opsional.
-   Mengedit jurnal selama sesi `OPEN`.
-   Melihat hasil sesi yang telah selesai sesuai hak akses Guru.

Guru **tidak dapat**:

-   Mengelola master data kelas.
-   Mengelola master data mata pelajaran.
-   Mengubah konfigurasi JP sekolah.
-   Mengubah data Guru lain.
-   Mengubah presensi setelah sesi selesai.
-   Mengubah jurnal setelah sesi selesai.
-   Mengelola data administrasi Guru lain.

Guru hanya dapat mengakses data pembelajaran miliknya sendiri.

------------------------------------------------------------------------

## 4.2 Admin

Admin adalah pengguna administrasi sekolah.

Admin dapat:

-   Mengelola master data siswa.
-   Mengelola kelas.
-   Mengelola mata pelajaran.
-   Mengelola konfigurasi JP.
-   Melihat jadwal Guru.
-   Mereview jadwal pembelajaran.
-   Melihat data Guru/Tenaga Pendidik.
-   Menonaktifkan akun Guru.
-   Menghapus akun Guru.
-   Mereview hasil presensi.
-   Mereview jurnal pembelajaran.

Admin **tidak mengubah hasil presensi atau jurnal yang telah dibuat
Guru.**

Admin berfungsi sebagai pihak administrasi yang menerima dan mereview
hasil pembelajaran.

------------------------------------------------------------------------

# 5. Authentication & Account

## 5.1 Authentication

Backend authentication menggunakan **Supabase Auth**.

Metode login:

-   Email + Password.
-   Google OAuth.

Google OAuth menggunakan konfigurasi Google Cloud dan Supabase Auth.

## 5.2 Initial Flow

``` text
Splash
   ↓
Cek Supabase Session
   ├── Authenticated → Dashboard
   └── Unauthenticated → Login
```

Splash screen berjalan sekitar 3 detik sebelum pengecekan/redirect
aplikasi.

## 5.3 Registration

Guru dapat membuat akun melalui:

-   Email + password.
-   Google OAuth.

Setelah login pertama kali, Guru harus melengkapi profil.

## 5.4 Teacher Profile

Minimal profil Guru:

-   Nama lengkap.
-   Mata pelajaran yang diampu.
-   Maksimal 2 mata pelajaran.
-   Data profil lain yang diperlukan sekolah.

Mata pelajaran dipilih dari master data yang dibuat Admin.

## 5.5 Account Status

Guru memiliki status akun.

Minimal:

-   `ACTIVE`
-   `INACTIVE`
-   `DELETED`

### ACTIVE

Guru dapat menggunakan aplikasi secara normal.

### INACTIVE

-   Guru tidak dapat menggunakan fitur pembelajaran seperti biasa.
-   Guru harus mengetahui bahwa akunnya telah dinonaktifkan.
-   UI harus memberikan informasi yang jelas mengenai status akun.

### DELETED

-   Guru tidak dapat login.
-   Jika sedang login, akses/session harus dicabut sehingga Guru
    otomatis logout/tidak dapat melanjutkan penggunaan aplikasi.

------------------------------------------------------------------------

# 6. Master Data

Master data dikendalikan oleh Admin.

## 6.1 Teacher

Data Guru/Tenaga Pendidik.

Digunakan untuk:

-   Identitas pengguna.
-   Relasi jadwal.
-   Relasi presensi/jurnal.
-   Administrasi akun.

## 6.2 Subject

Mata pelajaran.

Guru hanya memilih mata pelajaran dari data yang tersedia.

Guru tidak membuat mata pelajaran baru.

## 6.3 Class

Kelas yang digunakan dalam pembelajaran.

Guru hanya memilih kelas dari data yang tersedia.

## 6.4 Student

Data siswa dikelola Admin.

Minimal memiliki:

-   Identitas siswa.
-   Kelas.

Siswa digunakan sebagai daftar peserta pada sesi pembelajaran.

------------------------------------------------------------------------

# 7. Jam Pelajaran (JP)

## 7.1 Konsep

Sekolah/Admin menentukan konfigurasi Jam Pelajaran.

Guru tidak menentukan sendiri waktu mulai dan selesai.

Guru hanya memilih JP yang tersedia.

Sistem kemudian mengambil waktu mulai dan selesai berdasarkan
konfigurasi sekolah.

Contoh:

``` text
JP 1 = 07:00 - 07:45
JP 2 = 07:45 - 08:30
JP 3 = 08:30 - 09:15
```

Jika Guru memilih JP 1--3, sistem memahami bahwa sesi berlangsung dari
awal JP 1 sampai akhir JP 3.

## 7.2 JP Dapat Berbeda Berdasarkan Hari

Konfigurasi JP dapat berbeda antara:

-   Senin.
-   Selasa.
-   Rabu.
-   Kamis.
-   Jumat.
-   Hari sekolah lain jika nantinya dibutuhkan.

Karena itu, JP harus dikaitkan dengan hari/konfigurasi sekolah yang
sesuai.

## 7.3 JP Tidak Selalu Available

Tidak semua JP dapat digunakan oleh Guru.

Availability ditentukan oleh:

``` text
Hari
+
Kelas
+
Jadwal yang sudah digunakan
```

------------------------------------------------------------------------

# 8. Schedule / Jadwal

## 8.1 Konsep

Jadwal adalah **recurring schedule / template jadwal berulang**.

Contoh:

``` text
Senin
Kelas XI PPLG
Matematika
JP 1–3
```

Jadwal tersebut berulang setiap Senin sesuai aturan sekolah.

Jadwal recurring tidak memiliki tanggal akhir secara default.

## 8.2 Data Jadwal

Minimal jadwal memiliki:

-   Guru.
-   Mata pelajaran.
-   Kelas.
-   Hari.
-   JP awal.
-   JP akhir.
-   Referensi konfigurasi waktu JP.

Waktu mulai/selesai **tidak diketik manual oleh Guru**.

## 8.3 Membuat Jadwal

Alur:

``` text
Guru
 ↓
Pilih Mata Pelajaran
 ↓
Pilih Kelas
 ↓
Pilih Hari
 ↓
Sistem menghitung JP yang tersedia
 ↓
Guru memilih satu atau beberapa JP
 ↓
Sistem validasi konflik
 ↓
Jadwal dibuat
```

## 8.4 JP Availability Engine

Sistem wajib menghitung ketersediaan JP berdasarkan:

``` text
Hari + Kelas
```

Contoh:

``` text
Senin + Kelas XI
```

Sudah terdapat:

``` text
Matematika → JP 1–2
```

Maka untuk Guru lain yang membuat jadwal:

``` text
JP 1 → DISABLED
JP 2 → DISABLED
JP 3 → AVAILABLE
JP 4 → AVAILABLE
...
JP 10 → AVAILABLE
```

Guru tidak boleh memilih JP 1--2 untuk Kelas XI.

Namun:

``` text
Senin + Kelas X
```

JP 1--2 tetap dapat tersedia karena konflik tidak terjadi pada kelas
tersebut.

### Prinsip penting

Konflik JP **bukan global berdasarkan hari saja.**

Konflik dihitung berdasarkan:

``` text
HARI + KELAS + JP
```

Guru berbeda boleh mengajar pada JP yang sama jika kelasnya berbeda.

Guru yang berbeda **tidak boleh** mengajar kelas yang sama pada JP yang
sama.

## 8.5 Consecutive JP

Guru dapat memilih beberapa JP berurutan untuk satu jadwal.

Contoh:

``` text
JP 1
JP 2
JP 3
```

menjadi satu sesi pembelajaran:

``` text
07:00 - 09:15
```

Sistem harus memastikan JP yang dipilih valid dan tidak bertabrakan.

## 8.6 Edit Jadwal

Guru dapat mengedit jadwal.

Saat mengedit:

-   Sistem harus menghitung ulang availability.
-   Slot milik jadwal yang sedang diedit dapat dianggap sebagai slot
    miliknya sendiri selama proses validasi.
-   Slot yang digunakan jadwal lain tetap `DISABLED`.
-   Jadwal baru tidak boleh menyebabkan konflik.

## 8.7 Delete Jadwal

Guru dapat menghapus jadwal.

Tidak ada fitur `Deactivate Schedule` untuk Guru.

Penghapusan jadwal recurring **tidak boleh menghapus data historis**.

Contoh:

``` text
Jadwal:
Senin — XI PPLG — Matematika — JP 1–2
```

Sudah menghasilkan sesi:

``` text
1 Sep → presensi + jurnal
8 Sep → presensi + jurnal
```

Jika jadwal kemudian dihapus, data tanggal 1 Sep dan 8 Sep tetap
tersimpan sebagai histori.

------------------------------------------------------------------------

# 9. Schedule Conflict Rules

Ini adalah salah satu business rule terpenting aplikasi.

## 9.1 Konflik Guru/Kelas/JP

Sistem harus menolak:

``` text
Guru A
Senin
Kelas XI
JP 1–2
```

jika sudah terdapat:

``` text
Guru B
Senin
Kelas XI
JP 1–2
```

## 9.2 Conflict Constraint

Secara konseptual:

``` text
UNIQUE / EXCLUSION:
Hari + Kelas + JP
```

untuk jadwal aktif/berlaku.

Implementasi database harus memiliki mekanisme validasi yang aman
terhadap race condition, bukan hanya validasi UI.

UI `disabled` adalah bantuan untuk pengguna, tetapi database/backend
tetap harus menjadi lapisan validasi terakhir.

## 9.3 Admin Schedule Overview

Admin dapat melihat jadwal berdasarkan hari dan kelas.

Contoh:

``` text
SENIN — KELAS XI

JP 1–2 → Matematika
JP 3   → Bahasa Indonesia
JP 4–5 → Bahasa Inggris
JP 6–7 → PPKN
```

Tujuan:

-   Melihat pembagian JP.
-   Melihat mapel.
-   Melihat Guru.
-   Memastikan administrasi jadwal mudah direview.

------------------------------------------------------------------------

# 10. Session

## 10.1 Konsep

Jadwal recurring bukanlah data presensi/jurnal.

Setiap pengulangan jadwal menghasilkan **session / sesi pembelajaran
baru**.

Contoh:

``` text
Recurring Schedule
Senin
XI PPLG
Matematika
JP 7–8
```

Menghasilkan:

``` text
Session — 7 Sep
Session — 14 Sep
Session — 21 Sep
...
```

Setiap session memiliki:

-   tanggal aktual.
-   waktu mulai.
-   waktu selesai.
-   Guru.
-   kelas.
-   mata pelajaran.
-   presensi.
-   jurnal.

## 10.2 Session State

Minimal state:

``` text
LOCKED
OPEN
CLOSED
```

### LOCKED

Sebelum waktu mulai.

Guru:

-   dapat melihat detail jadwal/sesi.
-   tidak dapat mengisi presensi.
-   tidak dapat mengisi jurnal.

### OPEN

Tepat pada waktu mulai JP.

Guru:

-   dapat mengisi presensi.
-   dapat mengedit presensi.
-   dapat mengisi jurnal.
-   dapat mengedit jurnal.
-   dapat melihat realtime waktu tersisa.

### CLOSED

Tepat pada waktu selesai JP.

Guru:

-   tidak dapat mengedit presensi.
-   tidak dapat mengedit jurnal.
-   hanya dapat melihat hasil sesi.

## 10.3 Automatic Session Timing

Tidak ada tombol manual:

-   Open.
-   Close.

Jika sesi:

``` text
10:00 – 11:00
```

maka:

``` text
09:59 → LOCKED
10:00 → OPEN
11:00 → CLOSED
```

Saat memasuki `CLOSED`, aplikasi harus memberikan peringatan/informasi
kepada Guru.

## 10.4 Time Source

Status sesi harus mengikuti waktu yang dapat dipercaya.

Jangan hanya mengandalkan jam lokal perangkat sebagai sumber kebenaran
apabila hal tersebut dapat memungkinkan manipulasi waktu.

Backend/database harus menjadi sumber validasi utama untuk batas waktu
sesi bila memungkinkan.

------------------------------------------------------------------------

# 11. Attendance / Presensi

## 11.1 Status

Setiap siswa memiliki satu status:

``` text
BELUM_DIISI
HADIR
IZIN
SAKIT
ALPA
```

## 11.2 Initial State

Ketika sesi dibuka, semua siswa awalnya:

``` text
BELUM_DIISI
```

Sistem **tidak otomatis menganggap siswa hadir**.

## 11.3 One Student One Status

Dalam satu session:

``` text
1 siswa = 1 status presensi
```

Contoh:

``` text
Session 7 Sep
Siswa A → HADIR
```

Tidak boleh memiliki dua record/status aktif untuk siswa A pada session
yang sama.

## 11.4 Input Rules

Presensi hanya dapat diinput/edit ketika:

``` text
Session = OPEN
```

## 11.5 Required Completion

Presensi adalah wajib.

Jurnal tidak wajib.

Session tidak boleh dianggap selesai/final apabila masih terdapat:

``` text
BELUM_DIISI
```

Contoh:

``` text
30 siswa
29 sudah diisi
1 masih BELUM_DIISI
```

Guru harus mendapatkan peringatan:

> Masih ada siswa yang belum memiliki status presensi.

Sistem tidak mengizinkan Guru menyelesaikan/finalisasi presensi dalam
kondisi tersebut.

### Catatan penting

Waktu session tetap memiliki batas `CLOSED` otomatis. Karena presensi
wajib lengkap, UI harus memberikan peringatan yang jelas
menjelang/ketika batas waktu tercapai.

Jika aturan teknis membutuhkan mekanisme penyelesaian setelah waktu
habis, jangan membuat asumsi baru. Business rule final harus menjaga
prinsip bahwa data presensi tidak boleh ditutup dengan status
`BELUM_DIISI`.

## 11.6 Attendance History

Guru dapat melihat hasil presensi yang telah selesai sebagai
histori/read-only sesuai data yang masih tersedia pada siklus penggunaan
jadwal.

Riwayat presensi tidak boleh ditimpa oleh sesi minggu berikutnya.

Contoh:

``` text
Senin 7 Sep
A → HADIR

Senin 14 Sep
A → SAKIT
```

Kedua data harus tetap berbeda.

------------------------------------------------------------------------

# 12. Journal / Jurnal Pembelajaran

## 12.1 Tujuan

Jurnal digunakan untuk mencatat hal-hal yang terjadi selama
pembelajaran.

Jurnal dapat berisi:

-   Materi pembelajaran.
-   Catatan singkat.
-   Kejadian/insiden selama pembelajaran.
-   Catatan siswa tertentu.
-   Informasi lain yang relevan dengan kegiatan pembelajaran.

Contoh:

``` text
Materi:
Logaritma

Catatan:
Siswa A izin pulang karena sakit.
```

Contoh lain:

``` text
Siswa B dispen untuk kegiatan OSIS.
```

Catatan tersebut tidak otomatis menentukan status presensi.

## 12.2 Optional

Jurnal bersifat **opsional**.

Session tetap dapat diselesaikan tanpa jurnal.

Jika jurnal tidak tersedia:

``` text
-
```

ditampilkan pada UI.

Database sebaiknya menggunakan `NULL` untuk jurnal yang belum diisi
daripada memaksakan string kosong, kecuali ada alasan teknis yang kuat.

## 12.3 Timing

Jurnal hanya dapat dibuat/edit ketika:

``` text
Session = OPEN
```

Setelah:

``` text
Session = CLOSED
```

Guru tidak dapat mengubah jurnal.

## 12.4 Journal History

Jurnal merupakan data per-session.

Jurnal minggu sebelumnya tidak boleh ditimpa oleh jurnal minggu
berikutnya.

------------------------------------------------------------------------

# 13. Student Class Movement

Admin mengelola penempatan siswa ke kelas.

Jika siswa dipindahkan:

``` text
XI A → XI B
```

perubahan berlaku untuk sesi pembelajaran berikutnya.

Data historis tidak boleh berubah secara retroaktif.

Contoh:

``` text
1 Sep
Siswa A berada di XI A
→ Presensi tersimpan di XI A

10 Sep
Siswa A dipindahkan ke XI B

15 Sep
Sesi baru
→ Siswa A berada di XI B
```

Presensi tanggal 1 Sep tetap berada pada konteks XI A.

Asumsi bisnis: perpindahan siswa dilakukan oleh administrasi sekolah dan
bukan perubahan mendadak yang mengharuskan rekonstruksi data historis.

------------------------------------------------------------------------

# 14. Admin Review

Admin bukan editor hasil pembelajaran.

Admin berperan sebagai reviewer.

## 14.1 Attendance Review

Admin dapat:

-   Melihat data presensi.
-   Melihat session.
-   Melihat Guru.
-   Melihat kelas.
-   Melihat tanggal.
-   Melihat status setiap siswa.

Admin **tidak mengubah presensi.**

## 14.2 Journal Review

Admin dapat:

-   Melihat jurnal.
-   Melihat session.
-   Melihat Guru.
-   Melihat kelas.
-   Melihat tanggal.
-   Melihat materi/catatan.

Admin **tidak mengubah jurnal.**

## 14.3 Schedule Review

Admin dapat melihat jadwal Guru dan pembagian JP.

Admin tidak bertindak sebagai editor presensi/jurnal.

------------------------------------------------------------------------

# 15. Data Ownership & Access Control

## 15.1 Teacher

Guru hanya dapat mengakses:

-   Profilnya sendiri.
-   Jadwal miliknya.
-   Session miliknya.
-   Siswa yang terkait dengan kelas pada session miliknya.
-   Presensi yang berkaitan dengan session miliknya.
-   Jurnal yang berkaitan dengan session miliknya.

Guru tidak boleh membaca/mengubah data Guru lain melalui API/database.

## 15.2 Admin

Admin dapat membaca data administrasi seluruh Guru dan data pembelajaran
yang diperlukan untuk review.

Admin memiliki akses review terhadap:

-   Guru.
-   Jadwal.
-   Kelas.
-   Siswa.
-   Mata pelajaran.
-   Presensi.
-   Jurnal.
-   Konfigurasi JP.

Namun Admin tidak boleh melakukan perubahan terhadap hasil
presensi/jurnal yang sudah dibuat Guru.

## 15.3 Backend Security

Jangan mengandalkan UI untuk security.

Semua pembatasan akses harus divalidasi di backend/database menggunakan
mekanisme Supabase yang sesuai, termasuk Row Level Security jika
digunakan.

------------------------------------------------------------------------

# 16. Dashboard

Dashboard harus sederhana dan fokus pada kebutuhan utama Guru.

Informasi penting dapat mencakup:

-   Jadwal/sesi hari ini.
-   Status sesi.
-   Ringkasan siswa yang relevan.
-   Akses cepat ke sesi yang sedang `OPEN`.
-   Informasi akun/status pengguna.

Jangan memenuhi dashboard dengan statistik yang tidak dibutuhkan.

Jika terdapat card jumlah siswa:

``` text
Laki-laki
Perempuan
Total
```

data harus berasal dari database.

Jika data yang dibutuhkan belum tersedia di database, jangan membuat
data dummy untuk menyamarkan kekurangan backend. Tandai dependency
database yang harus diselesaikan.

------------------------------------------------------------------------

# 17. Navigation

Navigasi harus sederhana.

Minimal area aplikasi Guru:

``` text
Dashboard
Jadwal
Profil
Logout
```

Struktur final dapat disesuaikan selama tidak menambah kompleksitas yang
tidak diperlukan.

Logout harus benar-benar melakukan sign out dari Supabase Auth.

------------------------------------------------------------------------

# 18. UI/UX Requirements

Detail visual mengikuti dokumen:

``` text
DESIGN.md
```

AI Agent **WAJIB membaca dan mengikuti DESIGN.md** sebelum
mengimplementasikan UI.

## 18.1 Visual Direction

-   Flat UI.
-   Modern.
-   Sederhana.
-   Bersih.
-   Biru sebagai aksen utama sesuai DESIGN.md versi terbaru.
-   Tanpa gradient.
-   Hindari glassmorphism.
-   Hindari shadow berlebihan.
-   Hindari dekorasi yang tidak memiliki fungsi.
-   Animasi minimal dan fungsional.
-   Fokus pada readability dan usability.

> Jika terdapat instruksi visual lama yang bertentangan dengan
> `DESIGN.md`, gunakan `DESIGN.md` sebagai sumber kebenaran untuk UI/UX.

## 18.2 Consistency

Semua halaman harus konsisten dalam:

-   Typography.
-   Spacing.
-   Border radius.
-   Button.
-   Input.
-   Card.
-   Navigation.
-   Color system.
-   State component.
-   Error/success feedback.

## 18.3 Responsive

Flutter app harus tetap usable pada:

-   Android phone.
-   iOS phone.
-   Web.

Web tidak boleh sekadar memperbesar layout mobile secara mentah.

------------------------------------------------------------------------

# 19. Core User Flow

## 19.1 First Login

``` text
Open App
 ↓
Splash
 ↓
Supabase Session Check
 ↓
Login / Register
 ↓
Authentication
 ↓
First Login?
 ├── Yes → Complete Profile
 └── No → Dashboard
```

## 19.2 Create Schedule

``` text
Dashboard
 ↓
Jadwal
 ↓
Tambah Jadwal
 ↓
Pilih Mapel
 ↓
Pilih Kelas
 ↓
Pilih Hari
 ↓
System loads JP availability
 ↓
Unavailable JP = Disabled
Available JP = Selectable
 ↓
Pilih JP
 ↓
Validate conflict
 ↓
Save
```

## 19.3 Teaching Session

``` text
Recurring Schedule
 ↓
Session generated for date
 ↓
LOCKED
 ↓
Start time
 ↓
OPEN
 ↓
Teacher opens session
 ↓
Input Attendance
 ↓
Input Journal (optional)
 ↓
All students must have attendance status
 ↓
Session reaches end time
 ↓
CLOSED
 ↓
Read-only / Admin Review
```

------------------------------------------------------------------------

# 20. Business Rules Summary

  ID       Rule
  -------- ---------------------------------------------------------
  BR-001   Guru adalah pengguna utama.
  BR-002   Admin mengelola master data sekolah.
  BR-003   Guru hanya memilih mapel dari master data.
  BR-004   Guru hanya memilih kelas dari master data.
  BR-005   Konfigurasi JP ditentukan sekolah/Admin.
  BR-006   Guru tidak mengetik waktu mulai/selesai manual.
  BR-007   Availability JP dihitung berdasarkan Hari + Kelas.
  BR-008   JP yang sudah dipakai pada Hari + Kelas harus disabled.
  BR-009   Konflik jadwal harus divalidasi backend/database.
  BR-010   Guru dapat memilih beberapa JP berurutan.
  BR-011   Jadwal bersifat recurring.
  BR-012   Jadwal tidak memiliki tanggal akhir secara default.
  BR-013   Guru dapat mengedit jadwal.
  BR-014   Guru dapat menghapus jadwal.
  BR-015   Penghapusan jadwal tidak menghapus histori.
  BR-016   Setiap pengulangan jadwal menghasilkan session baru.
  BR-017   Session sebelum mulai = LOCKED.
  BR-018   Session tepat pada waktu mulai = OPEN.
  BR-019   Session tepat pada waktu selesai = CLOSED.
  BR-020   Tidak ada manual Open/Close.
  BR-021   Presensi awal = BELUM_DIISI.
  BR-022   Presensi memiliki status Hadir, Izin, Sakit, Alpa.
  BR-023   Satu siswa hanya memiliki satu status per session.
  BR-024   Guru hanya dapat edit presensi ketika OPEN.
  BR-025   Semua siswa harus memiliki status presensi.
  BR-026   Jurnal bersifat opsional.
  BR-027   Jurnal dapat dibuat/edit hanya ketika OPEN.
  BR-028   Jurnal kosong ditampilkan sebagai `-`.
  BR-029   Guru hanya mengakses data pembelajaran miliknya.
  BR-030   Admin dapat mereview hasil presensi.
  BR-031   Admin tidak mengubah presensi.
  BR-032   Admin dapat mereview jurnal.
  BR-033   Admin tidak mengubah jurnal.
  BR-034   Admin mengelola data Guru/Tenaga Pendidik.
  BR-035   Guru dapat memiliki maksimal 2 mata pelajaran.
  BR-036   Guru nonaktif harus mendapat informasi status nonaktif.
  BR-037   Guru yang dihapus tidak dapat login.
  BR-038   Perpindahan siswa berlaku untuk sesi mendatang.
  BR-039   Histori siswa tidak boleh berubah retroaktif.
  BR-040   Tahun ajaran belum menjadi bagian MVP.

------------------------------------------------------------------------

# 21. MVP Scope

## P0 --- Wajib

### Authentication

-   Splash.
-   Login.
-   Register.
-   Email/password.
-   Google OAuth.
-   Supabase Auth.
-   Logout.
-   Session handling.
-   Account status.

### Profile

-   Complete profile.
-   Nama lengkap.
-   Maksimal 2 mapel.
-   Data profil yang diperlukan.

### Master Data

-   Guru.
-   Siswa.
-   Kelas.
-   Mata pelajaran.
-   Konfigurasi JP.

### Schedule

-   Create schedule.
-   Read schedule.
-   Edit schedule.
-   Delete schedule.
-   Recurring schedule.
-   JP selection.
-   JP availability.
-   Conflict prevention.
-   Admin schedule overview.

### Session

-   Automatic session creation/handling.
-   LOCKED.
-   OPEN.
-   CLOSED.
-   Automatic time transition.
-   Read-only after closed.

### Attendance

-   Student list.
-   BELUM_DIISI.
-   HADIR.
-   IZIN.
-   SAKIT.
-   ALPA.
-   One status/student/session.
-   Required completion.
-   Edit while OPEN.
-   Read-only after CLOSED.

### Journal

-   Optional journal.
-   Material.
-   Notes.
-   Edit while OPEN.
-   Read-only after CLOSED.
-   `-` when empty.

### Admin Review

-   Teacher management.
-   Student/class management.
-   Subject management.
-   JP management.
-   Schedule review.
-   Attendance review.
-   Journal review.

------------------------------------------------------------------------

# 22. Out of Scope / Future Development

Fitur berikut **jangan diimplementasikan sebagai bagian MVP** kecuali
requirements diperbarui:

-   Tahun ajaran sebagai sistem penuh.
-   Notifikasi kompleks.
-   Statistik pembelajaran lanjutan.
-   Export PDF/Excel.
-   Integrasi sistem sekolah eksternal.
-   Student/parent application.
-   Multi-school / multi-tenant.
-   Bulk import kompleks.
-   Payroll.
-   Nilai/rapor.
-   Penilaian siswa.
-   Chat Guru-Orang Tua.
-   GPS/geolocation attendance.
-   Face recognition.
-   QR attendance.
-   AI-generated journal.
-   Fitur lain yang tidak memiliki requirement eksplisit.

Future features boleh ditambahkan setelah PRD diperbarui.

------------------------------------------------------------------------

# 23. Non-Functional Requirements

## 23.1 Performance

-   UI harus responsif.
-   Jangan melakukan query database berulang tanpa kebutuhan.
-   Gunakan query yang sesuai kebutuhan layar.
-   Hindari polling agresif.
-   Realtime hanya digunakan ketika benar-benar diperlukan.

## 23.2 Reliability

-   Presensi tidak boleh hilang ketika UI berpindah state.
-   Data session harus konsisten.
-   Jadwal tidak boleh memiliki konflik.
-   Histori tidak boleh tertimpa.

## 23.3 Security

-   Gunakan Supabase Auth.
-   Terapkan authorization di backend/database.
-   Jangan mengandalkan route/UI guard saja.
-   Jangan expose secret key.
-   Gunakan anon/public key sesuai arsitektur Supabase.
-   Service-role key tidak boleh berada di aplikasi client.

## 23.4 Data Integrity

Database harus mencegah:

-   Duplicate attendance untuk student + session.
-   Conflict schedule untuk class + day + JP.
-   Invalid relationship antar data.
-   Data histori yang ikut terhapus akibat perubahan recurring schedule.

------------------------------------------------------------------------

# 24. Recommended Conceptual Data Model

> Bagian ini adalah acuan konseptual untuk Technical Planning. AI Agent
> tidak boleh langsung membuat database hanya berdasarkan asumsi apabila
> masih ada detail teknis yang belum ditentukan.

Entitas utama:

``` text
profiles
teachers
subjects
classes
students
lesson_periods / jp_config
schedules
sessions
attendance
journals
```

Relasi konseptual:

``` text
Teacher
   │
   ├── Schedules
   │       │
   │       ├── Subject
   │       ├── Class
   │       └── JP configuration
   │
   └── Sessions
           │
           ├── Attendance
           │       └── Student
           │
           └── Journal
```

## 24.1 Important Database Constraints

Konsep constraint yang harus dipertimbangkan:

### Attendance

``` text
UNIQUE(session_id, student_id)
```

### Schedule conflict

Konflik harus mencegah dua schedule menggunakan:

``` text
same day
+
same class
+
same JP
```

Jika satu schedule memakai JP 1--3, maka schedule lain tidak boleh
memakai JP 1, 2, atau 3 untuk kelas yang sama pada hari tersebut.

### Historical data

Session harus menyimpan konteks yang diperlukan agar histori tetap benar
meskipun:

-   Jadwal diubah.
-   Jadwal dihapus.
-   Siswa berpindah kelas.
-   Master data berubah.

Jangan membuat histori bergantung sepenuhnya pada kondisi master data
saat ini.

------------------------------------------------------------------------

# 25. Important Implementation Notes for AI Agent

## 25.1 Do Not Overengineer

Jangan otomatis membuat:

``` text
repositories/
services/
providers/
controllers/
usecases/
models/
utils/
helpers/
constants/
```

hanya karena mengikuti architecture pattern tertentu.

Gunakan struktur sederhana terlebih dahulu.

Target awal:

``` text
lib/
├── main.dart
├── splash_page.dart
├── login_page.dart
├── register_page.dart
└── dashboard_page.dart
```

File tambahan hanya dibuat apabila benar-benar diperlukan.

Jika penambahan file/abstraksi diperlukan, jelaskan alasannya sebelum
memperluas struktur.

## 25.2 Supabase Initialization

Inisialisasi Supabase tetap berada di:

``` text
lib/main.dart
```

Jangan memindahkannya ke architecture layer lain tanpa requirement yang
jelas.

## 25.3 Database First When Needed

Jika fitur membutuhkan tabel/kolom/database rule yang belum tersedia:

1.  Identifikasi dependency.
2.  Jangan membuat data dummy.
3.  Periksa struktur Supabase.
4.  Jika perlu, lakukan perubahan database melalui Supabase tooling/MCP
    yang tersedia.
5.  Pastikan RLS dan constraint sesuai business rules.
6.  Baru implementasikan UI/logic yang bergantung pada data tersebut.

## 25.4 UI Must Follow DESIGN.md

Sebelum mengimplementasikan UI:

1.  Baca `DESIGN.md`.
2.  Gunakan token/style yang sudah ditentukan.
3.  Jangan membuat design system baru jika tidak diperlukan.
4.  Jangan menggunakan gradient jika DESIGN.md melarangnya.
5.  Jangan menambahkan dekorasi hanya untuk membuat UI terlihat ramai.

## 25.5 Do Not Invent Requirements

Jika requirement belum ditentukan:

-   Jangan mengarang business rule.
-   Jangan mengubah workflow.
-   Jangan menambahkan fitur besar.
-   Tandai sebagai `OPEN QUESTION`.
-   Ajukan pertanyaan sebelum implementasi jika keputusan tersebut
    memengaruhi data model atau behavior.

------------------------------------------------------------------------

# 26. Error & Empty States

UI harus memiliki state yang jelas untuk:

-   Loading.
-   Empty data.
-   Network error.
-   Authentication error.
-   Permission denied.
-   Schedule conflict.
-   JP unavailable.
-   Attendance incomplete.
-   Session locked.
-   Session closed.
-   Account inactive.
-   Account deleted.
-   Database dependency missing.

Contoh:

``` text
JP tidak tersedia

JP 1–3 sudah digunakan untuk kelas ini
oleh jadwal lain.
Silakan pilih JP yang tersedia.
```

Contoh:

``` text
Presensi belum lengkap

Masih terdapat siswa yang belum memiliki
status presensi. Lengkapi seluruh presensi
sebelum sesi dapat diselesaikan.
```

------------------------------------------------------------------------

# 27. UX Rules for JP Selection

JP selector adalah komponen penting.

Contoh:

``` text
Hari: Senin
Kelas: XI PPLG

JP 1  🔒 Tidak tersedia
JP 2  🔒 Tidak tersedia
JP 3  🔒 Tidak tersedia
JP 4  ✓ Tersedia
JP 5  ✓ Tersedia
JP 6  ✓ Tersedia
JP 7  ✓ Tersedia
...
```

UI harus membuat alasan slot disabled mudah dipahami.

Jangan hanya membuat tombol disabled tanpa konteks.

Jika memungkinkan, tampilkan informasi bahwa slot tersebut sudah
digunakan pada kelas tersebut.

------------------------------------------------------------------------

# 28. Session UX

Ketika sesi `LOCKED`:

``` text
Sesi belum dimulai
Mulai: 10:00
```

Ketika `OPEN`:

``` text
Sesi sedang berlangsung
Sisa waktu: 32:14
```

Ketika `CLOSED`:

``` text
Sesi telah selesai
Presensi dan jurnal tidak dapat diubah.
```

Timer harus bersifat informatif.

Status session tetap ditentukan berdasarkan aturan waktu yang valid,
bukan hanya timer UI.

------------------------------------------------------------------------

# 29. Data Lifecycle

``` text
MASTER DATA
   │
   ├── Teacher
   ├── Subject
   ├── Class
   ├── Student
   └── JP
          │
          ↓
      SCHEDULE
          │
          ↓
   RECURRING OCCURRENCE
          │
          ↓
       SESSION
       /      \
      /        \
ATTENDANCE    JOURNAL
```

Perubahan master data tidak boleh merusak histori.

Contoh:

``` text
Schedule
   ↓
Session 1 → Attendance + Journal
Session 2 → Attendance + Journal
Session 3 → Attendance + Journal
```

Jika schedule dihapus:

``` text
Schedule → deleted
```

tetapi:

``` text
Session 1 → tetap
Session 2 → tetap
Session 3 → tetap
```

------------------------------------------------------------------------

# 30. Future Academic Year

Konsep Tahun Ajaran belum menjadi bagian MVP.

Contoh:

``` text
2026/2027
2027/2028
```

Akan ditambahkan/matangkan pada update mendatang.

AI Agent **tidak boleh memaksakan academic year sebagai business rule
utama MVP** tanpa requirement baru.

Namun desain database sebaiknya tidak dibuat sedemikian rupa sehingga
penambahan konsep tahun ajaran di masa depan menjadi sangat sulit.

------------------------------------------------------------------------

# 31. Development Priorities

Urutan implementasi:

``` text
1. Product requirements validation
2. Database/data model validation
3. Supabase Auth
4. Master data dependencies
5. Schedule + JP availability
6. Session lifecycle
7. Attendance
8. Journal
9. Admin review
10. UI/UX refinement
11. Testing
12. Deployment
```

Jangan melompat langsung ke fitur kompleks sebelum dependency sebelumnya
siap.

------------------------------------------------------------------------

# 32. Acceptance Criteria

## Authentication

-   [ ] User dapat register.
-   [ ] User dapat login.
-   [ ] User dapat login dengan Google.
-   [ ] Session Supabase dipertahankan.
-   [ ] Logout benar-benar sign out.
-   [ ] User inactive tidak dapat menggunakan aplikasi.
-   [ ] User deleted tidak dapat login.

## Profile

-   [ ] Guru dapat melengkapi nama lengkap.
-   [ ] Guru dapat memilih maksimal 2 mapel.
-   [ ] Mapel berasal dari master data.

## Schedule

-   [ ] Guru dapat membuat recurring schedule.
-   [ ] Guru tidak memasukkan waktu manual.
-   [ ] Sistem mengambil waktu dari JP configuration.
-   [ ] JP availability berdasarkan hari + kelas.
-   [ ] JP yang konflik otomatis disabled.
-   [ ] Backend menolak conflict schedule.
-   [ ] Guru dapat memilih beberapa JP berurutan.
-   [ ] Guru dapat edit schedule.
-   [ ] Guru dapat delete schedule.
-   [ ] Histori tidak ikut terhapus.

## Session

-   [ ] Session sebelum waktu mulai = LOCKED.
-   [ ] Session tepat pada waktu mulai = OPEN.
-   [ ] Session tepat pada waktu selesai = CLOSED.
-   [ ] Tidak ada manual Open/Close.
-   [ ] Closed session bersifat read-only untuk Guru.

## Attendance

-   [ ] Semua siswa mulai dari BELUM_DIISI.
-   [ ] Status tersedia: Hadir, Izin, Sakit, Alpa.
-   [ ] Satu siswa hanya punya satu status per session.
-   [ ] Attendance dapat diedit saat OPEN.
-   [ ] Attendance tidak dapat diedit setelah CLOSED.
-   [ ] Semua siswa wajib memiliki status.
-   [ ] Incomplete attendance menampilkan warning.

## Journal

-   [ ] Journal bersifat optional.
-   [ ] Journal dapat diisi saat OPEN.
-   [ ] Journal dapat diedit saat OPEN.
-   [ ] Journal read-only setelah CLOSED.
-   [ ] Journal kosong ditampilkan sebagai `-`.

## Admin Review

-   [ ] Admin dapat melihat data Guru.
-   [ ] Admin dapat mengelola status akun Guru.
-   [ ] Admin dapat melihat jadwal.
-   [ ] Admin dapat melihat presensi.
-   [ ] Admin dapat melihat jurnal.
-   [ ] Admin tidak mengubah presensi.
-   [ ] Admin tidak mengubah jurnal.

------------------------------------------------------------------------

# 33. Open Questions / Future Decisions

Requirement berikut belum final dan **tidak boleh ditebak oleh AI
Agent**:

1.  Detail lengkap field profil Guru selain nama lengkap dan maksimal 2
    mapel.
2.  Detail format master data siswa.
3.  Detail konfigurasi JP untuk setiap hari pada database.
4.  Detail mekanisme teknis session generation.
5.  Detail UX ketika presensi belum lengkap tepat pada batas waktu.
6.  Detail retention/reset histori dan kapan histori dianggap tidak lagi
    tersedia.
7.  Detail aturan penghapusan schedule yang sudah memiliki session.
8.  Detail permission Admin terhadap perubahan master data yang
    berdampak pada histori.
9.  Detail Tahun Ajaran.
10. Detail kebutuhan laporan/rekap lanjutan.

Jika keputusan tersebut diperlukan untuk implementasi, AI Agent harus
berhenti pada dependency tersebut dan meminta klarifikasi daripada
mengarang behavior.

------------------------------------------------------------------------

# 34. Source of Truth

Prioritas sumber kebenaran:

1.  **PRD.md ini** --- product/business requirements.
2.  **DESIGN.md** --- visual/UI/UX requirements.
3.  Supabase/database schema yang telah disetujui --- data
    implementation.
4.  Flutter technical implementation --- harus mengikuti requirement di
    atas.

Jika kode saat ini bertentangan dengan PRD:

> **Requirement/PRD harus dianggap sebagai target behavior, bukan kode
> lama.**

Namun jangan melakukan refactor besar-besaran tanpa memahami kondisi
project terlebih dahulu.

------------------------------------------------------------------------

# 35. Final Product Definition

Skola App pada MVP adalah aplikasi administrasi pembelajaran yang
memungkinkan Guru:

``` text
Login
 ↓
Lengkapi Profil
 ↓
Buat Jadwal
 ↓
Pilih Hari + Kelas + JP yang tersedia
 ↓
Jadwal Berulang
 ↓
Session Otomatis OPEN
 ↓
Presensi Siswa
 ↓
Jurnal Opsional
 ↓
Session CLOSED
 ↓
Data Menjadi Hasil Pembelajaran
 ↓
Admin Review
```

Sistem jadwal harus menjamin:

``` text
Hari + Kelas + JP
```

tidak dapat digunakan oleh lebih dari satu jadwal pada waktu yang sama.

Sistem sesi harus menjamin:

``` text
LOCKED → OPEN → CLOSED
```

berdasarkan waktu JP sekolah.

Sistem presensi harus menjamin:

``` text
1 Student + 1 Session = 1 Attendance Status
```

dan tidak boleh ada siswa yang selesai dengan status `BELUM_DIISI`.

Sistem jurnal harus tetap sederhana dan opsional.

Admin berfungsi sebagai **administrator dan reviewer**, bukan editor
hasil presensi/jurnal.

Tujuan akhir produk adalah membuat proses administrasi pembelajaran Guru
menjadi **lebih cepat, terstruktur, konsisten, dan mudah direview oleh
sekolah**, tanpa overengineering.
