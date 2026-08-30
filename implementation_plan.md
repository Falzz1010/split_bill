# Implementation Plan — Transformasi Neobill ke AI Smart Bill & Business Assistant untuk UMKM F&B (TRACK AI)

Transformasi Neobill dari sekadar aplikasi *split bill* personal menjadi **"AI Smart Bill & Business Assistant untuk UMKM F&B"** guna memenuhi kriteria penilaian **Final Project TRACK AI (Topik 1 — AI untuk UMKM)**.

---

## 🎯 1. Re-Positioning & Skenario Kasus Bisnis UMKM

### 📌 Profil Kasus Nyata: *Warung Makan / Kedai Kopi Lokal (F&B UMKM)*
- **Nama Usaha Contoh**: Kedai Kopi & Resto Nusantara
- **Masalah Utama**:
  1. **Bottleneck Kasir pada Transaksi Rombongan**: Saat pelanggan makan bersama (3–8 orang) dan minta tagihan dipisah (*split bill* per orang / per menu), kasir menghitung manual dengan kalkulator dan memakan waktu 5-10 menit per meja.
  2. **Human Error Pajak & Service Charge**: Sering terjadi komplain pelanggan akibat salah membagi PPN 11% dan Service Charge secara manual.
  3. **Struk & Nota Fisik Sulit Direkap**: Kasir kesulitan merekap nota supplier / transaksi manual, sering salah baca teks nota kusut.
  4. **Nol Insight Bisnis Real-Time**: Pemilik UMKM tidak punya waktu menganalisis tren menu terlaris, pola pengeluaran pelanggan, atau rekomendasi harga.

### 💡 Solusi Neobill AI:
- **AI Smart OCR + Gemini 1.5/2.0 Flash Extraction**: Membaca foto struk dalam 2 detik, membetulkan salah baca OCR (*typo correction*), dan menyusun JSON terstruktur.
- **Fair Split Algorithm Engine**: Pembagian proporsional instan tanpa selisih (*largest remainder method*).
- **AI Business Insights for UMKM**: Gemini menganalisis riwayat transaksi dan memberikan rekomendasi bisnis cerdas (menu terlaris, efisiensi biaya, ide promo combo).
- **Digital Proof & Export**: Bukti rincian pembayaran siap kirim via WhatsApp dan cetak PDF struk.

---

## 🧠 2. Integrasi Google Gemini AI (Google AI Studio Free Tier)

Menambahkan layer kecerdasan buatan (GenAI) berbasis **Google Gemini API** yang melengkapi on-device ML Kit:

1. **Hybrid Architecture**:
   - **Mode Offline**: Google ML Kit Text Recognition (On-Device OCR cepat).
   - **Mode AI Enhanced**: Gemini 1.5 / 2.0 Flash API (Google AI Studio) untuk perbaikan teks cerdas, ekstraksi item rumit, auto-kategorisasi mendalam, dan deteksi anomali.
2. **Fitur AI Gemini**:
   - `GeminiReceiptRefiner`: Memperbaiki raw text OCR yang berantakan/buruk menjadi daftar item presisi.
   - `GeminiBusinessAdvisor`: Menganalisis riwayat transaksi UMKM dan menghasilkan ringkasan insight bisnis harian/bulanan.
   - `ApiKeyManager`: Pengguna/penguji dapat memasukkan Gemini API Key sendiri di Pengaturan atau menggunakan *fallback key/demo mode*.

---

## 📋 Proposed Changes

### Layer Core & Services

#### [NEW] `lib/core/services/gemini_service.dart`
- Client HTTP ke Google Gemini API (`gemini-1.5-flash` / `gemini-2.0-flash`).
- Method `refineReceiptWithAI(String rawOcrText, {String? imageBase64})` -> Menghasilkan `ParsedReceiptResult` dengan akurasi tinggi dan koreksi nama menu khas Indonesia.
- Method `generateBusinessInsights(List<SplitBill> splits)` -> Menghasilkan ringkasan analisis bisnis, tren pesanan, dan saran UMKM.

#### [MODIFY] `lib/core/settings/settings_service.dart`
- Tambah field preferensi: `geminiApiKey`, `useAiEnhancement` (boolean default true), `umkmMode` (boolean).

#### [MODIFY] `lib/core/utils/app_l10n.dart`
- Tambah terjemahan ID & EN untuk fitur AI Gemini, tombol AI Enhance, dan AI Business Insight Card.

---

### Layer Features & UI

#### [MODIFY] `lib/features/ocr_scanner/screens/ocr_result_preview_screen.dart`
- Tambah tombol **"✨ AI Smart Refine (Gemini)"** dengan status loading animasi.
- Fitur auto-koreksi menu dan harga menggunakan Gemini AI.

#### [MODIFY] `lib/features/dashboard/screens/dashboard_screen.dart`
- Tambah widget card **"💡 AI Business Insight (Asisten Cerdas UMKM)"** di Dashboard yang menampilkan analisis AI Gemini dari seluruh transaksi yang tercatat.

#### [MODIFY] `lib/features/pengaturan/screens/pengaturan_screen.dart`
- Tambah section **"🤖 Konfigurasi Google Gemini AI"** (Input API Key, Tes Koneksi AI, Toggle AI Auto-Refine).

#### [MODIFY] `README.md`
- Perbarui deskripsi, arsitektur AI (ML Kit + Gemini), use case bisnis UMKM F&B, dan alignment dengan rubrik penilaian **TRACK AI**.

---

## 🧪 Verification Plan

### Automated Verification
- Jalankan `flutter analyze` untuk memastikan tidak ada lint error atau type mismatch.
- Jalankan `flutter test` untuk memverifikasi logika model dan parser.

### Manual Verification
1. Masuk ke **Pengaturan** -> Masukkan/Uji Gemini API Key.
2. Buka **Scanner** -> Scan struk / pilih foto -> Buka **Preview OCR** -> Tap tombol **"✨ AI Smart Refine"** -> Verifikasi nama item & harga diperbaiki oleh Gemini.
3. Buka **Dashboard** -> Tap **"Analisis Transaksi dengan AI"** -> Verifikasi insight bisnis UMKM muncul dengan rekomendasi strategi.
