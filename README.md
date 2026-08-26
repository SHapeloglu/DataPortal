<div align="center">

# 📊 DataPortal

**Excel → MySQL ETL Portalı**

Kurumsal veri yükleme, çok adımlı onay akışı ve kalite kontrolü için geliştirilmiş web tabanlı yönetim platformu.

[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)](https://python.org)
[![Flask](https://img.shields.io/badge/Flask-3.x-black?logo=flask)](https://flask.palletsprojects.com)
[![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-orange?logo=mysql&logoColor=white)](https://mysql.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://docker.com)
[![License](https://img.shields.io/badge/Lisans-Kurumsal-gray)](LICENSE)

Excel dosyalarını tek arayüzden MySQL'e aktarın; rol bazlı erişim, onay akışı ve kalite kurallarıyla yönetin.

</div>

---

## 🗂️ İçindekiler

- [Genel Bakış](#-genel-bakış)
- [Özellikler](#-özellikler)
- [Mimari](#-mimari)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Sayfa Rehberi](#-sayfa-rehberi)
- [Veritabanı Şeması](#-veritabanı-şeması)
- [Yetki Sistemi](#-yetki-sistemi)
- [API Referansı](#-api-referansı)
- [Güvenlik](#-güvenlik)
- [Geliştirme](#-geliştirme)
- [Roadmap](#-roadmap)

---

## 🌐 Genel Bakış

DataPortal, Excel dosyalarını kurumsal MySQL veritabanlarına güvenli ve denetlenebilir şekilde aktarmak için tasarlanmış bir Flask uygulamasıdır. Dosya yükleme, çok adımlı onay akışı, kalite kontrolü, stored procedure entegrasyonu ve cron tabanlı otomasyon özelliklerini tek bir arayüzde sunar.

**Hedef kullanıcılar:** Veri analisti, data engineer ve kurumsal veri operasyonu ekipleri.

**Temel kullanım senaryoları:**

- İş analistleri Excel raporlarını manuel SQL yazmadan doğrudan veritabanına aktarabilir
- Yöneticiler hangi kullanıcının hangi tablolara, hangi dizinlere erişebileceğini rol bazında belirler
- Tüm aktarımlar kalite kurallarından geçer; her işlem otomatik audit log'a düşer
- Admin dışı yüklemeler onay akışına girer; onaylayan atanmış kullanıcılara bildirim gider

---

## ✨ Özellikler

### 📁 Dosya Yükleme & Onay Akışı
- **3 Adımlı Wizard:** Dosya & dizin seçimi → Hedef tablo + sütun eşleşme önizlemesi → Özet & Yükleme
- **Dizin tabanlı erişim kontrolü:** Hiyerarşik klasör yapısı, kullanıcı/rol bazlı izinler
- **Çok kademeli onay:** Onaylayan atama, onay/red kararı, bildirim sistemi
- **Admin bypass:** Admin kullanıcılar doğrudan onaylayarak arka planda aktarımı başlatabilir
- **Dosya arşivi:** Yüklenen tüm Excel dosyaları `excel_store/`'da kalıcı olarak saklanır

### 🔄 ETL İşlemleri
- **Truncate / Append modları:** Tablo konfigürasyonundan ayarlanabilir
- **Sütun eşleşme:** Excel sütunları ile DB sütunları otomatik eşleştirilir (büyük/küçük harf duyarsız)
- **ETL_DATE:** Her yüklemeye otomatik timestamp eklenir
- **Duplicate kontrolü:** Append modunda tekrar eden satırlar atlanır
- **BeforeSP / AfterSP:** Aktarım öncesi ve sonrası stored procedure desteği

### ✅ Kalite Kontrolü
- Sütun bazında kural tanımlama (boş değer, benzersizlik, vb.)
- Hata seviyesi: `hata` (aktarımı durdurur) / `uyari` (loglanır, devam eder)
- Kalite raporu `yukle_log` tablosuna JSON olarak kaydedilir

### 🔔 Bildirim Sistemi
- Gerçek zamanlı bildirim paneli (5 saniyede bir polling)
- Okundu / okunmadı yönetimi

| Tip | Açıklama |
|---|---|
| `onay_bekliyor` | Onay bekleyen dosya bildirimi |
| `onaylandi` | Dosya onaylandı |
| `reddedildi` | Dosya reddedildi |
| `yuklendi` | DB aktarımı başarılı |
| `yukleme_hatasi` | DB aktarımı başarısız |
| `kalite_uyari` | Kalite uyarısı |
| `kalite_hatasi` | Kalite hatası |
| `cron_hata` | Cron görevi hatası |
| `sistem` | Sistem bildirimi |

### ⏰ Cron & Otomasyon
- APScheduler ile zamanlanmış stored procedure çalıştırma
- Aktif/pasif cron yönetimi, son çalışma logu

### 🔒 Güvenlik
- CSRF koruması (tüm state-değiştiren endpoint'lerde)
- Brute-force koruması (rate limiting)
- Şifre hashing (werkzeug bcrypt)
- SQL injection koruması (`sanitize()`)
- Audit log: her kritik işlem kaydedilir

---

## 🏗️ Mimari

```
DataPortal_son/
├── app.py               # Tek dosya uygulama (~2500+ satır)
├── templates/           # Jinja2 şablonları (volume mount)
│   ├── base.html        # Ana layout: accordion nav, bildirim paneli, logout
│   ├── dosya_yukle.html # 3 adımlı yükleme wizard
│   ├── onay_bekleyenler.html
│   ├── kalite_kurallari.html
│   ├── tablo_konfig.html
│   ├── dizin_yonetimi.html
│   ├── cron_yonetimi.html
│   ├── audit_log.html
│   └── ...
├── uploads/             # Geçici yükleme dizini (volume mount)
├── excel_store/         # Kalıcı dosya arşivi (bind mount, chmod 777)
├── .env                 # Çevre değişkenleri
└── docker-compose.yml
```

### Stack

| Katman | Teknoloji |
|---|---|
| Backend | Python 3.11 + Flask |
| Veritabanı | MySQL 8.0+ |
| ORM/Driver | mysql-connector-python |
| Veri İşleme | pandas + openpyxl |
| Zamanlayıcı | APScheduler |
| Container | Docker + Compose |
| Web Sunucu | Gunicorn |

### Bağlantı Yönetimi

```
Request içi:         query() / execute()  →  Flask g nesnesi üzerinden pool
Background thread:   get_conn_direct()    →  .env'den direkt bağlantı
```

---

## 🚀 Kurulum

### Gereksinimler
- Docker & Docker Compose
- Git

### 1. Repoyu klonla

```bash
git clone https://github.com/kullanici/dataportal.git
cd dataportal
```

### 2. `.env` dosyasını oluştur

```env
SECRET_KEY=guclu-gizli-anahtar-buraya
DB_HOST=db
DB_PORT=3306
DB_USER=dpuser
DB_PASSWORD=guclu-sifre-buraya
DB_NAME=dataportal
DB_ROOT_PASSWORD=root-sifre-buraya
HTTPS=false
```

Güçlü `SECRET_KEY` üretmek için:

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

### 3. Dizinleri oluştur ve izin ver

```bash
mkdir -p excel_store uploads
chmod 777 excel_store
```

### 4. Container'ları başlat

```bash
docker compose up -d
```

### 5. DB migration (ilk kurulumda)

```sql
CREATE TABLE IF NOT EXISTS yukle_log (
    LogID         INT AUTO_INCREMENT PRIMARY KEY,
    DosyaID       VARCHAR(36),
    TabloAdi      VARCHAR(100),
    Durum         ENUM('basarili','hata','uyari'),
    Mesaj         TEXT,
    EklenenSatir  INT DEFAULT 0,
    AtlananSatir  INT DEFAULT 0,
    KalisonucJSON JSON,
    Tarih         DATETIME DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE excel_dosya
  MODIFY COLUMN Durum ENUM(
    'bekliyor','onaylandi','reddedildi',
    'yukleniyor','yuklendi','yukleme_hatasi'
  ) DEFAULT 'bekliyor';
```

Uygulama `http://localhost:5001` adresinde çalışmaya başlar.

---

## 📖 Kullanım

### Excel Dosyası Yükleme

1. **Dosya Yükle** menüsüne git
2. **Adım 1:** Excel dosyasını seç, dizin belirle
3. **Adım 2:** Hedef MySQL tablosunu seç, sütun eşleşmelerini kontrol et
4. **Adım 3:** Özeti gözden geçir, yükle

> Admin kullanıcılar dosyayı anında onaylayarak aktarımı başlatır.
> Normal kullanıcılar için dizinde tanımlı onaylayanlara bildirim gider.

### Onay Akışı

```
Dosya Yüklendi
    │
    ▼
[Admin?] ──Evet──► Otomatik Onay ──► dosya_db_aktar() ──► Tamamlandı
    │
   Hayır
    │
    ▼
Onaylayanlara Bildirim
    │
    ▼
Onaylayan Karar Verir (Onay / Red)
    │
    ▼ Onay
dosya_db_aktar()
    │
    ├── BeforeSP çalıştır
    ├── Excel → MySQL aktar (truncate / append)
    ├── Kalite kurallarını kontrol et
    ├── AfterSP çalıştır
    └── Kullanıcıya bildirim gönder
```

### Tablo Konfigürasyonu

`Tablo Konfig` menüsünden her tablo için:

| Alan | Açıklama |
|---|---|
| **Yükleme Modu** | `truncate` (sil & doldur) veya `append` (ekle) |
| **BeforeSP** | Aktarım öncesi çalışacak stored procedure |
| **AfterSP** | Aktarım sonrası çalışacak stored procedure |
| **Onay Gerekli** | Bu tabloya yükleme için onay akışı zorunlu mu? |

---

## 📋 Sayfa Rehberi

### Dashboard (`/dashboard`) — Y000001
Sistem istatistikleri, aktif yetkiler, rol'e atanmış tablolar ve son yükleme bilgileri.

### Dosya Yükle (`/dosya-yukle`) — Y000008
3 adımlı wizard ile Excel dosyasını seçili dizine yükle, hedef tabloyu belirle, sütun eşleşmelerini önizle.

### Onay Bekleyenler (`/onay-bekleyenler`) — Y000009
Onay bekleyen dosyaların listesi. Onaylayan kullanıcılar buradan onay/red kararı verir.

### Excel → MySQL Direkt (`/excel-mysql-load`) — Y000004
Onay akışı olmadan direkt yükleme. Truncate veya append modunda çalışır, ETL_DATE otomatik eklenir.

### Tablo Görüntüle (`/tablo-goruntule`) — Y000005
Mevcut tabloları sayfalı olarak görüntüle ve dışa aktar.

### Tablo Sil (`/tablo-sil`) — Y000006
Rol'e atanmış tablolar arasından seçim yaparak silme. Her silme `tablo_log`'a kaydedilir.

### Dizin Yönetimi (`/dizin-yonetimi`) — Y000007
Hiyerarşik klasör yapısını yönet, dizin bazlı kullanıcı ve onaylayan ata.

### Tablo Konfig (`/tablo-konfig`) — Y000010
Her tablo için yükleme modu, BeforeSP, AfterSP ve onay zorunluluğu ayarla.

### Kalite Kuralları (`/kalite-kurallari`) — Y000011
Sütun bazlı kalite kuralları tanımla (boş değer kontrolü, benzersizlik vb.).

### Cron Yönetimi (`/cron-yonetimi`) — Y000012
APScheduler ile zamanlanmış stored procedure görevlerini yönet.

### Kullanıcılar (`/kullanicilar`) — Y000002
Tam CRUD yönetimi. Kullanıcıya rol atanır; rol üzerinden yetkiler devralınır.

### Roller (`/roller`) — Y000003
Rol oluştur, düzenle, sil. Role yetki ve erişilebilir tablo ata.

### Audit Log (`/audit-log`) — Y000001
Tüm kritik işlemlerin kayıtları: kim, ne zaman, hangi işlemi yaptı.

---

## 🗄️ Veritabanı Şeması

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  kullanici   │────▶│   rol_yetki  │◀────│    yetki     │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ KullaniciID  │     │ RolID  FK    │     │ YetkiID PK   │
│ KullaniciAdi │     │ YetkiID FK   │     │ YetkiAdi     │
│ Sifre (hash) │     └──────────────┘     └──────────────┘
│ Email        │
│ RolID  FK    │────▶┌──────────────┐     ┌──────────────┐
└──────────────┘     │     rol      │     │  rol_tablo   │
                     ├──────────────┤◀────┤──────────────┤
┌──────────────┐     │ RolID PK     │     │ RolID FK     │
│ excel_dosya  │     │ RolAdi       │     │ TabloAdi     │
├──────────────┤     └──────────────┘     └──────────────┘
│ DosyaID (uuid)│
│ DizinID FK   │────▶┌──────────────┐
│ HedefTablo   │     │    dizin     │
│ Durum        │     ├──────────────┤
│ YukleyenID   │     │ DizinID PK   │
│ DosyaYolu    │     │ DizinAdi     │
└──────┬───────┘     │ UstDizinID   │
       │             └──────────────┘
       ▼
┌──────────────┐     ┌──────────────┐
│  excel_onay  │     │  yukle_log   │
├──────────────┤     ├──────────────┤
│ DosyaID FK   │     │ DosyaID FK   │
│ OnaylayanID  │     │ TabloAdi     │
│ Karar        │     │ Durum        │
│ KararTarihi  │     │ EklenenSatir │
└──────────────┘     │ KalisonucJSON│
                     └──────────────┘
```

### Tablo Açıklamaları

**Kullanıcı & Yetki**

| Tablo | Açıklama |
|---|---|
| `kullanici` | KullaniciID, Adi, Sifre hash, Email, RolID, AktifMi |
| `rol` | RolID, RolAdi, Aciklama |
| `yetki` | YetkiID (Y000001...), YetkiAdi, Aciklama |
| `rol_yetki` | Rol ↔ Yetki N:N bağlantısı |
| `rol_tablo` | Hangi rol hangi MySQL tablolarına erişebilir |
| `kullanici_tercih` | Kullanıcı tercihleri |

**Dosya & Onay**

| Tablo | Açıklama |
|---|---|
| `excel_dosya` | Yüklenen dosyalar, durumları ve meta bilgileri |
| `excel_onay` | Onay/red kararları ve açıklamaları |

**Dizin**

| Tablo | Açıklama |
|---|---|
| `dizin` | Hiyerarşik klasör yapısı |
| `dizin_yetki` | Dizin bazlı kullanıcı/rol erişim izinleri |
| `dizin_onaylayan` | Dizin bazlı onaylayan listesi |

**Kalite & Konfig**

| Tablo | Açıklama |
|---|---|
| `kalite_kural` | Sütun bazlı kalite kuralları (tip, seviye, aktif) |
| `tablo_konfig` | Yükleme modu, BeforeSP, AfterSP, onay zorunluluğu |

**Sistem**

| Tablo | Açıklama |
|---|---|
| `audit_log` | Tüm kritik işlem kayıtları |
| `bildirim` | Kullanıcı bildirimleri (okundu/okunmadı) |
| `tablo_log` | Tablo bazlı yükleme istatistikleri |
| `yukle_log` | Aktarım detayları + kalite sonuç JSON |
| `cron_gorev` | Zamanlanmış görevler ve çalışma logları |

---

## 🔐 Yetki Sistemi

| Kod | Açıklama |
|---|---|
| Y000001 | Dashboard erişimi |
| Y000002 | Kullanıcı yönetimi |
| Y000003 | Rol yönetimi |
| Y000004 | Excel → MySQL (direkt yükleme) |
| Y000005 | Tablo görüntüleme |
| Y000006 | Tablo silme |
| Y000007 | Dizin yönetimi |
| Y000008 | Dosya yükleme (wizard) |
| Y000009 | Dosya onaylama |
| Y000010 | Tablo konfigürasyonu |
| Y000011 | Kalite kuralları |
| Y000012 | Cron yönetimi |

Her route ve API endpoint'i `@login_gerekli` + `@yetki_gerekli('YXXXXXX')` decorator'larıyla korunur. Tablo erişimi ayrıca `tablo_yetkili_mi()` fonksiyonuyla kontrol edilir.

---

## 📡 API Referansı

Tüm endpoint'ler JSON döner. Kimlik doğrulama oturum (session) tabanlıdır.

### Kimlik Doğrulama

| Method | Endpoint | Açıklama |
|---|---|---|
| `POST` | `/api/login` | Kullanıcı adı/şifre ile oturum aç |
| `GET` | `/logout` | Oturumu kapat |

```json
// POST /api/login — İstek
{ "username": "ali.veli", "password": "Guclu123!" }

// Başarı
{ "ok": true }

// Hata
{ "ok": false, "msg": "Kullanıcı adı veya şifre hatalı." }
```

### Dosya Yükleme Wizard

| Method | Endpoint | Açıklama |
|---|---|---|
| `POST` | `/api/excel-kolonlar` | Excel dosyasının sütunlarını ve satır sayısını döner |
| `GET` | `/api/tablo-kolonlar/<tablo>` | DB tablosunun sütunlarını döner |
| `GET` | `/api/tablolar` | Kullanıcının yetkili tablolarını döner |
| `GET` | `/api/tablo-konfig-listesi` | Tablo konfigürasyonlarını döner |
| `POST` | `/api/dosya-yukle` | Dosyayı yükler, onay akışını veya aktarımı başlatır |

```json
// POST /api/dosya-yukle — Normal kullanıcı
{ "ok": true, "msg": "Dosya yüklendi, onay bekleniyor." }

// POST /api/dosya-yukle — Admin (anında aktarım)
{ "ok": true, "msg": "142 satır aktarıldı. 3 tekrar atlandı." }
```

### Direkt Excel Yükleme

| Method | Endpoint | Açıklama |
|---|---|---|
| `POST` | `/api/excel-load` | Excel verisini doğrudan tabloya aktar |
| `GET` | `/api/table-columns/<tablo>` | Tablo sütunlarını getir |

```
// POST /api/excel-load — multipart/form-data
file       : <Excel dosyası>
table_name : musteri
mode       : append | truncate
```

```json
// Başarı yanıtı
{
  "success": true,
  "message": "142 yeni satır eklendi. 3 tekrar eden satır atlandı.",
  "inserted": 142,
  "duplicates": 3,
  "skipped": 0,
  "etl_date": "2026-08-05 14:35:22"
}
```

### Bildirim

| Method | Endpoint | Açıklama |
|---|---|---|
| `GET` | `/api/bildirimler` | Son 50 bildirim + okunmamış sayısı |
| `POST` | `/api/bildirimler/okundu` | Tüm bildirimleri okundu işaretle |
| `POST` | `/api/bildirimler/<id>/okundu` | Tekil bildirimi okundu işaretle |

### Kullanıcı Yönetimi

| Method | Endpoint | Yetki | Açıklama |
|---|---|---|---|
| `GET` | `/api/kullanicilar` | Y000002 | Sayfalı liste |
| `POST` | `/api/kullanicilar` | Y000002 | Yeni kullanıcı |
| `PUT` | `/api/kullanicilar/<id>` | Y000002 | Güncelle |
| `DELETE` | `/api/kullanicilar/<id>` | Y000002 | Sil |

### Rol Yönetimi

| Method | Endpoint | Yetki | Açıklama |
|---|---|---|---|
| `GET` | `/api/roller` | Y000003 | Tüm roller (yetkiler ve tablolar dahil) |
| `POST` | `/api/roller` | Y000003 | Yeni rol oluştur |
| `PUT` | `/api/roller/<id>` | Y000003 | Güncelle |
| `DELETE` | `/api/roller/<id>` | Y000003 | Sil |

```json
// POST /api/roller
{
  "RolAdi": "Analist",
  "yetkiler": ["Y000008", "Y000009"],
  "tablolar": ["musteri", "siparis"]
}
```

### Log & Bilgi

| Method | Endpoint | Açıklama |
|---|---|---|
| `GET` | `/api/tablo-log/<tablo>` | Tablonun son 100 işlem logu |
| `GET` | `/api/tablo-info/<tablo>` | İlk oluşturma ve son yükleme özeti |

---

## 🔒 Güvenlik

| Alan | Uygulama |
|---|---|
| **Şifre Saklama** | `werkzeug.security` bcrypt hash |
| **Oturum Anahtarı** | `.env`'den okunur |
| **Yetki Kontrolü** | Her route'da `@login_gerekli` + `@yetki_gerekli` |
| **Tablo Yetki Kontrolü** | `tablo_yetkili_mi()` — yalnızca rol'e atanmış tablolara erişim |
| **CSRF Koruması** | `@csrf_protect` — tüm state-değiştiren endpoint'lerde |
| **Rate Limiting** | `@rate_limit` — brute-force koruması (login) |
| **Dosya Güvenliği** | `secure_filename` + `.xlsx/.xls` uzantı whitelist |
| **SQL Injection** | `sanitize()` tablo/kolon adlarına, `%s` parametreli sorgulara |
| **Self-Delete** | Kullanıcı kendi hesabını silemez |
| **Audit Log** | Her kritik işlem `audit_log` tablosuna kaydedilir |

> ⚠️ **Production Notları:**
> - `SECRET_KEY` değerini güçlü bir rastgele değerle değiştirin
> - HTTPS (TLS) arkasında çalıştırın
> - MySQL kullanıcısına yalnızca gerekli izinleri verin
> - `excel_store/` ve `uploads/` dizinlerini web'e açık yapmayın

---

## 🛠️ Geliştirme

### Kod Değişikliği Sonrası Deploy

```bash
# app.py veya template değişikliği (yeterli):
cd /root/DataPortal_son && docker compose restart web

# requirements.txt veya Dockerfile değişikliği:
cd /root/DataPortal_son && docker compose up -d --build web
```

### Loglar

```bash
# Uygulama logları (canlı):
docker logs -f dataportal_son-web-1

# Hata filtreleme:
docker logs dataportal_son-web-1 2>&1 | grep ERROR

# Belirli bir fonksiyona ait loglar:
docker logs dataportal_son-web-1 2>&1 | grep -A20 "dosya_db_aktar"
```

### Korunan Sistem Tabloları

Aşağıdaki tablolar uygulama tarafından korunur; silme ve değiştirme işlemlerine kapatılmıştır:

```
audit_log, bildirim, cron_gorev, dizin, dizin_onaylayan, dizin_yetki,
excel_dosya, excel_onay, kalite_kural, kullanici, kullanici_tercih,
rol, rol_tablo, rol_yetki, tablo_konfig, tablo_log, yetki, yukle_log
```

### Background Thread Kuralları

`dosya_db_aktar()` ve scheduler görevleri Flask request context dışında çalışır:

```python
# ✅ DOĞRU — request context gerektirmez
conn = get_conn_direct()
_bildirim_direct(alici_id, tip, baslik, mesaj, dosya_id)
_audit_direct('EYLEM_ADI', 'detay')

# ❌ YANLIŞ — request context gerektirir, background thread'de çöker
query("SELECT ...")
execute("INSERT ...")
bildirim_gonder(...)
audit(...)
session['kullanici_id']
```

### Yeni Yetki Ekleme

1. `yetki` tablosuna `INSERT` satırı ekle
2. İlgili route'a `@yetki_gerekli('YXXXXXX')` decorator'ı ekle
3. `base.html` sidebar'ına koşullu link ekle

### Yeni Modül Şablonu

```python
@app.route('/api/endpoint', methods=['POST'])
@api_login_gerekli
@api_yetki_gerekli('Y000XXX')
@csrf_protect
def api_endpoint():
    try:
        d = request.get_json(force=True)
        # validasyon → iş mantığı → DB işlemi
        audit('EYLEM_ADI', 'detay')
        return jsonify({'ok': True, 'msg': 'Başarılı.'})
    except Exception as e:
        logger.error(f'Endpoint hatası: {e}')
        return jsonify({'ok': False, 'msg': str(e)})
```

### Commit Mesajı Formatı

```
feat:     yeni özellik
fix:      hata düzeltme
docs:     sadece dokümantasyon
refactor: yeniden yapılandırma
style:    kod formatı (işlevsel değişiklik yok)
test:     test ekleme
```

### Sık Karşılaşılan Hatalar

| Hata | Neden | Çözüm |
|---|---|---|
| `Working outside of request context` | Background thread'de `query()`/`session` kullanımı | `get_conn_direct()` kullan |
| `Invalid cross-device link` | `os.rename()` farklı volume'lar arası | `shutil.move()` kullan |
| `Permission denied: excel_store` | Container appuser, host dizin root'a ait | `chmod 777 excel_store/` |
| `Table 'dataportal.X' doesn't exist` | `HedefTablo` alanı yanlış kaydedilmiş | DB'deki kaydı kontrol et |

---

## 📋 Roadmap

- [ ] Dosya versiyonlama (aynı tabloya gelen dosyaların geçmişi)
- [ ] E-posta bildirimi (SMTP entegrasyonu)
- [ ] Dashboard istatistikleri (kaç dosya yüklendi, tablo bazlı son yükleme)
- [ ] Çoklu onaylayan (2/3 onay şartı)
- [ ] Yükleme kuyruğu (Celery/Redis)
- [ ] API token desteği (harici sistem entegrasyonu)
- [ ] Otomatik şema güncellemesi (yeni sütun gelince ALTER TABLE)
- [ ] Veri soyu (data lineage)
- [ ] Detaylı kalite raporu (satır bazlı hata)
- [ ] Yükleme önizleme (onaylamadan önce ilk 10 satır)

---

## 📄 Lisans

Bu proje özel/kurumsal kullanım için geliştirilmiştir.

---

<div align="center">
<sub>Flask · MySQL · Docker ile geliştirildi</sub>
</div>
