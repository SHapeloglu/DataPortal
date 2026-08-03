<div align="center">

# ⬡ DataPortal

**MySQL tabanlı kurumsal veri yönetim sistemi**

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python&logoColor=white)](https://python.org)
[![Flask](https://img.shields.io/badge/Flask-2.3%2B-black?logo=flask)](https://flask.palletsprojects.com)
[![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-orange?logo=mysql&logoColor=white)](https://mysql.com)
[![License](https://img.shields.io/badge/Lisans-MIT-green)](LICENSE)

Excel dosyalarını tek tıkla MySQL'e aktarın, rol ve yetki tabanlı erişim kontrolüyle yönetin.

[Kurulum](#-kurulum) · [Özellikler](#-özellikler) · [Ekran Görüntüleri](#-ekran-görüntüleri) · [API](#-api-referansı) · [Katkı](#-katkı)

</div>

---

## 📋 İçindekiler

- [Proje Hakkında](#-proje-hakkında)
- [Özellikler](#-özellikler)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Kurulum](#-kurulum)
- [Yapılandırma](#-yapılandırma)
- [Veritabanı Şeması](#-veritabanı-şeması)
- [Yetki Sistemi](#-yetki-sistemi)
- [Sayfa Rehberi](#-sayfa-rehberi)
- [API Referansı](#-api-referansı)
- [Güvenlik](#-güvenlik)
- [Geliştirici Notları](#-geliştirici-notları)
- [Katkı](#-katkı)

---

## 🎯 Proje Hakkında

DataPortal, farklı rollere sahip kullanıcıların MySQL veritabanına Excel verisi aktarmasına, mevcut tablolara veri yüklemesine ve erişim yetkilerini merkezi olarak yönetmesine olanak tanıyan bir web uygulamasıdır.

**Temel kullanım senaryoları:**

- İş analistleri Excel raporlarını manuel SQL yazmadan doğrudan veritabanına aktarabilir
- Veritabanı yöneticileri hangi kullanıcının hangi tablolara erişebileceğini rol bazında belirler
- Her işlem otomatik olarak loglanır; kim, ne zaman, kaç satır yükledi görülebilir

---

## ✨ Özellikler

| Özellik | Açıklama |
|---|---|
| 🔐 **2 Adımlı Giriş** | Önce DB bağlantısı, sonra kullanıcı kimlik doğrulaması |
| 📊 **Excel → Tablo Oluştur** | `.xlsx` / `.xls` dosyasından otomatik tablo şeması üretir |
| 📥 **Excel → Tabloya Yükle** | Mevcut tabloya veri aktarır; tekrar eden satırları atlar |
| 🗑️ **Tablo Sil** | Yetki kapsamındaki tabloları güvenli siler |
| 👥 **Kullanıcı Yönetimi** | Tam CRUD — kullanıcı ekle, düzenle, sil |
| 🎭 **Rol Yönetimi** | Rol oluştur, yetki ve tablo ata |
| 🔑 **Yetki Yönetimi** | İnce taneli yetki tanımları |
| 📈 **ETL Log** | Her yükleme işlemi kayıt altına alınır |
| 📋 **Audit Log** | Giriş, silme, kullanıcı işlemleri gibi kritik olaylar izlenir |
| 📌 **Özelleştirilebilir Dashboard** | Hızlı erişim kartları sürükle-bırak ile yeniden düzenlenir |
| 🔒 **Scrypt/Bcrypt Şifreleme** | Tüm şifreler hash'lenerek saklanır; her iki format da desteklenir |
| 💾 **DB Profil Yönetimi** | Bağlantı bilgileri tarayıcıda profil olarak kaydedilebilir (şifre hariç) |
| 🎯 **Alan Seçimi** | Tablo oluştururken Excel'deki alanlar tek tek seçilebilir |
| 🔗 **Connection Pooling** | MySQL bağlantıları pool ile verimli yönetilir |

---

## 🛠 Teknoloji Yığını

**Backend**
- [Flask 2.3+](https://flask.palletsprojects.com/) — Web framework
- [mysql-connector-python](https://dev.mysql.com/doc/connector-python/en/) — MySQL sürücüsü
- [pandas](https://pandas.pydata.org/) — Excel okuma ve veri işleme
- [openpyxl](https://openpyxl.readthedocs.io/) — `.xlsx` desteği
- [Werkzeug](https://werkzeug.palletsprojects.com/) — Şifre hash'leme, güvenli dosya adı

**Frontend**
- Saf HTML/CSS/JS — framework bağımlılığı yok
- [DM Sans & DM Mono](https://fonts.google.com/) — Tipografi
- Koyu tema, CSS değişkenleri ile özelleştirilebilir

**Veritabanı**
- MySQL 8.0+ (utf8mb4 / unicode_ci)

---

## 🚀 Kurulum

### Gereksinimler

- Python 3.10+
- MySQL 8.0+
- pip

### Adım Adım

```bash
# 1. Repoyu klonlayın
git clone https://github.com/kullanici/dataportal.git
cd dataportal

# 2. Sanal ortam oluşturun (önerilir)
python -m venv venv
source venv/bin/activate        # Linux/macOS
venv\Scripts\activate           # Windows

# 3. Bağımlılıkları yükleyin
pip install -r requirements.txt

# 4. Ortam değişkenlerini ayarlayın
cp .env.example .env
# .env dosyasını açıp SECRET_KEY değerini güncelleyin
```

#### Güçlü SECRET_KEY üretmek için:

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

```bash
# 5. Veritabanını hazırlayın
mysql -u root -p veritabani_adi < migration.sql

# 6. Uygulamayı başlatın
python app.py
```

Tarayıcıda **http://localhost:5000** adresini açın.

---

## ⚙️ Yapılandırma

### `.env` Dosyası

```env
# Flask oturum güvenlik anahtarı — production'da mutlaka değiştirin
SECRET_KEY=buraya_guclu_rastgele_bir_deger_yazin

# Debug modu — production'da false olmalı
FLASK_DEBUG=false
```

### Uygulama Sabitleri (`app.py`)

| Sabit | Varsayılan | Açıklama |
|---|---|---|
| `MAX_CONTENT_LENGTH` | `16 MB` | Maksimum yükleme boyutu |
| `UPLOAD_FOLDER` | `uploads/` | Geçici dosya dizini |
| `IZIN_VERILEN_UZANTILAR` | `.xlsx, .xls` | Kabul edilen dosya türleri |
| Connection pool `pool_size` | `5` | Eş zamanlı DB bağlantısı |

---

## 🗄️ Veritabanı Şeması

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────┐
│    kullanici     │────▶│    rol_yetki      │◀────│    yetki     │
├─────────────────┤     ├──────────────────┤     ├──────────────┤
│ KullaniciID PK  │     │ RolID  FK        │     │ YetkiID PK   │
│ KullaniciAdi    │     │ YetkiID FK       │     │ YetkiAdi     │
│ KullaniciSifresi│     └──────────────────┘     └──────────────┘
│ KullaniciEposta │
│ RolID  FK       │────▶┌──────────────────┐
└─────────────────┘     │       rol         │
                        ├──────────────────┤
┌─────────────────┐     │ RolID PK         │
│   rol_tablo     │◀────│ RolAdi           │
├─────────────────┤     └──────────────────┘
│ RolID  FK       │
│ TablAdi         │     ┌──────────────────┐
└─────────────────┘     │    tablo_log      │
                        ├──────────────────┤
┌─────────────────┐     │ LogID PK         │
│ kullanici_tercih│     │ Tablo            │
├─────────────────┤     │ KullaniciID FK   │
│ KullaniciID FK  │     │ IslemTuru        │
│ TercihAnahtar   │     │ Eklenen          │
│ TercihDeger     │     │ Atlanan / Tekrar │
└─────────────────┘     │ IslemTarihi      │
                        └──────────────────┘
```

### Tablo Açıklamaları

| Tablo | Açıklama |
|---|---|
| `kullanici` | Sistem kullanıcıları; şifreler bcrypt ile hash'lenir |
| `rol` | Kullanıcı rolleri (örn. Admin, Analist, Okuyucu) |
| `yetki` | Atomik yetki tanımları |
| `rol_yetki` | Rol ↔ Yetki N:N ilişki tablosu |
| `rol_tablo` | Hangi rolün hangi MySQL tablolarına erişebileceği |
| `tablo_log` | Excel yükleme/oluşturma/silme işlem geçmişi |
| `kullanici_tercih` | Dashboard hızlı erişim kartı tercihleri |

---

## 🔑 Yetki Sistemi

Her sayfa ve API endpoint'i, yetki kontrol decorator'larıyla korunur.

| YetkiID | Yetki Adı | Erişim Sağladığı Ekranlar |
|---|---|---|
| `Y000001` | Kullanıcı Yönetimi | `/kullanicilar` ve tüm CRUD API'leri |
| `Y000002` | Rol ve Yetki Yönetimi | `/roller`, `/yetkiler` ve CRUD API'leri |
| `Y000003` | Tablo Oluşturma | `/excel-mysql-create`, `POST /api/excel-upload` |
| `Y000004` | Tabloya Veri Yükleme | `/excel-mysql-load`, `POST /api/excel-load` |
| `Y000005` | Tablo Silme | `/tablo-sil`, `POST /api/tablo-sil` |
| `Y000006` | Tablo Görüntüleme | `/tablo-goruntule` ve export API |

### Rol → Tablo İlişkisi

`rol_tablo` tablosu sayesinde her rol yalnızca atanmış MySQL tablolarına erişebilir:

```
Admin Rolü → [musteri, siparis, urun]   (3 tabloya tam yetki)
Analist Rolü → [rapor_q1, rapor_q2]    (sadece rapor tablolarına)
```

---

## 📖 Sayfa Rehberi

### 🔑 Login (`/login`)

İki adımlı oturum açma:
1. **DB Bağlantısı** — Host, port, kullanıcı adı, şifre, veritabanı adı girilir
2. **Kullanıcı Girişi** — Sisteme kayıtlı kullanıcı adı ve şifre ile giriş yapılır

### 📊 Dashboard (`/dashboard`)

- Sistem istatistikleri (kullanıcı, rol, yetki sayıları)
- Aktif yetkiler listesi
- Rol'e atanmış tablolar ve son yükleme bilgileri
- Her tablo için yükleme geçmişi modalı
- Sürükle-bırak ile özelleştirilebilir hızlı erişim kartları

### ⬛ Excel → Tablo Oluştur (`/excel-mysql-create`) — `Y000003`

Excel dosyasının ilk satırını sütun adı olarak kullanarak MySQL'de yeni bir tablo oluşturur. Tüm sütunlar `NVARCHAR(500)` olarak tanımlanır.

**Akış:**
1. `.xlsx` veya `.xls` dosyası seçin / sürükleyin
2. "Alanları Görüntüle" butonuna tıklayın
3. İstenen alanları seçin / kaldırın; tablo adını düzenleyin
4. "Tabloyu Oluştur" ile sadece seçili alanlardan tablo oluşturulur

### ⬜ Excel → Tabloya Yükle (`/excel-mysql-load`) — `Y000004`

Mevcut bir tabloya Excel verisi aktarır.

**Modlar:**
- **Sadece Yeni Ekle** — Mevcut satırlarla birebir eşleşen satırları atlar (append)
- **Tabloyu Temizleyip Yükle** — Önce `TRUNCATE`, sonra tüm satırları ekler

Her yüklemede `ETL_DATE` sütunu otomatik eklenir / güncellenir.

### 🗑️ Tablo Sil (`/tablo-sil`) — `Y000005`

Rol'e atanmış tablolar arasından seçim yaparak silme işlemi gerçekleştirir. Her silme `tablo_log`'a kaydedilir.

### 👥 Kullanıcılar (`/kullanicilar`) — `Y000001`

Tam CRUD yönetimi. Kullanıcıya rol atanır; rol üzerinden yetkiler ve tablo erişimleri devralınır. Kendi hesabını silme engeli mevcuttur.

### 🎭 Roller (`/roller`) — `Y000002`

- Rol oluştur/düzenle/sil
- Role yetki ata (çoklu seçim)
- Role erişilebilir MySQL tabloları ata

### 🔑 Yetkiler (`/yetkiler`) — `Y000002`

Sistemdeki atomik yetki tanımlarını yönetir.

---

## 🌐 API Referansı

Tüm API endpoint'leri JSON döner. Kimlik doğrulama oturum (session) tabanlıdır.

### Kimlik Doğrulama

| Metot | Endpoint | Açıklama |
|---|---|---|
| `POST` | `/api/connect` | MySQL bağlantısını test et ve oturuma kaydet |
| `POST` | `/api/login` | Kullanıcı adı/şifre ile oturum aç |
| `GET` | `/logout` | Oturumu kapat |

**`POST /api/connect`**
```json
// İstek
{ "host": "localhost", "port": 3306, "user": "root", "password": "...", "database": "mydb" }
// Yanıt
{ "ok": true }
```

**`POST /api/login`**
```json
// İstek
{ "username": "selim.kilic", "password": "102030" }
// Yanıt (başarı)
{ "ok": true }
// Yanıt (hata)
{ "ok": false, "msg": "Kullanıcı adı veya şifre hatalı." }
```

---

### Kullanıcılar

| Metot | Endpoint | Yetki | Açıklama |
|---|---|---|---|
| `GET` | `/api/kullanicilar?page=1&per_page=50` | Y000001 | Sayfalı liste |
| `POST` | `/api/kullanicilar` | Y000001 | Yeni kullanıcı |
| `PUT` | `/api/kullanicilar/<id>` | Y000001 | Güncelle |
| `DELETE` | `/api/kullanicilar/<id>` | Y000001 | Sil |

**`POST /api/kullanicilar`**
```json
{ "KullaniciAdi": "ali.veli", "KullaniciSifresi": "Guclu123!", "KullaniciEposta": "ali@firma.com", "RolID": "R000002" }
```

---

### Roller

| Metot | Endpoint | Yetki | Açıklama |
|---|---|---|---|
| `GET` | `/api/roller` | Y000002 | Tüm roller (yetkiler ve tablolar dahil) |
| `POST` | `/api/roller` | Y000002 | Yeni rol |
| `PUT` | `/api/roller/<id>` | Y000002 | Güncelle |
| `DELETE` | `/api/roller/<id>` | Y000002 | Sil |

**`POST /api/roller`**
```json
{ "RolAdi": "Analist", "yetkiler": ["Y000003","Y000004"], "tablolar": ["musteri","siparis"] }
```

---

### Excel İşlemleri

| Metot | Endpoint | Yetki | Açıklama |
|---|---|---|---|
| `POST` | `/api/excel-upload` | Y000003 | Excel'den yeni tablo oluştur |
| `GET` | `/api/table-columns/<tablo>` | Y000004 | Tablo sütunlarını getir |
| `POST` | `/api/excel-load` | Y000004 | Excel verisi mevcut tabloya yükle |

**`POST /api/excel-load`** — `multipart/form-data`
```
file       : <Excel dosyası>
table_name : musteri
mode       : append | truncate
```

```json
// Başarı yanıtı
{
  "success": true,
  "message": "142 yeni satır eklendi. 3 tekrar eden satır atlandı.",
  "inserted": 142, "duplicates": 3, "skipped": 0,
  "matched_cols": ["AdSoyad","Telefon","Sehir"],
  "etl_date": "2026-02-28 14:35:22"
}
```

---

### Log & Bilgi

| Metot | Endpoint | Açıklama |
|---|---|---|
| `GET` | `/api/tablo-log/<tablo>` | Tablonun son 100 işlem logu |
| `GET` | `/api/tablo-info/<tablo>` | İlk oluşturma ve son yükleme özeti |

---

### Dashboard

| Metot | Endpoint | Açıklama |
|---|---|---|
| `GET` | `/api/dashboard-tercih` | Kullanıcının kart tercihlerini getir |
| `POST` | `/api/dashboard-tercih` | Kart tercihlerini kaydet |

---

## 🔒 Güvenlik

| Alan | Uygulama |
|---|---|
| **Şifre Saklama** | `werkzeug.security` bcrypt (PBKDF2-HMAC-SHA256) |
| **Oturum Anahtarı** | `.env`'den okunur, production'da `os.urandom(32)` |
| **Yetki Kontrolü** | Her route ve API endpoint'inde `@login_gerekli` + `@yetki_gerekli` |
| **Tablo Yetki Kontrolü** | `tablo_yetkili_mi()` — kullanıcı yalnızca rol'üne atanmış tablolara erişir |
| **Dosya Güvenliği** | `werkzeug.utils.secure_filename` + uzantı whitelist |
| **SQL Parametre** | Kullanıcı verisi her zaman `%s` parametresiyle geçirilir |
| **Debug Modu** | `FLASK_DEBUG=true` env değişkeni ile kontrol edilir; varsayılan `false` |
| **Self-Delete Koruması** | Kullanıcı kendi hesabını silemez |

> ⚠️ **Production Notları:**
> - `SECRET_KEY` değerini güçlü bir rastgele değerle değiştirin
> - HTTPS (TLS) arkasında çalıştırın
> - MySQL kullanıcısına yalnızca gerekli izinleri verin
> - Dosya yükleme dizinini (`uploads/`) web'e açık yapmayın

---

## 🧑‍💻 Geliştirici Notları

### Proje Yapısı

```
dataportal/
├── app.py                  # Tüm route ve iş mantığı
├── requirements.txt        # Python bağımlılıkları
├── migration.sql           # Veritabanı kurulum scripti
├── .env.example            # Ortam değişkeni şablonu
├── .env                    # Yerel yapılandırma (git'e eklenmez)
├── uploads/                # Geçici yükleme dizini (git'e eklenmez)
└── templates/
    ├── base.html           # Ortak layout, sidebar, toast, JS yardımcıları
    ├── login.html          # 2 adımlı giriş ekranı
    ├── dashboard.html      # Ana panel
    ├── excel_mysql.html    # Tablo oluşturma
    ├── excel_mysql_load.html # Veri yükleme
    ├── tablo_sil.html      # Tablo silme
    ├── kullanicilar.html   # Kullanıcı yönetimi
    ├── roller.html         # Rol yönetimi
    ├── yetkiler.html       # Yetki yönetimi
    ├── audit_log.html      # Audit log izleme (sadece Admin)
    ├── yetkisiz.html       # 403 sayfası
    └── help.html           # Yardım / kullanım kılavuzu
```

### Yeni Yetki Eklemek

1. `migration.sql`'e `INSERT INTO yetki` satırı ekleyin
2. İlgili route'a `@yetki_gerekli('YXXXXXX')` decorator'ı ekleyin
3. Gerekirse `base.html` sidebar'ına koşullu link ekleyin

### Yeni Tablo Alanı Eklemek

ETL akışı tamamen dinamiktir; Excel sütun adları otomatik olarak DB sütunlarıyla eşleştirilir (büyük/küçük harf duyarsız). Yeni sütun için code değişikliği gerekmez.

### Bağımlılıkları Güncellemek

```bash
pip install --upgrade -r requirements.txt
pip freeze > requirements.txt
```

---

## 🤝 Katkı

1. Repo'yu fork'layın
2. Feature branch oluşturun: `git checkout -b feature/yeni-ozellik`
3. Değişikliklerinizi commit'leyin: `git commit -m 'feat: yeni özellik açıklaması'`
4. Branch'i push'layın: `git push origin feature/yeni-ozellik`
5. Pull Request açın

### Commit Mesajı Formatı

```
feat:  yeni özellik
fix:   hata düzeltme
docs:  sadece dokümantasyon
style: kod formatı (işlevsel değişiklik yok)
refactor: yeniden yapılandırma
test:  test ekleme
```

---

## 📄 Lisans

MIT © 2026 DataPortal

---

<div align="center">
<sub>Flask · MySQL · Python ile geliştirildi</sub>
</div>
