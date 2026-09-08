# 📑 Naskah Presentasi — Final Project TRACK AI

> **Topik 1: AI untuk UMKM** — Pendekatan *Vibe Coding* dengan **Google AI Studio**
>
> File ini adalah naskah presentasi (teks per-slide) sesuai kerangka penilaian.
> Bagian yang bertanda **✍️** adalah data asli milikmu — isi/lengkapi sebelum dipakai.

---

## 1️⃣ Halaman Judul (Title Slide)

| Elemen | Isi |
|---|---|
| **Nama Usaha / Judul Proyek** | **Toko Doa Ibu** (Toko Listrik) × **Neobill** — *"AI Smart Bill & Business Assistant untuk UMKM"* |
| **Tagline** | Kasir Cepat, Stok Aman, Laporan Otomatis — Insight Bisnis dari AI |
| **Nama Lengkap Peserta** | ✍️ *[Nama lengkap kamu sebagai peserta]* |
| **Pendekatan** | Vibe Coding dengan **Google AI Studio** (Google Gemini + ML Kit) |

> **Saran narasi slide 1:**
> "Halo, perkenalkan nama saya ✍️ *[nama]*. Pada final project ini saya membangun **Neobill**,
> sebuah aplikasi kasir & asisten bisnis berbasis AI untuk UMKM, dengan studi kasus
> **Toko Doa Ibu**, toko listrik di ✍️ *[kota/lokasi]*. Aplikasi ini saya bangun dengan
> pendekatan *vibe coding* memanfaatkan **Google AI Studio**."

---

## 2️⃣ Profil UMKM

### UMKM Name
| Item | Keterangan |
|---|---|
| Nama usaha | **Toko Doa Ibu** |
| Jenis usaha | **Toko listrik** — menjual peralatan & perlengkapan listrik |
| Berdiri sejak | ✍️ *[tahun berdiri, mis. 2010]* |
| Lokasi | ✍️ *[kota/kecamatan + alamat lengkap, mis. Kediri, Jawa Timur]* |

### UMKM Type
| Item | Keterangan |
|---|---|
| Kategori usaha | Perdagangan / retail (non-makanan) — perlengkapan listrik |
| Skala usaha | **Usaha Mikro/Kecil** (UMKM) ✍️ *[jumlah karyawan, mis. pemilik + 1–2 pegawai]* |
| Kapasitas | ✍️ *[mis. melayani ± 20–50 transaksi/hari, ratusan jenis barang (SKU) di etalase & gudang]* |

### Products
| Item | Keterangan |
|---|---|
| Produk utama | Lampu & LED, kabel, stop kontak/saklar, fitting, MCB, kran & pompa air, kipas angin, perkakas listrik ✍️ *[sesuaikan dengan barang yang benar-benar dijual]* |
| Rentang harga | ✍️ *[mis. Rp 2.000 (fitting) – Rp 500.000 (pompa air/kabel rol)*]* |
| Cara penjualan saat ini | ✍️ *[mis. pembeli datang langsung (eceran), pesanan borongan tukang/kontraktor, pesan via WhatsApp]* |
| Pencatatan saat ini | ✍️ *[mis. buku jualan harian, nota tulis tangan]* |

### Target Market
| Item | Keterangan |
|---|---|
| Pelanggan utama | ✍️ *[mis. ibu rumah tangga, tukang listrik, kontraktor/borongan bangunan, toko/warung sekitar]* |
| Lokasi pelanggan | Sekitar toko + area proyek di ✍️ *[kota]* |
| Kebutuhan | Beli barang listrik untuk perbaikan/renovasi rumah & proyek — butuh barang tersedia, harga jelas, cepat dilayani |

### Current Business Condition
✍️ *[Tulis 3–5 kalimat kondisi asli. Contoh kerangka yang bisa dipakai:]*

> Toko Doa Ibu melayani ± ✍️ *[angka]* transaksi per hari dengan ratusan jenis barang.
> Pencatatan penjualan dan **stok masih manual di buku**, sehingga pemilik tidak tahu
> persis barang apa yang paling laku, barang mana yang sudah lama mengendap, dan berapa
> stok tersisa. Kadang barang habis saat pelanggan butuh (kehilangan omzet), sebaliknya
> barang lambat laku menumpuk dan mengikat modal. Rekap penjualan harian/bulanan juga
> menyita waktu di akhir hari, dan **keputusan belanja stok masih berdasarkan perkiraan,
> bukan data**.

---

## 3️⃣ Pernyataan Masalah (Problem Statement)

### Kalimat inti (1 kalimat)
> **Toko Doa Ibu tidak memiliki sistem pencatatan penjualan dan stok yang rapi untuk ratusan
> jenis barang listrik, sehingga pemilik kesulitan memantau stok, rekap harian menyita waktu,
> dan keputusan belanja barang diambil tanpa data penjualan yang akurat.**
> ✍️ *[boleh disesuaikan, tetap 1 kalimat]*

### Konteks masalah

| Poin | Penjelasan |
|---|---|
| **Apa yang terjadi saat ini** | Penjualan & stok dicatat manual; jumlah barang (SKU) sangat banyak sehingga rawan salah catat dan tidak terpantau. |
| **Mengapa ini menjadi masalah** | Barang bisa habis tanpa diketahui (kehilangan penjualan) atau menumpuk & modal terikat; rekap manual lambat dan rawan salah; pemilik tidak tahu barang paling laku/untung. |
| **Mengapa penting segera diselesaikan** | Persaingan toko listrik & toko material ketat; tanpa data, stok tidak efisien, arus kas terganggu, dan toko sulit berkembang atau mengambil keputusan (belanja, promo, barang baru). |

---

## 4️⃣ Solusi (Solution)

### Solusi
**Neobill** — aplikasi mobile **kasir digital + asisten bisnis AI** untuk UMKM yang dibangun
dengan pendekatan **vibe coding** menggunakan **Google AI Studio**:

- **Proses pengembangan (*vibe coding*):** ide, kode, dan perbaikan aplikasi disusun secara
  iteratif bersama asisten AI (Gemini di AI Studio) — dari prompt sederhana hingga aplikasi
  Flutter yang berfungsi penuh, tanpa harus menulis semua kode dari nol.
- **AI yang dipakai di dalam aplikasi:**
  - **Google ML Kit OCR (on-device)** — scan nota/struk dibaca otomatis (input barang lebih cepat, tanpa ketik manual).
  - **Google Gemini API (free tier AI Studio)** — koreksi cerdas hasil OCR (AI Smart Refine) dan
    menghasilkan **narasi insight bisnis** berbahasa Indonesia yang mudah dipahami pemilik UMKM.

#### Fitur utama (dipetakan ke kebutuhan Toko Doa Ibu)

| Fitur | Manfaat untuk Toko Doa Ibu |
|---|---|
| 🧾 **Kasir digital + OCR nota** | Input barang cepat (ketik nama/scan nota), total otomatis, dukung bayar Tunai/QRIS/transfer. |
| 📒 **Pencatatan transaksi otomatis** | Setiap penjualan tercatat otomatis — rekap harian/bulanan tanpa nulis manual lagi. |
| 📦 **Manajemen stok barang** | Stok ratusan SKU terpantau; ada **peringatan stok rendah/habis** + saran jumlah belanja ulang. |
| 📊 **Laporan & grafik penjualan** | Omzet harian/mingguan, barang terlaris, barang lambat laku, jam ramai — tampil otomatis. |
| 💡 **AI Business Insight** | Rekomendasi otomatis: barang terlaris, margin rendah, barang mengendap, prediksi omzet, deteksi kenaikan/penurunan — plus narasi dari **Gemini**. |
| 📄 **Export Laporan PDF** | Laporan penjualan & stok siap cetak/kirim (untuk pemilik, pembukuan, atau kebutuhan permodalan). |

### Manfaat dan Dampak
- **Kasir & layanan lebih cepat** — total langsung terhitung, pelanggan tidak menunggu lama.
- **Rekap harian jadi instan** — hemat waktu tutup toko (otomatis vs catat manual).
- **Stok lebih terkontrol** — tahu barang habis/menipis lebih dini, tidak kehabisan saat dibutuhkan & tidak boros belanja.
- **Barang mengendap terdeteksi** — barang lama bisa di-promo/di-disposal sehingga modal tidak terikat.
- **Keputusan berbasis data** — tahu barang terlaris, margin, dan kapan harus restock.
- **Biaya terjangkau** — AI memakai *free tier* Google AI Studio + OCR on-device; **tetap berfungsi offline** tanpa koneksi/API key (analisis lokal).
- **Melatih literasi digital** — pemilik UMKM terbiasa dengan data & teknologi sederhana.

### Indikator Keberhasilan
> ✍️ *[angka target — silakan disesuaikan dengan kondisi nyata Toko Doa Ibu]*

| Indikator | Baseline (sekarang) | Target (setelah pakai Neobill) | Waktu |
|---|---|---|---|
| Waktu satu transaksi di kasir | ± 3–5 menit manual | **< 1 menit** (input cepat) | 1 bulan |
| Waktu rekap penjualan harian | ± 60–120 menit | **< 5 menit** (otomatis) | Langsung |
| Akurasi catatan penjualan & stok | Rawan salah/tercecer | **100%** tercatat otomatis | Langsung |
| Kejadian stok habis tak terduga | ✍️ *[mis. 3–5×/bulan]* | **Mendekati 0** (ada peringatan dini) | 1–2 bulan |
| Barang lambat laku teridentifikasi | Tidak diketahui | Terdeteksi otomatis per bulan | 1 bulan |
| Kenaikan omzet | ✍️ *[baseline]* | **+10–20%** dalam 3 bulan | 3 bulan |
| Pengguna aktif harian | — | Pemilik & pegawai pakai **setiap hari buka** | 1 bulan |

---

## 5️⃣ Target Pengguna (Target User)

### Who?
| Item | Keterangan |
|---|---|
| Pengguna utama | **Pemilik Toko Doa Ibu** (pengambil keputusan & belanja stok) dan **pegawai kasir/toko** (operator harian) |
| Usia | ✍️ *[mis. pemilik 30–55 tahun, pegawai 18–35 tahun]* |
| Lokasi | ✍️ *[kota tempat toko beroperasi]* |
| Profil | Pelaku UMKM retail yang sibuk melayani pelanggan, akrab dengan smartphone & QRIS, tetapi belum memakai aplikasi kasir/pembukuan |

### Why?
| Kebutuhan | Mengapa butuh Neobill |
|---|---|
| Barang banyak, catatan manual tidak cukup | Semua penjualan & stok tercatat otomatis & rapi di HP |
| Tidak mau ribet rekap buku tiap malam | Laporan & omzet tersusun otomatis |
| Takut barang habis / tidak tahu stok | Peringatan stok rendah + saran belanja ulang |
| Ingin tahu barang paling laku & paling untung | AI kasih insight & rekomendasi langkah sederhana |

---

## 6️⃣ Penutup & Lampiran (Opsional)

### Halaman Penutup
> **Terima Kasih! 🙏**
> Toko Doa Ibu ✍️ *[nama peserta]* — TRACK AI: AI untuk UMKM
>
> *"UMKM naik kelas bukan karena tebak-tebakan, tapi karena keputusan berbasis data."*

### Lampiran (link yang bisa dilampirkan)
| Materi | Tautan |
|---|---|
| 🎬 Demo aplikasi (video/screen recording) | ✍️ *[tempel link YouTube/Drive]* |
| 📁 Repositori kode | ✍️ *[tempel link GitHub]* |
| 🧭 User journey / alur pengguna | ✍️ *[bisa lampirkan file/screenshot]* |
| 📚 Knowledge base (prompt vibe coding, dokumentasi) | ✍️ *[tempel link]* |
| 🖼 Screenshot tampilan | Terlampir di repositori (`screen*.png`, `s14–s17.png`) |

---

## 📝 Catatan Penggunaan

1. **Isi semua bagian ✍️** dengan data asli Toko Doa Ibu sebelum dipakai.
2. Naskah ini siap diubah menjadi **slide Canva** — 1 bagian utama = ±1–3 slide.
3. Bagian yang sudah akurat (fitur, alur, indikator) bisa langsung dipakai apa adanya.

> *Disusun untuk Final Project TRACK AI — Topik 1: AI untuk UMKM*
> *Aplikasi: **Neobill** (Flutter + Google ML Kit OCR + Google Gemini / AI Studio) — lihat `README.md` untuk dokumentasi teknis lengkap.*
