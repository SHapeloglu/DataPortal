# DataPortal — Kurulum Rehberi

## Docker ile Kurulum (Önerilen)

### 1. Gereksinimler
- Docker Desktop (Windows/Mac) veya Docker Engine (Linux)
- `docker compose` komutu çalışıyor olmalı

### 2. Projeyi hazırla
```bash
# .env dosyasını oluştur
cp .env.example .env
```

`.env` dosyasını aç ve şu değerleri değiştir:
```
SECRET_KEY=python -c "import secrets; print(secrets.token_hex(32))" komutuyla üret
DB_ROOT_PASSWORD=güçlü_bir_şifre
DB_PASSWORD=güçlü_bir_şifre
```

### 3. Başlat
```bash
docker compose up -d
```

İlk çalıştırmada Docker şunları yapar:
- Python imajını indirir ve bağımlılıkları yükler
- MySQL 8.0 başlatır
- `migration.sql` otomatik çalışır (tüm tablolar ve başlangıç verisi)
- Uygulama `http://localhost:5000` adresinde açılır

### 4. Giriş
Login ekranında DB bağlantı bilgilerini gir:

| Alan | Değer |
|---|---|
| Host | `db` |
| Port | `3306` |
| Kullanıcı | `dpuser` (veya .env'deki DB_USER) |
| Şifre | .env'deki DB_PASSWORD |
| Veritabanı | `dataportal` |

Sistem kullanıcısı: `selim.kilic` / `102030`

### 5. Durdur / Yeniden başlat
```bash
docker compose stop      # Durdur (veri korunur)
docker compose start     # Tekrar başlat
docker compose down      # Durdur ve container'ları sil (veri volume'da korunur)
docker compose down -v   # Her şeyi sil (VERİ KAYBOLUR)
```

### 6. Logları izle
```bash
docker compose logs -f web   # Uygulama logları
docker compose logs -f db    # MySQL logları
```

---

## Lokal Kurulum (Docker olmadan)

### 1. Python 3.11+ gerekli
```bash
pip install -r requirements.txt
```

### 2. MySQL kur ve çalıştır
```bash
mysql -u root -p -e "CREATE DATABASE dataportal CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p dataportal < migration.sql
```

### 3. .env oluştur
```bash
cp .env.example .env
# SECRET_KEY değerini düzenle
```

### 4. Başlat
```bash
python app.py
```

`http://localhost:5000` adresinde açılır.

---

## Sorun Giderme

**DB bağlantısı kurulamıyor (Docker):**
```bash
docker compose ps          # Tüm servisler running olmalı
docker compose logs db     # MySQL hata loglarına bak
```

**migration.sql çalışmadı:**
```bash
docker compose exec db mysql -u root -p dataportal -e "SHOW TABLES;"
# Tablolar görünmüyorsa:
docker compose exec db mysql -u root -p dataportal < /docker-entrypoint-initdb.d/init.sql
```

**Port 5000 meşgul:**
```yaml
# docker-compose.yml içinde ports'u değiştir:
ports:
  - "8080:5000"   # 8080'de aç
```
