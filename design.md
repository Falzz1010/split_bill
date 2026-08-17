# 🎨 FairSplit — UI/UX Design System & Specification Document
> **Design Style:** Soft Neo-Brutalism (Playful, Vibrant, Bold Outlines, Offset Shadows)  
> **Reference Design:** Pet Care App Mockup (Neo-Brutalist aesthetic)

---

## 🎯 1. Konsep & Filosofi Desain

Aplikasi **FairSplit** mengadopsi gaya **Soft Neo-Brutalism**. Gaya ini menggabungkan:
- **Kemudahan Keterbacaan**: Kontras tinggi dengan border hitam tegas (`#1E1E1E`).
- **Elemen Playful & Friendly**: Sudut serba membulat (*rounded corners* 16px - 24px) dan palet warna krem hangat bersahabat.
- **Hard Offset Shadow**: Bayangan tegas 2D tanpa blur (`Offset(3, 3)`) yang membuat komponen terasa seperti tombol fisik/kartu yang timbul.
- **Kategorisasi Warna Ceria**: Setiap anggota, status tagihan, dan kategori menggunakan warna pastel bernyawa (*Vibrant Pastel*).

---

## 🎨 2. Design Tokens & Color Palette

### Primary & Background Colors
| Token Name | Color Hex | Visual | Penggunaan |
|---|---|---|---|
| `bgCream` | `#FAF6EE` | 🟡 Krem Murni | Background utama seluruh halaman |
| `cardWhite` | `#FFFFFF` | ⚪ Putih Solid | Background kartu utama & dialog |
| `borderBlack` | `#1E1E1E` | ⬛ Hitam Legam | Border (2.5px) & bayangan offset |
| `textPrimary` | `#18181B` | 🖤 Charcoal Hitam | Teks judul, label utama, angka harga |
| `textSecondary` | `#71717A` | 🩶 Abu-abu Muted | Subtitle, tanggal, teks pembantu |

### Vibrant Accent Colors (Neo-Brutalist Palette)
| Token Name | Color Hex | Visual | Penggunaan |
|---|---|---|---|
| `accentYellow` | `#FFCD00` | 💛 Yellow Gold | Tombol CTA Utama ("Split Sekarang", "Lihat Detail"), Card Active |
| `accentTeal` | `#2DD4BF` | 🩵 Turquoise Teal | Card Anggota, Status Selesai / Checked |
| `accentOrange` | `#FF7A59` | 🧡 Warm Coral | Card Anggota / Badge Kategori Makan |
| `accentLavender`| `#A5B4FC` | 💜 Soft Lavender | Badge Tambahan, Filter Active |
| `accentGreen` | `#22C55E` | 💚 Emerald Green | Status Lunas, Badge "Healthy / Normal" |
| `accentRed` | `#F87171` | 🔴 Soft Crimson | Status Belum Bayar, Tombol Hapus |

### Elevation & Shadows
- **Border Width:** `2.5 px` solid `#1E1E1E`
- **Box Shadow Offset:** `Offset(3, 3)` (tanpa blur / `blurRadius: 0`)
- **Border Radius:**
  - Card Utama: `20.0`
  - Tombol Pill / Search: `30.0`
  - Chip / Badge: `12.0` - `50.0`

---

## 🔤 3. Tipografi (Google Fonts: Outfit / Plus Jakarta Sans)

- **Headline Large (Judul Utama):** `Outfit` / `Plus Jakarta Sans`, 24pt, Bold (FontWeight.w800)
- **Headline Medium (Judul Kartu):** `Outfit`, 18pt, ExtraBold (FontWeight.w700)
- **Body Large (Teks Item/Harga):** `Plus Jakarta Sans`, 15pt, SemiBold (FontWeight.w600)
- **Body Small (Subtitle/Badge):** `Plus Jakarta Sans`, 12pt, Medium (FontWeight.w500)

---

## 🧩 4. Components Library (Widget Neo-Brutalist Flutter)

### A. Kartu Container Neo-Brutalist (`NeoCard`)
```dart
BoxDecoration(
  color: backgroundColor, // White / Yellow / Teal / Orange
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFF1E1E1E), width: 2.5),
  boxShadow: const [
    BoxShadow(
      color: Color(0xFF1E1E1E),
      offset: Offset(3, 3),
      blurRadius: 0,
    ),
  ],
)
```

### B. Tombol Utama Pill CTA (`NeoPillButton`)
```dart
Container(
  height: 52,
  decoration: BoxDecoration(
    color: const Color(0xFFFFCD00), // Yellow Accent
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: const Color(0xFF1E1E1E), width: 2.5),
    boxShadow: const [
      BoxShadow(
        color: Color(0xFF1E1E1E),
        offset: Offset(3, 3),
        blurRadius: 0,
      ),
    ],
  ),
  child: Center(
    child: Text(
      'View Full Profile / Split Sekarang',
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    ),
  ),
)
```

### C. Search Bar Pill (`NeoSearchBar`)
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Cari struk atau teman...',
    prefixIcon: Icon(Icons.search_rounded, color: Colors.black),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: Color(0xFF1E1E1E), width: 2.5),
    ),
  ),
)
```

---

## 📱 5. UI/UX Layout Screen Specifications

### 🏠 Screen 1: Dashboard / Home Screen (Adaptasi Lengkap Gambar Referensi)
Berdasarkan tata letak gambar referensi yang dikirim user:

```
+-------------------------------------------------------+
|  (Avatar)  Hi, Marko                [ + Struk Baru ]  |
|            Good morning.                              |
|                                                       |
|  [ 🔍 Cari struk atau riwayat...                  ]  |
|                                                       |
|  Split Aktif (3)                                      |
|  +--------------+  +--------------+  +-------------+  |
|  | (🧑) Oliver  |  | (👩) Luna    |  | (👨) Milo   |  |
|  |     Kopi Ken. |  |     Sushi    |  |     Padang  |  |
|  +--------------+  +--------------+  +-------------+  |
|     (Yellow Card)    (Teal Card)      (Orange Card)   |
|                                                       |
|  +-------------------------------------------------+  |
|  |  +-------+  Kopi Kenangan Senopati        ⋮     |  |
|  |  |       |  4 Anggota • F&B Resto               |  |
|  |  | 🧾    |  [ 📅 12 Mei 2024 ]                  |  |
|  |  +-------+  +---------------------------------+ |  |
|  |             | ✔️ Lunas (3/4 Anggota Transfer)  | |  |
|  |             +---------------------------------+ |  |
|  |                                                 |  |
|  |  +-------------+ +-------------+ +-----------+  |  |
|  |  | ⚖️ Total    | | 🧾 Items    | | 📅 Status |  |  |
|  |  | Rp 185.000  | | 6 Pesanan   | | 1 Pending |  |  |
|  |  | Proposional | | Terhitung   | | Tagihan   |  |  |
|  |  +-------------+ +-------------+ +-----------+  |  |
|  |                                                 |  |
|  |  [         Lihat Rincian Detail Split         ]  |  |
|  +-------------------------------------------------+  |
|                                                       |
|=======================================================|
|  🏠 Home    🔔 Reminders   (🧾 Scan)   💖 Health   ⚙️  |
+-------------------------------------------------------+
```

#### Komponen Utama Screen 1:
1. **Header Bar:**
   - Avatar Pengguna di lingkaran berborder hitam tebal.
   - Text Greeting: *"Halo, Marko 👋"* (Bold 18pt), subtitle *"Selamat Pagi"* (Muted 13pt).
   - Tombol Kanan Atas: Pill White Button `+ Struk Baru` dengan border 2.5px & bayangan hitam.
2. **Search Bar:**
   - Input pill memanjang dengan icon pencarian, background putih, border hitam 2.5px.
3. **Horizontal Split Selector ("Split Aktif (3)"):**
   - Kartu scrollable horizontal dengan warna beda-beda:
     - **Kartu 1 (Kuning `#FFCD00`):** Icon/Avatar, Nama "Oliver / Kopi Kenangan", Subtitle "Makan Bersama".
     - **Kartu 2 (Teal `#2DD4BF`):** Icon/Avatar, Nama "Luna / Sushi Tei", Subtitle "Pesta Ulang Tahun".
     - **Kartu 3 (Orange `#FF7A59`):** Icon/Avatar, Nama "Milo / RM Padang", Subtitle "Makan Siang Office".
4. **Primary Featured Split Card:**
   - Background Putih dengan border hitam tebal 2.5px & shadow `Offset(3, 3)`.
   - **Foto/Icon Struk:** Frame rounded square berborder hitam.
   - **Header Info:** Nama Resto/Split, Kategori, 3-dots menu icon.
   - **Badge Tanggal:** Pill Oranye lembut `📅 12 Mei 2024`.
   - **Badge Status Pelunasan:** Card hijau teal lembut dengan Icon Centang `✔️ Lunas (3 dari 4 Orang Transfer)`.
   - **3 Grid Stat Summary:**
     - Box 1 (Total Tagihan): Icon Timbangan/Uang, Nominal `Rp 185.000`, Badge Blue `Proposional`.
     - Box 2 (Items): Icon Jarum/Struk, Total `6 Item`, Badge Blue `Terhitung`.
     - Box 3 (Next Check/Status): Icon Kalender/Waktu, `1 Pending`, Badge Yellow `Menunggu`.
   - **Tombol CTA Kuning Memanjang:** Pill Button `#FFCD00` berteks bold *"Lihat Rincian Detail Split"*.
5. **Bottom Navigation Bar:**
   - Bar putih di bagian bawah dengan border atas hitam.
   - 5 Item Navigasi: Home (Active), Riwayat, **Floating Center Action Button (Icon Camera Scan Struk dengan Lingkaran Kuning Border Hitam Tebal)**, Ringkasan, Pengaturan.

---

### 📷 Screen 2: OCR Scanner & Camera View Screen
- **Camera Frame:** Area potret struk dengan garis pembatas kamera bergaris tebal hitam dan sudut rounded.
- **Scanning Animation:** Garis scan neon cyan berjalan naik-turun.
- **Control Bar:**
  - Tombol `Galeri` (Pill putih).
  - Tombol `Shutter Kamera` (Lingkaran Kuning besar berborder hitam tebal).
  - Tombol `Flash` (Pill putih).

---

### ✏️ Screen 3: Bill Item Editor Screen
- **Review List Struk:** Kartu-kartu item struk berlatar putih dengan border 2.5px.
- **Input Item:** Nama item di kiri, Jumlah (Qty) dengan stepper button `[-] [1] [+]`, dan harga di kanan dengan format `Rp`.
- **Tambahan Biaya Card (Tax, Service, Discount):**
  - Section khusus berlatar krem muda dengan opsi toggle switch untuk PPN (11%), Service Charge (5%), dan Diskon Nominal/Persen.

---

### 👥 Screen 4: Member Assignment Screen (Pembagian Pesanan)
- **Member Chips Header:** Baris horizontal chip nama teman berlatar warna pastel (Kuning, Teal, Orange, Purple) lengkap dengan avatar.
- **Interactive Checkbox Cards:**
  - Setiap item pesanan dapat di-tap untuk mencentang siapa saja anggota yang ikut makan/minum item tersebut.
  - Chip avatar anggota yang terpilih langsung muncul di kartu item (seperti badge Oliver/Luna pada gambar).

---

### 📊 Screen 5: Summary & Settlement Screen
- **Per-Person Breakdown Cards:** Kartu unik per anggota berlatar warna khas masing-masing (misal: Kartu Marko berlatar Kuning, Kartu Budi berlatar Teal).
- **Rincian Perhitungan:**
  - Subtotal Item
  - Bagian Pajak (Proposional)
  - Bagian Diskon (Proposional)
  - **Grand Total Tagihan Anggota** (Teks besar bold)
- **Tombol Action:**
  - Tombol Pill Hijau `📱 Bagikan ke WhatsApp` (Berisi teks tagihan yang tertata rapi).
  - Tombol Pill Biru `📄 Download PDF Struk`.

---

## 🛠️ 6. Panduan Implementasi Flutter Code

### Map Warna Tema ke `AppColors`
```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color bgCream = Color(0xFFFAF6EE);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderBlack = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF71717A);

  // Vibrant Accents
  static const Color accentYellow = Color(0xFFFFCD00);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentOrange = Color(0xFFFF7A59);
  static const Color accentLavender = Color(0xFFA5B4FC);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentRed = Color(0xFFF87171);
  static const Color cardCreamBg = Color(0xFFFFFDF5);
}
```

---

## 📝 Ringkasan Keselarasan dengan Gambar Referensi
1. **Header & User Profile:** Disesuaikan dari "Hi, Marko" pet app menjadi dashboard personal pengguna FairSplit.
2. **Horizontal Cards (Oliver, Luna, Milo):** Diadaptasi menjadi daftar *Split Aktif* / *Grup Makan* pengguna dengan warna-warna pastel cerah.
3. **Kartu Profil Utama (Oliver Profile Card):** Diadaptasi menjadi *Kartu Rincian Struk Utama* lengkap dengan badge status pelunasan, 3 boks ringkasan statistik (Total, Items, Status), dan tombol CTA Kuning memanjang.
4. **Bottom Bar Floating Avatar:** Diadaptasi menjadi Floating Scan Button untuk akses cepat kamera OCR.
