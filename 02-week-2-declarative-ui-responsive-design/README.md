# 1. Praktikum: Layout Sederhana (warm-up)
Praktikum ini membuat kartu profil sederhana sebagai berikut
<br><img src="./screenshots/Hasil_WarmUp.png" alt="Hasil WarmUp 0" width="50%">

## Eksperimen warm-up
1. **Hapus Expanded pada baris nama**
<br><img src="./screenshots/Hapus Expanded_WarmUp.png" alt="Hasil WarmUp 1" width="50%"><br>
Pada saat expanded di hapus pada baris nama yang terjadi adalah Text nama akan berada pada samping "Nama Mahasiswa" yang menyebabkan kalimat akan menembus layar dan memunculkan peringatan overflow

2. **Ganti mainAxisSize: MainAxisSize.min menjadi nilai default**
<br><img src="./screenshots/Hasil Nilai Default_WarmUp.png" alt="Hasil WarmUp 2" width="50%"><br>
Ketika mainAxisSize: MainAxisSize.min diganti menjadi nilai default terjadi perubahan pada tinggi kartu mulai dari atas hingga bawah layar.
3. **Tambahkan satu baris data**
<br><img src="./screenshots/Hasil add Email_WarmUp.png" alt="Hasil WarmUp 3" width="50%"><br>
Penambahan satu baris data yaitu informasi email pada kartu

# 2. Praktikum: dashboard responsif

## Persiapan Project
<br><img src="./screenshots/create responsive dashboard.png" alt="Persiapan Project" width="100%"><br>

## Stateless Widget
### Phone 5"
<img src="./screenshots/Hasil StatelessWidget Phone.png" alt="Stateless Widget Phone" width="50%"><br>

### Tablet 10"
<img src="./screenshots/Hasil StatelessWidgetTablet.png" alt="Stateless Widget Tablet" width="50%"><br>

## Menambahkan interaksi: StatefulWidget dan Cupertino
### Phone 5"
<img src="./screenshots/HasilStatefulWidgetdanCupertinoPhone.png" alt="Stateless Widget Tablet" width="50%"><br>

### Tablet 10"
<img src="./screenshots/HasilStatefulWidgetdanCupertinoTablet.png" alt="Stateless Widget Tablet" width="50%"><br>

### Eksperimen layout
1. **Ubah breakpoint**
<br> <img src="./screenshots/Breakpoint350Phone.png" alt="Stateless Widget Tablet" width="40%"> <img src="./screenshots/Breakpoint1000Tablet.png" alt="Stateless Widget Tablet" width="40%"> <br>
Perubahan dilakukan dengan mengubah breakpoint menjadi 350 pada phone 5" dan 1000 pada Tablet 10". Hasilnya menampilkan pada device phone dari yang awalnya menjadi 1 kolom menjadi 2 kolom, begitupula sebaliknya pada tablet dari yang 2 menjadi 1 kolom. 

2. **Ubah themeMode menjadi ThemeMode.dark**
<br> <img src="./screenshots/DarkmodePhone.png" alt="Stateless Widget Tablet" width="40%"> <img src="./screenshots/DarkmodeTablet.png" alt="Stateless Widget Tablet" width="40%"> <br>

3. **Uji aplikasi dengan ukuran layar emulator yang berbeda**
<br><img src="./screenshots/Flutter devices.png" alt="Stateless Widget Tablet" width="100%"><br>
Pengujian layar telah dilakukan pada dua layar berbeda yaitu Phone 5" dan Tablet 10" 

4. **Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader**
<br> Penambahan telah dilakukan pada kode di bagian tombol switch dan card

# 3. Tugas dan AI design exploration
## Tugas Utama
### Phone 5"
<img src="./screenshots/AcademicOverviewPhone.png" alt="Stateless Widget Tablet" width="50%"><br>

### Tablet 10"
<img src="./screenshots/AcademicOverviewTablet.png" alt="Stateless Widget Tablet" width="50%"><br>

Pengembangan dashboard diubah menjadi halaman Academic Overview dengan tambahan memiliki header profil dan empat kartu informasi. Serta Menampilkan satu kolom pada layar sempit dan dua kolom pada layar lebar. Pada bagian atas juga terdapat toggle tema untuk menyediakan light theme dan dark theme. Serta memiliki label aksesibilitas untuk informasi atau tombol penting.

## AI Prompt Challenge
1. Prompt desain."Bandingkan dua tata letak dashboard akademik untuk Flutter: versi GridView dan versi LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya."
<br><img src="./screenshots/Hasil_Prompt1.png" alt="Hasil Prompt1" width="40%"> <img src="./screenshots/Hasil_Prompt1.2.png" alt="Hasil Prompt1.2 Tablet" width="50%"><br>

**Kesimpulan** : 
- GridView: Praktis, efisien, dan ideal untuk kartu informasi yang seragam, namun kontrol posisinya terbatas dan berisiko terlalu sempit pada layar kecil.
- LayoutBuilder + Column: Sangat fleksibel dan responsif karena menggunakan breakpoint (misalnya $< 600$ px), sehingga lebih unggul dalam menjaga keterbacaan teks, area sentuh (tap target), dan aksesibilitas pada perangkat seluler.

2. Prompt penguatan konsep. "Jelaskan kapan penggunaan Expanded justru menyebabkan overflow di dalam Row, beri contoh kode yang gagal dan perbaikannya."
<br><img src="./screenshots/Hasil_Prompt2.png" alt="Hasil Prompt2" width="100%"> <img src="./screenshots/Hasil_Prompt2.2.png" alt="Hasil Prompt2.2 Tablet" width="45%"> <img src="./screenshots/Hasil_Prompt2.3.png" alt="Hasil Prompt2.3 Tablet" width="45%"><br> 

Kesimpulan : Widget Expanded berfungsi membagikan ruang yang tersedia, bukan menciptakan ruang baru. Oleh karena itu, penggunaan ukuran tetap (fixed width) yang berlebihan di dalamnya atau pemaksaan banyak kolom pada layar yang terlalu sempit akan memicu error overflow (RenderFlex).

3. Verification prompt. Minta AI mengaudit hasilnya sendiri: "Periksa kembali rekomendasi layout di atas: apakah tetap responsif di bawah 600px, apakah mengurangi aksesibilitas, dan apakah ada widget yang tidak tersedia di Flutter stabil saat ini?"
<br><img src="./screenshots/Hasil_Prompt3.png" alt="Hasil Prompt3" width="50%"> <img src="./screenshots/Hasil_Prompt3.2.png" alt="Hasil Prompt3.2 Tablet" width="45%"> <img src="./screenshots/Hasil_Prompt3.3.png" alt="Hasil Prompt3.3 Tablet" width="45%"> <img src="./screenshots/Hasil_Prompt3.4.png" alt="Hasil Prompt1.2 Tablet" width="50%"><br> 

Kesimpulan: 
- **Responsif di bawah 600 px**: Ya, tetap responsif. Penggunaan breakpoint di bawah 600 px yang mengubah susunan dari Row menjadi Column memastikan kartu tidak terlalu sempit atau terpotong pada perangkat seluler.

- **Aksesibilitas**: Tidak mengurangi aksesibilitas. Tata letak vertikal justru mempermudah pembacaan teks dan memberikan ruang yang lebih lega pada layar kecil, selama parameter seperti kontras, ukuran font, dan target sentuh tetap diperhatikan.

- **Ketersediaan Widget**: Semua widget tersedia di Flutter stabil. Seluruh komponen yang digunakan (LayoutBuilder, Row, Column, Expanded, GridView, dll.) merupakan bagian standar dari SDK Flutter tanpa memerlukan plugin tambahan.

## Checklist Verifikasi
- flutter analyze tidak menghasilkan error.
<br><img src="./screenshots/FlutterAnalyze.png" alt="Stateless Widget Tablet" width="100%"><br>

- flutter test lulus semua widget test responsif.

Saat menjalankan `flutter test`, test mengalami error `Bad state: Too many elements`. Setelah diperiksa, penyebabnya ada pada bagian `find.byType(Card)` di `widget_test.dart`.

Test tersebut menggunakan `tester.getSize(find.byType(Card))`, sedangkan pada implementasi dashboard saya terdapat 4 buah `Card`. Akibatnya `find.byType(Card)` menemukan lebih dari satu widget, sementara `getSize()` membutuhkan satu widget saja.

Untuk layout responsive-nya sendiri, saya menggunakan `LayoutBuilder` dengan breakpoint 700 px. Jika lebar layar kurang dari 700 px, `crossAxisCount` bernilai 1, sedangkan jika 700 px atau lebih, `crossAxisCount` bernilai 2.

Jadi error tersebut berasal dari cara test mencari `Card`, bukan karena `GridView` gagal mengatur responsive layout.

# 4. Refleksi dan referensi
### - Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?
Pada pendekatan imperatif, berfokus pada mengubah tampilan UI secara manual setiap kali ada perubahan data. Sedangkan pada pendekatan deklaratif, kode mendeskripsikan tampilan berdasarkan state saat ini. Ketika state berubah, Flutter membangun ulang bagian UI yang relevan. 

### - Kapan Expanded membantu dan kapan penggunaannya justru menghasilkan layout error?
Widget Expanded membantu ketika perlu membuat elemen di dalam Row, Column, atau Flex mengisi sisa ruang yang tersedia secara proporsional demi menciptakan tampilan yang responsif. Namun, penggunaannya justru akan menghasilkan error overflow jika anak di dalam Expanded dipaksa memiliki ukuran tetap (fixed constraints) yang melebihi kapasitas ruang sisa yang diberikan, atau ketika dipaksa berbagi ruang pada wadah yang terlalu sempit.

### - Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?
Breakpoint mengatur tata letak agar tetap rapi dan mudah diakses di berbagai ukuran layar, sementara theme menjaga konsistensi visual serta kenyamanan mata pengguna. Kombinasi keduanya menciptakan antarmuka yang adaptif dan menyenangkan di semua perangkat.

### - Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?
Memastikan responsivitas tata letak di bawah 600 px melalui peralihan Row ke Column, menjaga aksesibilitas seperti ukuran target sentuh, kontras, dan pembesaran teks, serta memvalidasi bahwa seluruh widget yang digunakan sepenuhnya tersedia di Flutter stable tanpa memerlukan plugin tambahan.

