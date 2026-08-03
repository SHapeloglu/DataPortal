-- DataPortal — Veritabanı Kurulum Scripti
-- MySQL 8.0+
-- Bu dosya docker-entrypoint-initdb.d/ altında sadece ilk açılışta çalışır.

SET NAMES utf8mb4;
SET time_zone = '+03:00';

-- ─── YETKİ & ROL ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS rol (
    RolID    INT AUTO_INCREMENT PRIMARY KEY,
    RolAdi   VARCHAR(100) NOT NULL UNIQUE,
    Aciklama TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS yetki (
    YetkiID  VARCHAR(10) PRIMARY KEY,   -- Y000001 formatı
    YetkiAdi VARCHAR(100) NOT NULL,
    Aciklama TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS rol_yetki (
    RolID   INT NOT NULL,
    YetkiID VARCHAR(10) NOT NULL,
    PRIMARY KEY (RolID, YetkiID),
    FOREIGN KEY (RolID)   REFERENCES rol(RolID)   ON DELETE CASCADE,
    FOREIGN KEY (YetkiID) REFERENCES yetki(YetkiID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS rol_tablo (
    RolID    INT NOT NULL,
    TabloAdi VARCHAR(100) NOT NULL,
    PRIMARY KEY (RolID, TabloAdi),
    FOREIGN KEY (RolID) REFERENCES rol(RolID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── KULLANICI ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS kullanici (
    KullaniciID  INT AUTO_INCREMENT PRIMARY KEY,
    KullaniciAdi VARCHAR(100) NOT NULL UNIQUE,
    Sifre        VARCHAR(255) NOT NULL,
    Email        VARCHAR(200),
    RolID        INT,
    AktifMi      TINYINT(1) DEFAULT 1,
    OlusturmaTarih DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (RolID) REFERENCES rol(RolID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS kullanici_tercih (
    TercihID   INT AUTO_INCREMENT PRIMARY KEY,
    KullaniciID INT NOT NULL,
    TercihAdi  VARCHAR(100) NOT NULL,
    TercihDeger TEXT,
    UNIQUE KEY uq_kullanici_tercih (KullaniciID, TercihAdi),
    FOREIGN KEY (KullaniciID) REFERENCES kullanici(KullaniciID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── DİZİN YÖNETİMİ ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS dizin (
    DizinID    INT AUTO_INCREMENT PRIMARY KEY,
    DizinAdi   VARCHAR(200) NOT NULL,
    UstDizinID INT,
    Aciklama   TEXT,
    FOREIGN KEY (UstDizinID) REFERENCES dizin(DizinID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dizin_yetki (
    ID         INT AUTO_INCREMENT PRIMARY KEY,
    DizinID    INT NOT NULL,
    KullaniciID INT,
    RolID      INT,
    YetkiTuru  ENUM('okuma','yazma') DEFAULT 'okuma',
    FOREIGN KEY (DizinID) REFERENCES dizin(DizinID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dizin_onaylayan (
    ID          INT AUTO_INCREMENT PRIMARY KEY,
    DizinID     INT NOT NULL,
    OnaylayanID INT NOT NULL,
    FOREIGN KEY (DizinID)     REFERENCES dizin(DizinID)       ON DELETE CASCADE,
    FOREIGN KEY (OnaylayanID) REFERENCES kullanici(KullaniciID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── DOSYA & ONAY AKIŞI ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS excel_dosya (
    DosyaID      VARCHAR(36) PRIMARY KEY,
    DizinID      INT,
    DosyaAdi     VARCHAR(255) NOT NULL,
    OrijinalAd   VARCHAR(255),
    HedefTablo   VARCHAR(100),
    Durum        ENUM('bekliyor','onaylandi','reddedildi','yukleniyor','yuklendi','yukleme_hatasi')
                 DEFAULT 'bekliyor',
    YukleyenID   INT,
    DosyaYolu    VARCHAR(500),
    DosyaHash    VARCHAR(64),
    SatirSayisi  INT,
    Notlar       TEXT,
    YukleTarihi  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (DizinID)    REFERENCES dizin(DizinID)         ON DELETE SET NULL,
    FOREIGN KEY (YukleyenID) REFERENCES kullanici(KullaniciID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS excel_onay (
    OnayID      INT AUTO_INCREMENT PRIMARY KEY,
    DosyaID     VARCHAR(36) NOT NULL,
    OnaylayanID INT,
    Karar       ENUM('onaylandi','reddedildi') NOT NULL,
    Aciklama    TEXT,
    KararTarihi DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (DosyaID)     REFERENCES excel_dosya(DosyaID)   ON DELETE CASCADE,
    FOREIGN KEY (OnaylayanID) REFERENCES kullanici(KullaniciID)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── KALİTE & KONFİGÜRASYON ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS tablo_konfig (
    KonfigID      INT AUTO_INCREMENT PRIMARY KEY,
    TabloAdi      VARCHAR(100) NOT NULL UNIQUE,
    YukleModu     ENUM('truncate','append') DEFAULT 'truncate',
    BeforeSP      VARCHAR(200),
    AfterSP       VARCHAR(200),
    ArtanAnahtar  VARCHAR(100),
    OnayGerekli   TINYINT(1) DEFAULT 1,
    Aciklama      TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS kalite_kural (
    KuralID      INT AUTO_INCREMENT PRIMARY KEY,
    TabloAdi     VARCHAR(100) NOT NULL,
    SutunAdi     VARCHAR(100) NOT NULL,
    KuralTipi    ENUM('bos_deger','uzunluk','format','benzersiz','deger_listesi') NOT NULL,
    KuralDeger   VARCHAR(500),
    HataSeviyesi ENUM('hata','uyari') DEFAULT 'hata',
    Aciklama     TEXT,
    AktifMi      TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── SİSTEM TABLOLARI ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS audit_log (
    LogID       INT AUTO_INCREMENT PRIMARY KEY,
    KullaniciID INT,
    Eylem       VARCHAR(100),
    Detay       TEXT,
    IP          VARCHAR(45),
    Tarih       DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tarih (Tarih),
    INDEX idx_kullanici (KullaniciID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS bildirim (
    BildirimID  INT AUTO_INCREMENT PRIMARY KEY,
    AliciID     INT NOT NULL,
    Tip         VARCHAR(50),
    Baslik      VARCHAR(255) NOT NULL,
    Mesaj       TEXT,
    DosyaID     VARCHAR(36),
    OkunduMu    TINYINT(1) DEFAULT 0,
    Tarih       DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_alici (AliciID),
    INDEX idx_okundu (AliciID, OkunduMu)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tablo_log (
    LogID       INT AUTO_INCREMENT PRIMARY KEY,
    TabloAdi    VARCHAR(100),
    KullaniciID INT,
    IslemTuru   VARCHAR(50),
    Eklenen     INT DEFAULT 0,
    Atlanan     INT DEFAULT 0,
    Tekrar      INT DEFAULT 0,
    Tarih       DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS yukle_log (
    LogID          INT AUTO_INCREMENT PRIMARY KEY,
    DosyaID        VARCHAR(36),
    TabloAdi       VARCHAR(100),
    Durum          ENUM('basarili','hata','uyari'),
    Mesaj          TEXT,
    EklenenSatir   INT DEFAULT 0,
    AtlananSatir   INT DEFAULT 0,
    KalisonucJSON  JSON,
    Tarih          DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_dosya (DosyaID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cron_gorev (
    GorevID    INT AUTO_INCREMENT PRIMARY KEY,
    GorevAdi   VARCHAR(200) NOT NULL,
    SpAdi      VARCHAR(200) NOT NULL,
    CronExpr   VARCHAR(100) NOT NULL,
    AktifMi    TINYINT(1) DEFAULT 1,
    SonCalisma DATETIME,
    SonSonuc   ENUM('basarili','hata'),
    Aciklama   TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── SEED DATA ────────────────────────────────────────────────────────────────

-- Roller
INSERT IGNORE INTO rol (RolID, RolAdi, Aciklama) VALUES
(1, 'Admin',    'Tüm yetkilere sahip sistem yöneticisi'),
(2, 'Analist',  'Veri yükleme ve görüntüleme yetkisi'),
(3, 'Onaylayan','Dosya onaylama yetkisi');

-- Yetkiler
INSERT IGNORE INTO yetki (YetkiID, YetkiAdi, Aciklama) VALUES
('Y000001', 'Dashboard',           'Ana ekrana erişim'),
('Y000002', 'Kullanıcı Yönetimi',  'Kullanıcı CRUD'),
('Y000003', 'Rol Yönetimi',        'Rol ve yetki CRUD'),
('Y000004', 'Excel→MySQL',         'Direkt Excel yükleme'),
('Y000005', 'Tablo Görüntüleme',   'Tablo listesi ve veri görüntüleme'),
('Y000006', 'Tablo Silme',         'Tablo silme işlemi'),
('Y000007', 'Dizin Yönetimi',      'Dizin CRUD ve yetki atama'),
('Y000008', 'Dosya Yükleme',       'Dosya yükleme ve arşiv'),
('Y000009', 'Dosya Onaylama',      'Yüklenen dosyaları onaylama/reddetme'),
('Y000010', 'Tablo Konfigürasyonu','Tablo yükleme modu ve SP ayarları'),
('Y000011', 'Kalite Kuralları',    'Kalite kural CRUD'),
('Y000012', 'Cron Yönetimi',       'Zamanlanmış görev yönetimi');

-- Admin rolüne tüm yetkiler
INSERT IGNORE INTO rol_yetki (RolID, YetkiID)
SELECT 1, YetkiID FROM yetki;

-- Analist yetkiler
INSERT IGNORE INTO rol_yetki (RolID, YetkiID) VALUES
(2, 'Y000001'),(2, 'Y000004'),(2, 'Y000005'),(2, 'Y000008');

-- Onaylayan yetkiler
INSERT IGNORE INTO rol_yetki (RolID, YetkiID) VALUES
(3, 'Y000001'),(3, 'Y000005'),(3, 'Y000009');

-- Admin kullanıcı (şifre: Admin123!)
-- werkzeug pbkdf2:sha256 hash — uygulama ilk açılışta değiştirin!
INSERT IGNORE INTO kullanici (KullaniciID, KullaniciAdi, Sifre, Email, RolID, AktifMi) VALUES
(1, 'admin',
 'pbkdf2:sha256:600000$x8Kn2QpL$a3b4c5d6e7f8a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6',
 'admin@dataportal.local', 1, 1);

-- NOT: Yukarıdaki hash placeholder'dır.
-- İlk girişte "Şifre Değiştir" sayfasını kullanın.
-- Ya da uygulama başlamadan önce aşağıdaki Python ile hash üretin:
--   from werkzeug.security import generate_password_hash
--   print(generate_password_hash('Admin123!'))
-- Üretilen hash'i buraya yazın.
