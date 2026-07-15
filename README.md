# SiPeBanjir - Sistem Peringatan Dini Potensi Titik Banjir

Sistem Peringatan Dini Potensi Titik Banjir Berdasarkan Durasi dan Curah Hujan Menggunakan Algoritma *K-Nearest Neighbor* (K-NN). Proyek ini merupakan Capstone Project Mahasiswa Program Studi Teknologi Rekayasa Perangkat Lunak, Politeknik Negeri Padang.

## 📌 Deskripsi Proyek
Banjir genangan akibat tingginya curah hujan merupakan permasalahan lingkungan yang sering mengganggu mobilitas masyarakat. Sistem ini dirancang untuk memprediksi potensi genangan air secara cepat dan efisien dengan memanfaatkan data historis cuaca (intensitas curah hujan dan durasi hujan) menggunakan algoritma **K-Nearest Neighbor (K-NN)**, sehingga masyarakat dapat melakukan mitigasi secara dini.

## 📂 Struktur Repositori
Repositori ini terdiri dari dua komponen utama:
*   📁 **[backend](./backend)**: Layanan backend yang mengimplementasikan pemrosesan data, prediksi menggunakan algoritma K-NN, dan API. Dibangun menggunakan Python.
*   📁 **[frontend](./frontend)**: Aplikasi mobile client yang digunakan oleh pengguna untuk melihat peta titik banjir, notifikasi, dan riwayat. Dibangun menggunakan Flutter (Dart).
*   📄 **[Laporan_Proyek_SiPeBanjir.md](./Laporan_Proyek_SiPeBanjir.md)**: Dokumen lengkap proposal dan laporan Capstone Project.

## 🚀 Cara Menjalankan Proyek

### 1. Backend (Python)
1. Masuk ke direktori backend:
   ```bash
   cd backend
   ```
2. Install dependensi yang dibutuhkan:
   ```bash
   pip install -r requirement.txt
   ```
3. Jalankan server backend:
   ```bash
   python app.py
   ```

### 2. Frontend (Flutter)
1. Masuk ke direktori frontend:
   ```bash
   cd frontend
   ```
2. Jalankan perintah untuk mengunduh dependensi:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi pada perangkat emulator/fisik:
   ```bash
   flutter run
   ```

---
**Penyusun:**
* **Rivelino Wahyu Rizky** (NIM. 2311081035)
* Program Studi Teknologi Rekayasa Perangkat Lunak, Jurusan Teknologi Informasi, Politeknik Negeri Padang.
