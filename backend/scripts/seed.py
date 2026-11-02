"""
Skinly - Script Seed Data
Mengisi database dengan:
  - skin_type_info: deskripsi, karakteristik, rutinitas, & rekomendasi produk per jenis kulit
  - articles: minimal 8 artikel edukasi berbahasa Indonesia

Cara menjalankan (dari folder backend/):
  conda activate skinly
  python scripts/seed.py
"""
import sys
import os
import uuid
from datetime import datetime, timezone

# Tambah root backend ke sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import SessionLocal
from app.models.models import SkinTypeInfo, Article


def utcnow():
    return datetime.now(timezone.utc).replace(tzinfo=None)


# ============================================================
# DATA SKIN TYPE INFO
# ============================================================
SKIN_TYPE_DATA = {
    "normal": {
        "description": (
            "Kulit normal memiliki keseimbangan sebum yang baik, tidak terlalu berminyak "
            "dan tidak terlalu kering. Pori-pori umumnya kecil, tekstur kulit halus, "
            "dan jarang mengalami masalah jerawat atau iritasi. "
            "Jenis kulit ini paling mudah dirawat karena kondisinya sudah seimbang."
        ),
        "characteristics": [
            "Permukaan kulit halus dan lembut",
            "Pori-pori berukuran kecil",
            "Warna kulit merata dan cerah",
            "Jarang timbul jerawat",
            "Tidak mudah mengalami iritasi",
            "Tingkat kelembapan alami yang seimbang",
        ],
        "routine_morning": [
            {"step": "1", "name": "Pembersih Wajah", "detail": "Gunakan pembersih gentle berbahan surfaktan ringan (misalnya ceramide atau glycerin). Bersihkan dengan air hangat suam-suam."},
            {"step": "2", "name": "Toner", "detail": "Toner hydrating berbahan hyaluronic acid atau rose water untuk menyeimbangkan pH kulit."},
            {"step": "3", "name": "Serum", "detail": "Serum antioksidan dengan vitamin C atau niacinamide untuk proteksi dan pencerah."},
            {"step": "4", "name": "Pelembap", "detail": "Pelembap ringan (lotion atau gel) dengan kandungan ceramide atau hyaluronic acid."},
            {"step": "5", "name": "Sunscreen", "detail": "Sunscreen SPF 30 atau lebih setiap hari, meski cuaca mendung sekalipun."},
        ],
        "routine_night": [
            {"step": "1", "name": "Pembersih Wajah", "detail": "Cuci muka dengan pembersih gentle untuk mengangkat kotoran dan polutan."},
            {"step": "2", "name": "Toner", "detail": "Toner hydrating untuk mempersiapkan kulit menerima perawatan berikutnya."},
            {"step": "3", "name": "Serum / Treatment", "detail": "Retinol konsentrasi rendah (1-2x seminggu) atau serum niacinamide untuk menjaga kejernihan kulit."},
            {"step": "4", "name": "Pelembap Malam", "detail": "Pelembap berbahan ceramide atau peptide untuk regenerasi kulit selama tidur."},
        ],
        "recommended_products": [
            {"name": "Pembersih berbahan ceramide atau glycerin", "note": "Jaga kelembapan alami kulit"},
            {"name": "Pelembap ringan dengan hyaluronic acid", "note": "Hydrating tanpa rasa berat"},
            {"name": "Sunscreen mineral SPF 30+", "note": "Proteksi UV setiap hari"},
            {"name": "Serum vitamin C", "note": "Pencerah dan antioksidan"},
            {"name": "Retinol ringan (0.025%–0.05%)", "note": "Anti-aging, 1-2x seminggu"},
        ],
    },
    "oily": {
        "description": (
            "Kulit berminyak (oily) diproduksi akibat kelenjar sebaceous yang terlalu aktif, "
            "menghasilkan sebum berlebih. Kondisi ini membuat wajah terlihat mengkilap, "
            "terutama di area T-zone (dahi, hidung, dagu). Pori-pori cenderung besar dan "
            "rentan tersumbat sehingga mudah berjerawat. Meski begitu, kulit berminyak "
            "cenderung lebih lambat menua dibanding jenis kulit lainnya."
        ),
        "characteristics": [
            "Wajah terlihat mengkilap, terutama di area T-zone",
            "Pori-pori besar dan mudah terlihat",
            "Rentan berjerawat (blackhead, whitehead, pustul)",
            "Riasan mudah luntur",
            "Tekstur kulit terasa tebal",
            "Kulit terlihat kusam meski sudah dicuci",
        ],
        "routine_morning": [
            {"step": "1", "name": "Pembersih Wajah", "detail": "Gunakan pembersih berbahan salicylic acid (BHA 0.5%–2%) atau tea tree untuk mengontrol minyak."},
            {"step": "2", "name": "Toner", "detail": "Toner bebas alkohol dengan niacinamide atau witch hazel untuk menciutkan pori dan mengontrol sebum."},
            {"step": "3", "name": "Serum", "detail": "Serum niacinamide 10% untuk mengontrol produksi minyak dan memperkecil tampilan pori."},
            {"step": "4", "name": "Pelembap", "detail": "Pelembap gel berbahan ringan (oil-free) dengan hyaluronic acid. Hindari pelembap berbahan minyak berat."},
            {"step": "5", "name": "Sunscreen", "detail": "Sunscreen gel atau fluid (oil-free) SPF 50. Pilih formula matte finish."},
        ],
        "routine_night": [
            {"step": "1", "name": "Double Cleanse", "detail": "Micellar water atau cleansing balm untuk makeup/sunscreen, diikuti pembersih berbahan salicylic acid."},
            {"step": "2", "name": "Toner Exfoliating", "detail": "Toner dengan AHA (glycolic acid) atau BHA (salicylic acid) untuk eksfoliasi kimiawi ringan, 3x seminggu."},
            {"step": "3", "name": "Serum Treatment", "detail": "Serum retinol atau adapalene (retinoid) untuk mengontrol sebum dan mencegah pori tersumbat."},
            {"step": "4", "name": "Pelembap Malam", "detail": "Pelembap gel ringan atau sleeping mask non-comedogenic. Jangan lewatkan langkah ini meski kulit berminyak."},
        ],
        "recommended_products": [
            {"name": "Pembersih berbahan salicylic acid (BHA)", "note": "Membersihkan pori dari dalam"},
            {"name": "Toner niacinamide atau witch hazel", "note": "Kontrol minyak berlebih"},
            {"name": "Pelembap gel oil-free", "note": "Hydrating tanpa menambah minyak"},
            {"name": "Sunscreen formula matte/oil-control", "note": "SPF 50, tidak menyumbat pori"},
            {"name": "Masker kaolin atau bentonite clay", "note": "Serap minyak, bersihkan pori, 2x seminggu"},
        ],
    },
    "dry": {
        "description": (
            "Kulit kering (dry) terjadi ketika kulit tidak menghasilkan cukup sebum "
            "atau kehilangan kelembapan terlalu cepat. Kondisi ini menyebabkan kulit terasa "
            "kencang, kasar, bersisik, dan mudah teriritasi. Garis halus dan kerutan juga "
            "lebih mudah terlihat pada kulit kering. Perawatan utama berfokus pada hidrasi "
            "intens dan memperkuat skin barrier."
        ),
        "characteristics": [
            "Kulit terasa kencang atau tertarik, terutama setelah cuci muka",
            "Permukaan kulit kasar, bersisik, atau mengelupas",
            "Garis halus terlihat lebih jelas",
            "Mudah kemerahan dan iritasi",
            "Pori-pori kecil dan hampir tidak terlihat",
            "Kulit terlihat kusam dan kurang bercahaya",
        ],
        "routine_morning": [
            {"step": "1", "name": "Pembersih Lembut", "detail": "Gunakan milk cleanser atau cream cleanser berbahan ceramide. Hindari sabun berbusa keras atau yang mengandung SLS."},
            {"step": "2", "name": "Toner Hydrating", "detail": "Toner essence berbahan hyaluronic acid atau centella asiatica untuk lapisan kelembapan pertama."},
            {"step": "3", "name": "Serum Hydrating", "detail": "Serum hyaluronic acid berlapis (HA tinggi + rendah molekul) untuk hidrasi dalam dan luar."},
            {"step": "4", "name": "Pelembap Kaya", "detail": "Pelembap krim berbahan ceramide, squalane, shea butter, atau niacinamide untuk mengunci kelembapan."},
            {"step": "5", "name": "Sunscreen", "detail": "Sunscreen formula creamy atau dengan kandungan pelembap tambahan, SPF 30 atau lebih."},
        ],
        "routine_night": [
            {"step": "1", "name": "Pembersih Lembut", "detail": "Cleansing oil atau micellar water untuk angkat kotoran tanpa merusak skin barrier."},
            {"step": "2", "name": "Toner / Essence", "detail": "Toner atau essence berbahan fermentasi (galactomyces) untuk nutrisi kulit."},
            {"step": "3", "name": "Serum / Ampoule", "detail": "Serum peptide atau ceramide untuk memperkuat skin barrier dan regenerasi malam."},
            {"step": "4", "name": "Face Oil (opsional)", "detail": "Beberapa tetes facial oil (rosehip, argan) di atas serum untuk mengunci kelembapan."},
            {"step": "5", "name": "Pelembap Krim Malam", "detail": "Krim malam berbahan shea butter atau ceramide yang lebih kental dari pelembap pagi."},
        ],
        "recommended_products": [
            {"name": "Pembersih krim berbahan ceramide", "note": "Bersihkan tanpa merusak skin barrier"},
            {"name": "Serum hyaluronic acid berlapis", "note": "Hidrasi dalam dan luar"},
            {"name": "Pelembap krim kaya ceramide + squalane", "note": "Kunci kelembapan seharian"},
            {"name": "Sunscreen creamy SPF 30+", "note": "Perlindungan UV sekaligus melembapkan"},
            {"name": "Sleeping mask berbahan hyaluronic acid", "note": "Hidrasi ekstra saat tidur"},
        ],
    },
    "combination": {
        "description": (
            "Kulit kombinasi (combination) adalah jenis kulit yang paling umum. "
            "Area T-zone (dahi, hidung, dagu) cenderung berminyak dengan pori besar, "
            "sementara area pipi dan sekitar mata cenderung normal hingga kering. "
            "Perawatan kulit kombinasi memerlukan pendekatan yang lebih spesifik per area, "
            "atau menggunakan produk yang cukup seimbang untuk kedua kondisi."
        ),
        "characteristics": [
            "T-zone (dahi, hidung, dagu) berminyak dan mengkilap",
            "Area pipi normal atau kering",
            "Pori besar di area hidung dan dahi",
            "Rentan berjerawat di T-zone",
            "Pipi bisa terasa kencang setelah cuci muka",
            "Riasan luntur di T-zone lebih cepat",
        ],
        "routine_morning": [
            {"step": "1", "name": "Pembersih Gentle", "detail": "Pembersih berbahan glycerin atau centella asiatica - cukup gentle untuk pipi, cukup membersihkan untuk T-zone."},
            {"step": "2", "name": "Toner Balancing", "detail": "Toner bebas alkohol dengan niacinamide - menyeimbangkan minyak di T-zone tanpa mengeringkan pipi."},
            {"step": "3", "name": "Serum Niacinamide", "detail": "Niacinamide 5-10% untuk mengontrol sebum di T-zone dan mencerahkan secara keseluruhan."},
            {"step": "4", "name": "Pelembap Ringan", "detail": "Pelembap gel-cream yang cukup ringan untuk T-zone tapi cukup melembapkan untuk pipi."},
            {"step": "5", "name": "Sunscreen", "detail": "Sunscreen SPF 50, pilih formula fluid atau gel yang tidak membuat T-zone semakin berminyak."},
        ],
        "routine_night": [
            {"step": "1", "name": "Pembersih", "detail": "Pembersih gentle, jika ada makeup gunakan micellar water terlebih dahulu."},
            {"step": "2", "name": "Toner Exfoliating (3x/minggu)", "detail": "BHA 0.5-1% di T-zone, AHA di pipi untuk eksfoliasi merata tanpa iritasi."},
            {"step": "3", "name": "Serum Treatment", "detail": "Serum retinol ringan di seluruh wajah atau niacinamide setiap malam."},
            {"step": "4", "name": "Multi-masking (1-2x/minggu)", "detail": "Clay mask di T-zone, sleeping mask di area pipi secara bersamaan."},
            {"step": "5", "name": "Pelembap Malam", "detail": "Pelembap gel-cream ringan di seluruh wajah, tambahkan pelembap krim di area pipi yang lebih kering."},
        ],
        "recommended_products": [
            {"name": "Pembersih gentle berbahan glycerin atau centella", "note": "Seimbang untuk dua kondisi"},
            {"name": "Toner/serum niacinamide", "note": "Kontrol minyak tanpa mengeringkan"},
            {"name": "Pelembap gel-cream", "note": "Ringan untuk T-zone, cukup untuk pipi"},
            {"name": "Clay mask khusus T-zone", "note": "Serap minyak tanpa keringkan seluruh wajah"},
            {"name": "Sunscreen SPF 50 formula fluid", "note": "Ringan, tidak menyumbat pori"},
        ],
    },
}

# ============================================================
# DATA ARTIKEL EDUKASI (minimal 8 artikel)
# ============================================================
ARTICLES_DATA = [
    {
        "title": "Kenali 4 Jenis Kulit Wajah dan Ciri-cirinya",
        "category": "jenis_kulit",
        "summary": "Memahami jenis kulit adalah langkah pertama menuju rutinitas skincare yang tepat. Kenali perbedaan kulit normal, berminyak, kering, dan kombinasi.",
        "content": """## Kenali 4 Jenis Kulit Wajah

Setiap orang memiliki jenis kulit yang berbeda-beda, dan memahami jenis kulitmu adalah fondasi dari rutinitas perawatan kulit yang efektif.

### 1. Kulit Normal
Kulit normal adalah jenis kulit yang paling ideal. Kulit ini memiliki keseimbangan antara produksi sebum dan kelembapan yang baik. Ciri-cirinya:
- Permukaan halus dan lembut
- Pori-pori kecil
- Tidak mudah berjerawat
- Jarang iritasi

### 2. Kulit Berminyak (Oily)
Kulit berminyak terjadi ketika kelenjar sebaceous memproduksi sebum secara berlebihan. Ciri-cirinya:
- Wajah mengkilap, terutama di area T-zone
- Pori-pori besar dan terlihat jelas
- Rentan blackhead dan jerawat

### 3. Kulit Kering (Dry)
Kulit kering kekurangan kelembapan alami atau produksi sebum yang kurang. Ciri-cirinya:
- Terasa kencang setelah cuci muka
- Mudah bersisik atau mengelupas
- Garis halus lebih terlihat
- Sering kemerahan

### 4. Kulit Kombinasi (Combination)
Kulit kombinasi memiliki dua kondisi sekaligus: T-zone berminyak dan area pipi normal atau kering. Ini adalah jenis kulit yang paling umum ditemui.

## Cara Mengetahui Jenis Kulitmu
Cuci muka dan tunggu 1 jam tanpa mengaplikasikan produk apapun. Perhatikan:
- Seluruh wajah nyaman → **Kulit Normal**
- Seluruh wajah mengkilap → **Kulit Berminyak**
- Wajah terasa kencang dan kasar → **Kulit Kering**
- T-zone mengkilap, pipi normal/kering → **Kulit Kombinasi**

Atau gunakan aplikasi Skinly untuk hasil yang lebih akurat menggunakan teknologi kecerdasan buatan!
""",
        "read_minutes": 4,
    },
    {
        "title": "Cara Merawat Kulit Berminyak agar Tidak Kusam",
        "category": "jenis_kulit",
        "summary": "Kulit berminyak bukan berarti tidak perlu dilembapkan. Pelajari rutinitas perawatan yang tepat untuk kulit oily agar tetap sehat dan cerah.",
        "content": """## Merawat Kulit Berminyak dengan Tepat

Salah kaprah terbesar dalam merawat kulit berminyak adalah menghindari pelembap karena takut semakin berminyak. Padahal, kulit yang kekurangan kelembapan justru akan memproduksi lebih banyak minyak sebagai kompensasi!

### Prinsip Dasar Kulit Berminyak
1. **Bersihkan dengan benar** - Gunakan pembersih berbahan BHA (salicylic acid) yang bisa masuk ke dalam pori
2. **Tetap pakai pelembap** - Pilih formula gel atau water-based, bukan krim berbahan minyak berat
3. **Eksfoliasi rutin** - 2-3x seminggu menggunakan AHA atau BHA

### Bahan Aktif yang Direkomendasikan
- **Salicylic Acid (BHA)**: Membersihkan pori dari dalam, ideal untuk kulit berminyak berjerawat
- **Niacinamide**: Mengontrol produksi sebum sekaligus mencerahkan wajah
- **Clay (Kaolin/Bentonite)**: Menyerap minyak berlebih tanpa mengiritasi
- **Hyaluronic Acid**: Memberikan hidrasi ringan tanpa menambah minyak

### Ingredients yang Sebaiknya Dihindari
- Mineral oil dan minyak berat lainnya
- Petrolatum dalam jumlah besar
- Alkohol konsentrasi tinggi (mengeringkan tapi memicu produksi minyak lebih)

### Tips Sehari-hari
- Gunakan facial blotting paper untuk menyerap minyak berlebih di siang hari
- Pilih sunscreen formula matte atau gel
- Ganti sarung bantal setiap 2-3 hari untuk mencegah bakteri penyebab jerawat
""",
        "read_minutes": 5,
    },
    {
        "title": "Rutinitas Skincare untuk Kulit Kering: Hidrasi Berlapis",
        "category": "jenis_kulit",
        "summary": "Kulit kering membutuhkan hidrasi yang intens dan perlindungan skin barrier. Pelajari metode skincare berlapis untuk kulit kering yang optimal.",
        "content": """## Skincare untuk Kulit Kering: Metode Layering

Kulit kering membutuhkan pendekatan yang berbeda: fokus pada hidrasi berlapis-lapis dan memperkuat skin barrier.

### Memahami Skin Barrier
Skin barrier adalah lapisan pelindung terluar kulit yang terdiri dari lipid (ceramide, fatty acid, cholesterol). Kerusakan skin barrier menyebabkan kulit kehilangan kelembapan lebih cepat.

### Teknik "Sandwich" untuk Kulit Kering
Oleskan produk dari yang paling ringan hingga paling berat:
1. Toner/essence berbahan hydrating
2. Serum hyaluronic acid (HA)
3. Pelembap krim berbahan ceramide
4. Face oil (opsional, untuk mengunci semua lapisan)

### Bahan Aktif Terbaik untuk Kulit Kering
- **Hyaluronic Acid**: Menarik dan mengikat air ke dalam kulit
- **Ceramide**: Memperkuat skin barrier
- **Squalane**: Pelembap ringan yang mirip sebum alami kulit
- **Glycerin**: Humektan yang menarik kelembapan dari udara
- **Shea Butter**: Oklusif yang mengunci kelembapan

### Hal yang Perlu Dihindari
- Pembersih wajah berbahan SLS yang keras
- Air panas saat mencuci muka (gunakan air suam-suam)
- Produk mengandung alkohol tinggi
- Menggaruk atau mengusap wajah terlalu keras

### Tips Tambahan
- Gunakan humidifier di kamar tidur
- Minum air putih minimal 8 gelas sehari
- Konsumsi makanan kaya omega-3 (ikan salmon, alpukat, kacang-kacangan)
""",
        "read_minutes": 5,
    },
    {
        "title": "Jerawat: Penyebab, Jenis, dan Cara Mengatasinya",
        "category": "masalah_kulit",
        "summary": "Jerawat adalah masalah kulit paling umum. Kenali berbagai jenis jerawat dan pendekatan perawatan yang tepat untuk setiap jenisnya.",
        "content": """## Memahami Jerawat secara Komprehensif

Jerawat (acne vulgaris) adalah kondisi peradangan pada folikel rambut dan kelenjar sebaceous. Hampir 85% orang pernah mengalaminya setidaknya sekali dalam hidup.

### Penyebab Utama Jerawat
1. **Produksi sebum berlebih** - Membuat pori lebih mudah tersumbat
2. **Sel kulit mati** - Menumpuk di pori dan menyumbat jalan keluar sebum
3. **Bakteri C. acnes** - Berkembang biak di lingkungan anaerobik dalam pori tersumbat
4. **Peradangan** - Respons imun tubuh terhadap bakteri

### Jenis-jenis Jerawat
**Non-inflamasi (tidak meradang):**
- **Komedo terbuka (blackhead)** - Pori tersumbat yang teroksidasi, berwarna hitam
- **Komedo tertutup (whitehead)** - Pori tersumbat yang tertutup

**Inflamasi (meradang):**
- **Papul** - Benjolan merah, terasa nyeri
- **Pustul** - Berisi nanah di puncaknya
- **Nodul** - Lebih besar dan dalam, lebih nyeri
- **Kista** - Terbesar, berisi nanah, berisiko meninggalkan bekas

### Bahan Aktif Anti-Jerawat
| Bahan | Fungsi |
|-------|--------|
| Salicylic Acid | Eksfoliasi dalam pori, anti-inflamasi |
| Benzoyl Peroxide | Membunuh bakteri C. acnes |
| Retinol/Retinoid | Percepat pergantian sel, mencegah pori tersumbat |
| Niacinamide | Kurangi peradangan, kontrol sebum |
| Tea Tree Oil | Antimikroba alami |

### Kapan Harus ke Dokter Kulit?
- Jerawat tidak membaik setelah 2-3 bulan perawatan mandiri
- Jerawat nodular atau kistik yang besar dan nyeri
- Jerawat meninggalkan bekas permanen
- Jerawat disertai gejala hormonal lain

*Catatan: Konsultasikan selalu ke dokter kulit untuk masalah kulit serius.*
""",
        "read_minutes": 6,
    },
    {
        "title": "Hiperpigmentasi: Kenapa Kulit Bisa Belang?",
        "category": "masalah_kulit",
        "summary": "Flek hitam, bekas jerawat, dan melasma adalah bentuk hiperpigmentasi yang umum. Pelajari penyebab dan cara mengatasinya dengan bahan aktif yang tepat.",
        "content": """## Hiperpigmentasi: Penyebab dan Solusinya

Hiperpigmentasi adalah kondisi di mana area tertentu pada kulit menjadi lebih gelap dari warna kulit sekitarnya karena produksi melanin berlebih.

### Jenis-jenis Hiperpigmentasi
1. **Post-Inflammatory Hyperpigmentation (PIH)** - Bekas jerawat atau luka yang meninggalkan noda gelap
2. **Melasma** - Bercak cokelat yang umumnya terkait hormon (kehamilan, pil KB)
3. **Solar Lentigines** - Flek hitam akibat paparan sinar matahari berlebih (age spots)
4. **Freckles** - Titik-titik kecil cokelat akibat faktor genetik + paparan UV

### Proses Terbentuknya Hiperpigmentasi
Paparan UV, inflamasi, atau perubahan hormonal merangsang melanosit (sel penghasil melanin) untuk memproduksi melanin lebih banyak. Melanin menumpuk di lapisan kulit dan tampak sebagai noda gelap.

### Bahan Aktif Pencerah yang Efektif
- **Vitamin C (L-Ascorbic Acid)**: Menghambat enzim tirosinase, antioksidan terhadap UV
- **Niacinamide**: Menghambat transfer melanin ke sel kulit
- **Alpha Arbutin**: Turunan hydroquinone yang lebih aman dan stabil
- **Tranexamic Acid**: Efektif untuk melasma
- **AHA (Glycolic/Lactic Acid)**: Eksfoliasi untuk mempercepat regenerasi kulit
- **Retinol**: Mempercepat pergantian sel kulit

### Tips Mencegah Hiperpigmentasi
- **Sunscreen setiap hari** - Ini yang paling penting! UV adalah pemicu utama
- Jangan memencet jerawat (bisa memperparah PIH)
- Gunakan produk pencerah secara konsisten
- Sabar - proses pencerah bisa butuh 2-3 bulan

*Ingat: Hasil ini bersifat estimasi dan bukan diagnosis medis. Konsultasikan ke dokter kulit untuk masalah kulit serius.*
""",
        "read_minutes": 5,
    },
    {
        "title": "Pentingnya Sunscreen: Mengapa Harus Dipakai Setiap Hari?",
        "category": "perawatan",
        "summary": "Sunscreen adalah langkah paling penting dalam rutinitas skincare. Pelajari cara memilih dan menggunakan sunscreen yang tepat untuk perlindungan optimal.",
        "content": """## Sunscreen: Investasi Terbaik untuk Kulitmu

Jika kamu hanya bisa memilih SATU produk skincare, pilih sunscreen. Penelitian menunjukkan bahwa 80% tanda-tanda penuaan kulit disebabkan oleh paparan sinar UV.

### Memahami Sinar UV
- **UV-A**: Menembus awan dan kaca, menyebabkan penuaan dini, hiperpigmentasi
- **UV-B**: Penyebab utama sunburn, berkontribusi pada kanker kulit
- **UV-C**: Terblokir atmosfer bumi, tidak sampai ke kulit

### Perbedaan SPF dan PA
- **SPF (Sun Protection Factor)**: Ukuran perlindungan terhadap UV-B. SPF 30 memblokir ~97%, SPF 50 memblokir ~98%
- **PA (Protection Grade of UVA)**: Ukuran perlindungan terhadap UV-A. Dilambangkan PA+, PA++, PA+++, PA++++

Untuk perlindungan optimal, pilih sunscreen dengan minimal **SPF 30** dan **PA++** atau lebih.

### Chemical vs Mineral Sunscreen
**Chemical Sunscreen:**
- Menyerap UV dan mengubahnya menjadi panas
- Formula lebih ringan dan mudah meresap
- Cocok untuk kulit normal hingga berminyak

**Mineral Sunscreen (fisik):**
- Memantulkan sinar UV dari permukaan kulit
- Bahan aktif: zinc oxide, titanium dioxide
- Lebih cocok untuk kulit sensitif atau berjerawat

### Cara Pemakaian yang Benar
1. Aplikasikan sunscreen sebagai langkah terakhir sebelum makeup (setelah pelembap)
2. Gunakan **2 sendok teh** untuk seluruh wajah dan leher
3. Oleskan 15-30 menit sebelum keluar
4. **Reapply setiap 2 jam** saat beraktivitas di luar ruangan

### Mitos Sunscreen yang Perlu Diluruskan
- ❌ "Cuaca mendung berarti tidak perlu sunscreen" → UV tetap menembus awan
- ❌ "Kulit gelap tidak perlu sunscreen" → Semua jenis kulit butuh proteksi UV
- ❌ "Sunscreen di dalam ruangan tidak perlu" → UV-A menembus kaca jendela
""",
        "read_minutes": 6,
    },
    {
        "title": "Exfoliasi: Kunci Kulit Cerah dan Bebas Pori Tersumbat",
        "category": "perawatan",
        "summary": "Eksfoliasi yang tepat dapat mentransformasi tampilan kulit. Pelajari perbedaan exfoliasi fisik dan kimiawi, serta frekuensi yang aman untuk kulitmu.",
        "content": """## Panduan Lengkap Eksfoliasi Kulit

Kulit manusia mengalami regenerasi setiap 28-40 hari. Sel kulit mati yang menumpuk di permukaan membuat kulit terlihat kusam, pori tersumbat, dan produk skincare sulit meresap.

### Dua Jenis Eksfoliasi

#### 1. Eksfoliasi Fisik (Scrub)
Menggunakan butiran halus atau alat untuk mengangkat sel kulit mati secara mekanis.
- Contoh: scrub gula, microbeads, sikat wajah, konjac sponge
- **Pro**: Hasilnya instan dan terasa langsung
- **Kontra**: Berisiko iritasi jika terlalu kasar atau terlalu sering

#### 2. Eksfoliasi Kimiawi (Chemical Exfoliant)
Menggunakan asam untuk melarutkan ikatan antar sel kulit mati.

**AHA (Alpha Hydroxy Acid) - untuk permukaan:**
- Glycolic Acid: Terkecil, meresap paling dalam
- Lactic Acid: Lebih lembut, cocok kulit sensitif/kering
- Mandelic Acid: Paling lembut, cocok pemula

**BHA (Beta Hydroxy Acid) - untuk dalam pori:**
- Salicylic Acid: Oil-soluble, masuk ke dalam pori
- Ideal untuk kulit berminyak dan berjerawat

**PHA (Polyhydroxy Acid) - paling lembut:**
- Gluconolactone, Lactobionic Acid
- Cocok kulit sangat sensitif atau rosacea

### Frekuensi Eksfoliasi yang Disarankan
| Jenis Kulit | Frekuensi |
|-------------|-----------|
| Normal | 2-3x seminggu |
| Berminyak | 3x seminggu |
| Kering | 1-2x seminggu |
| Sensitif | 1x seminggu atau kurang |

### Tanda Over-Exfoliasi
Jika kulit mengalami kemerahan berlebihan, rasa terbakar, kulit terkelupas, atau justru semakin sensitif, kemungkinan kamu over-exfoliasi. Istirahatkan kulitmu selama 1-2 minggu.

### Tips Penting
- Selalu gunakan sunscreen setelah eksfoliasi (kulit lebih sensitif terhadap UV)
- Jangan gabungkan multiple exfoliant sekaligus
- Mulai dengan konsentrasi rendah, tingkatkan bertahap
""",
        "read_minutes": 5,
    },
    {
        "title": "Skin Barrier: Mengapa Ini adalah Rahasia Kulit Sehat",
        "category": "perawatan",
        "summary": "Skin barrier yang sehat adalah fondasi kulit yang cantik. Pelajari apa itu skin barrier, penyebab kerusakannya, dan cara memperbaikinya.",
        "content": """## Skin Barrier: Pelindung Utama Kulitmu

Skin barrier, atau yang dikenal secara ilmiah sebagai stratum corneum, adalah lapisan terluar kulit yang berfungsi sebagai "perisai" untuk melindungi tubuh dari ancaman luar sekaligus menjaga kelembapan di dalam.

### Struktur Skin Barrier
Skin barrier terdiri dari sel kulit mati (korneosit) yang "diikat" oleh lipid, mirip seperti batu bata dan semen. Lipid ini terdiri dari:
- Ceramide (50%)
- Kolesterol (25%)
- Asam lemak bebas (15-20%)

Ketika komposisi lipid ini terganggu, kulit menjadi "bocor" - air mudah menguap dan iritan mudah masuk.

### Tanda-tanda Skin Barrier Rusak
- Kulit kering, bersisik, atau mengelupas
- Kemerahan atau iritasi yang tidak biasa
- Kulit terasa "terbakar" saat aplikasikan produk
- Jerawat yang muncul tiba-tiba
- Kulit sensitif terhadap produk yang biasanya cocok

### Penyebab Kerusakan Skin Barrier
1. **Over-exfoliasi** - Terlalu sering eksfoliasi melarutkan lipid pelindung
2. **Produk terlalu keras** - Sabun berbahan SLS tinggi
3. **Faktor lingkungan** - Angin, udara kering, polusi
4. **Paparan UV berlebih**
5. **Stres dan kurang tidur**
6. **Kondisi kulit tertentu** - Eksim (eczema), psoriasis

### Cara Memperbaiki Skin Barrier
**Langkah 1: Sederhanakan rutinitas**
Kurangi jumlah produk dan bahan aktif sementara. Fokus pada pembersih lembut + pelembap + sunscreen.

**Langkah 2: Gunakan bahan aktif reparasi**
- **Ceramide**: Mengganti lipid yang hilang
- **Cholesterol**: Komponen penting skin barrier
- **Niacinamide**: Meningkatkan produksi ceramide alami
- **Centella Asiatica (Cica)**: Anti-inflamasi, mempercepat penyembuhan
- **Panthenol (Pro-Vitamin B5)**: Menenangkan dan melembapkan

**Langkah 3: Bersabar**
Skin barrier membutuhkan waktu 2-4 minggu untuk pulih. Konsistensi adalah kuncinya.

*Ingat: Untuk kondisi kulit yang serius seperti eczema atau psoriasis, konsultasikan ke dokter kulit.*
""",
        "read_minutes": 6,
    },
    {
        "title": "Retinol: Bahan Ajaib Anti-Aging yang Perlu Kamu Tahu",
        "category": "perawatan",
        "summary": "Retinol adalah salah satu bahan aktif paling terbukti ilmiah untuk anti-aging. Pelajari cara penggunaannya yang aman untuk pemula.",
        "content": """## Panduan Penggunaan Retinol untuk Pemula

Retinol adalah derivat Vitamin A yang telah menjadi bahan skincare paling banyak diteliti dan terbukti efektif untuk berbagai masalah kulit.

### Manfaat Retinol yang Terbukti Ilmiah
1. **Anti-aging**: Merangsang produksi kolagen, mengurangi kerutan
2. **Anti-jerawat**: Mencegah pori tersumbat, mempercepat regenerasi sel
3. **Pencerah**: Memudarkan hiperpigmentasi dan noda gelap
4. **Perbaikan tekstur**: Kulit lebih halus dan merata

### Hirarki Kekuatan Retinoid
Dari yang paling lemah hingga terkuat:
1. **Bakuchiol** - Alternatif alami, lebih lembut
2. **Retinol** (0.025% - 1%) - Tersedia bebas, untuk pemula
3. **Retinaldehyde** - Lebih efektif, kurang iritasi
4. **Retinyl Retinoate** - Efisiensi tinggi, iritasi minimal
5. **Tretinoin (Retinoic Acid)** - Resep dokter, paling kuat

### Cara Memulai Retinol dengan Aman
**Metode "Sandwich"** (untuk pemula/kulit sensitif):
1. Aplikasikan pelembap terlebih dahulu
2. Aplikasikan retinol di atas pelembap
3. Tutup dengan pelembap lagi

**Jadwal Memulai:**
- Minggu 1-2: 1x seminggu
- Minggu 3-4: 2x seminggu
- Bulan 2: 3x seminggu
- Bulan 3+: Setiap malam (jika kulit toleran)

### Efek Samping Normal (Retinization)
Saat pertama menggunakan retinol, kulit bisa mengalami:
- Kemerahan ringan
- Kulit mengering atau mengelupas
- Sensasi hangat atau perih ringan

Ini normal dan biasanya berkurang dalam 4-6 minggu.

### Yang Harus Dihindari Saat Pakai Retinol
- Jangan kombinasikan dengan vitamin C, AHA/BHA di waktu yang sama
- Jangan gunakan saat hamil atau menyusui
- Selalu pakai sunscreen di pagi hari - kulit menjadi lebih sensitif UV

*Konsultasikan ke dokter kulit sebelum menggunakan retinol jika memiliki kondisi kulit tertentu.*
""",
        "read_minutes": 6,
    },
    {
        "title": "Kulit Kombinasi: Tips Merawat Dua Kondisi Sekaligus",
        "category": "jenis_kulit",
        "summary": "Merawat kulit kombinasi memerlukan strategi khusus. Pelajari teknik multi-masking dan pilihan produk yang tepat untuk kedua zona kulitmu.",
        "content": """## Strategi Cerdas Merawat Kulit Kombinasi

Kulit kombinasi adalah jenis kulit yang paling umum, namun juga yang paling membingungkan untuk dirawat. T-zone (dahi-hidung-dagu) berminyak sementara pipi normal atau kering membutuhkan pendekatan yang berbeda.

### Memahami Pola Kulitmu
Sebelum memilih produk, petakan kondisi kulitmu:
- Di mana area berminyak? (biasanya T-zone)
- Di mana area kering atau normal? (biasanya pipi dan sekitar mata)
- Apakah kondisinya bervariasi tergantung musim atau cuaca?

### Strategi #1: Pilih Produk "Middle Ground"
Gunakan produk yang cukup gentle untuk area kering tapi efektif untuk area berminyak:
- **Pembersih**: Gel pembersih berbahan centella atau glycerin - tidak terlalu keras, tidak terlalu ringan
- **Pelembap**: Gel-cream (bukan krim kental, bukan lotion encer) - tekstur di tengah-tengah

### Strategi #2: Multi-Masking
Teknik paling efektif untuk kulit kombinasi:
- **T-zone**: Oleskan clay mask (kaolin/bentonite) untuk serap minyak
- **Pipi + area kering**: Oleskan sleeping mask atau masker hydrating

Diamkan 15-20 menit, bilas, rasakan perbedaannya!

### Strategi #3: Targeted Treatment
Aplikasikan produk spesifik hanya di area yang membutuhkan:
- BHA/salicylic acid hanya di T-zone yang bermasalah
- Pelembap ekstra hanya di pipi yang kering

### Bahan Aktif Terbaik untuk Kulit Kombinasi
- **Niacinamide 5-10%**: Bintang untuk kulit kombinasi - kontrol sebum di T-zone, perbaiki skin barrier di pipi
- **Hyaluronic Acid**: Hidrasi ringan untuk seluruh wajah
- **Centella Asiatica**: Menenangkan iritasi tanpa menyumbat pori

### Kesalahan Umum yang Perlu Dihindari
❌ Menggunakan produk kulit berminyak di seluruh wajah → pipi menjadi kering
❌ Menggunakan krim kental di seluruh wajah → T-zone semakin berminyak
❌ Melewatkan pelembap karena T-zone berminyak → dehidrasi memperburuk kedua kondisi
""",
        "read_minutes": 5,
    },
]


def run_seed():
    print("🌱 Memulai proses seed data Skinly...")
    db = SessionLocal()

    try:
        # --- Seed SkinTypeInfo ---
        print("\n📊 Mengisi data skin_type_info...")
        for skin_type, data in SKIN_TYPE_DATA.items():
            existing = db.query(SkinTypeInfo).filter(SkinTypeInfo.skin_type == skin_type).first()
            if existing:
                # Update data yang sudah ada
                existing.description = data["description"]
                existing.characteristics = data["characteristics"]
                existing.routine_morning = data["routine_morning"]
                existing.routine_night = data["routine_night"]
                existing.recommended_products = data["recommended_products"]
                print(f"  ♻️  Update: {skin_type}")
            else:
                record = SkinTypeInfo(
                    skin_type=skin_type,
                    description=data["description"],
                    characteristics=data["characteristics"],
                    routine_morning=data["routine_morning"],
                    routine_night=data["routine_night"],
                    recommended_products=data["recommended_products"],
                )
                db.add(record)
                print(f"  ✅ Tambah: {skin_type}")

        db.commit()

        # --- Seed Articles ---
        print("\n📚 Mengisi data artikel edukasi...")
        existing_titles = {a.title for a in db.query(Article.title).all()}

        for article_data in ARTICLES_DATA:
            if article_data["title"] in existing_titles:
                print(f"  ⏭️  Lewati (sudah ada): {article_data['title'][:50]}...")
                continue

            article = Article(
                id=str(uuid.uuid4()),
                title=article_data["title"],
                category=article_data["category"],
                summary=article_data["summary"],
                content=article_data["content"],
                cover_image_url=None,
                read_minutes=article_data["read_minutes"],
                created_at=utcnow(),
            )
            db.add(article)
            print(f"  ✅ Tambah: {article_data['title'][:50]}...")

        db.commit()
        print(f"\n✅ Seed selesai! {len(SKIN_TYPE_DATA)} skin type info dan {len(ARTICLES_DATA)} artikel berhasil diisi.")

    except Exception as e:
        db.rollback()
        print(f"\n❌ Error saat seed: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    run_seed()
