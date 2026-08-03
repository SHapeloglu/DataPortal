-- ============================================================
-- DataPortal — Veritabanı Kurulum & Migration Scripti
-- Önce bu dosyayı çalıştırın, sonra uygulamayı başlatın.
-- ============================================================

-- Karakter seti ayarı
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- ─── TABLOLAR ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS rol (
    RolID    VARCHAR(10)  NOT NULL,
    RolAdi   VARCHAR(100) NOT NULL,
    PRIMARY KEY (RolID)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS yetki (
    YetkiID  VARCHAR(10)  NOT NULL,
    YetkiAdi VARCHAR(100) NOT NULL,
    PRIMARY KEY (YetkiID)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rol_yetki (
    RolID   VARCHAR(10) NOT NULL,
    YetkiID VARCHAR(10) NOT NULL,
    PRIMARY KEY (RolID, YetkiID),
    FOREIGN KEY (RolID)   REFERENCES rol(RolID)   ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (YetkiID) REFERENCES yetki(YetkiID) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kullanici (
    KullaniciID     VARCHAR(10)  NOT NULL,
    KullaniciAdi    VARCHAR(100) NOT NULL UNIQUE,
    KullaniciSifresi VARCHAR(255) NOT NULL,   -- bcrypt hash
    KullaniciEposta  VARCHAR(200),
    RolID           VARCHAR(10),
    PRIMARY KEY (KullaniciID),
    FOREIGN KEY (RolID) REFERENCES rol(RolID) ON DELETE SET NULL ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rol_tablo (
    RolID   VARCHAR(10)  NOT NULL,
    TablAdi VARCHAR(200) NOT NULL,
    PRIMARY KEY (RolID, TablAdi),
    FOREIGN KEY (RolID) REFERENCES rol(RolID) ON DELETE CASCADE ON UPDATE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tablo_log (
    LogID       INT AUTO_INCREMENT PRIMARY KEY,
    Tablo       VARCHAR(200) NOT NULL,
    KullaniciID VARCHAR(10),
    IslemTuru   VARCHAR(20)  NOT NULL,   -- OLUSTUR | YUKLE | SIL
    Eklenen     INT DEFAULT 0,
    Atlanan     INT DEFAULT 0,
    Tekrar      INT DEFAULT 0,
    IslemTarihi VARCHAR(30)  NOT NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kullanici_tercih (
    KullaniciID    VARCHAR(10)  NOT NULL,
    TercihAnahtar  VARCHAR(50)  NOT NULL,
    TercihDeger    TEXT,
    PRIMARY KEY (KullaniciID, TercihAnahtar),
    FOREIGN KEY (KullaniciID) REFERENCES kullanici(KullaniciID) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ─── TEMEL YETKİLER ─────────────────────────────────────────
-- Y000001: Kullanıcı Yönetimi
-- Y000002: Rol & Yetki Yönetimi
-- Y000003: Tablo Oluşturma (Excel → MySQL)
-- Y000004: Tabloya Yükleme (Excel → Mevcut Tablo)
-- Y000005: Tablo Silme

INSERT IGNORE INTO yetki (YetkiID, YetkiAdi) VALUES
    ('Y000001', 'Kullanıcı Yönetimi'),
    ('Y000002', 'Rol ve Yetki Yönetimi'),
    ('Y000003', 'Tablo Oluşturma'),
    ('Y000004', 'Tabloya Veri Yükleme'),
    ('Y000005', 'Tablo Silme');

-- ─── ÖRNEK VERİ ─────────────────────────────────────────────
-- Admin rolü — tüm yetkiler
INSERT IGNORE INTO rol (RolID, RolAdi) VALUES ('R000001', 'Admin');
INSERT IGNORE INTO rol_yetki (RolID, YetkiID) VALUES
    ('R000001', 'Y000001'),
    ('R000001', 'Y000002'),
    ('R000001', 'Y000003'),
    ('R000001', 'Y000004'),
    ('R000001', 'Y000005');

-- Admin kullanıcısı (şifre: 102030 → bcrypt hash)
-- NOT: İlk girişte uygulama otomatik olarak hash'e geçirir.
--      Veya aşağıdaki hash'i Python ile üretebilirsiniz:
--      python -c "from werkzeug.security import generate_password_hash; print(generate_password_hash('102030'))"
INSERT IGNORE INTO kullanici (KullaniciID, KullaniciAdi, KullaniciSifresi, KullaniciEposta, RolID)
VALUES ('K000001', 'selim.kilic', '102030', 'selim@example.com', 'R000001');
-- ↑ İlk girişte düz metin şifre otomatik hash'lenecektir.

-- ─── YENİ TABLOLAR (v2) ─────────────────────────────────────────────────────

-- Audit log: login, kullanıcı/rol değişiklikleri, tablo işlemleri
CREATE TABLE IF NOT EXISTS audit_log (
    LogID        INT AUTO_INCREMENT PRIMARY KEY,
    KullaniciID  VARCHAR(10),
    IslemKodu    VARCHAR(30)  NOT NULL,
    Detay        VARCHAR(500),
    IP           VARCHAR(45),
    IslemTarihi  VARCHAR(30)  NOT NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Y000006: Tablo Görüntüleme (tablo_goruntule sayfası için)
INSERT IGNORE INTO yetki (YetkiID, YetkiAdi) VALUES ('Y000006', 'Tablo Görüntüleme ve Export');
-- Admin rolüne yeni yetkiyi de ekle
INSERT IGNORE INTO rol_yetki (RolID, YetkiID) VALUES ('R000001', 'Y000006');

-- ─── ETL MODÜLÜ (v3) ─────────────────────────────────────────────────────────

-- Dizin yapısı (2 seviye: bölüm → alt dizin)
CREATE TABLE IF NOT EXISTS dizin (
    DizinID          VARCHAR(20)  NOT NULL PRIMARY KEY,
    DizinAdi         VARCHAR(100) NOT NULL,
    UstDizinID       VARCHAR(20)  NULL,
    Aciklama         VARCHAR(300) NULL,
    OlusturmaTarihi  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    OlusturanID      VARCHAR(10)  NULL,
    FOREIGN KEY (UstDizinID) REFERENCES dizin(DizinID) ON DELETE SET NULL,
    FOREIGN KEY (OlusturanID) REFERENCES kullanici(KullaniciID) ON DELETE SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Dizin yetkileri (rol veya kullanıcı bazlı)
CREATE TABLE IF NOT EXISTS dizin_yetki (
    YetkiID      INT          AUTO_INCREMENT PRIMARY KEY,
    DizinID      VARCHAR(20)  NOT NULL,
    RolID        VARCHAR(10)  NULL,
    KullaniciID  VARCHAR(10)  NULL,
    YetkiTipi   ENUM('okuma','yazma') NOT NULL DEFAULT 'okuma',
    FOREIGN KEY (DizinID)     REFERENCES dizin(DizinID)      ON DELETE CASCADE,
    FOREIGN KEY (RolID)       REFERENCES rol(RolID)           ON DELETE CASCADE,
    FOREIGN KEY (KullaniciID) REFERENCES kullanici(KullaniciID) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Dizin onaylayan tanımı
CREATE TABLE IF NOT EXISTS dizin_onaylayan (
    ID           INT         AUTO_INCREMENT PRIMARY KEY,
    DizinID      VARCHAR(20) NOT NULL,
    OnaylayanID  VARCHAR(10) NOT NULL,
    OnayTipi     ENUM('dizin','yonetici') NOT NULL DEFAULT 'dizin',
    FOREIGN KEY (DizinID)     REFERENCES dizin(DizinID)        ON DELETE CASCADE,
    FOREIGN KEY (OnaylayanID) REFERENCES kullanici(KullaniciID) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Yüklenen Excel dosyaları (her versiyon ayrı satır)
CREATE TABLE IF NOT EXISTS excel_dosya (
    DosyaID          VARCHAR(36)   NOT NULL PRIMARY KEY,  -- UUID
    DizinID          VARCHAR(20)   NOT NULL,
    DosyaAdi         VARCHAR(255)  NOT NULL,
    OrijinalAd       VARCHAR(255)  NOT NULL,
    HedefTablo       VARCHAR(100)  NULL,
    Durum            ENUM('bekliyor','onaylandi','reddedildi','islendi','hata') NOT NULL DEFAULT 'bekliyor',
    YukleyenID       VARCHAR(10)   NOT NULL,
    YuklemeTarihi    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DosyaYolu        VARCHAR(500)  NOT NULL,
    DosyaHash        VARCHAR(64)   NULL,
    DosyaBoyutu      INT           NULL,
    SatirSayisi      INT           NULL,
    OncekiDosyaID    VARCHAR(36)   NULL,
    Notlar           VARCHAR(500)  NULL,
    FOREIGN KEY (DizinID)       REFERENCES dizin(DizinID)          ON DELETE RESTRICT,
    FOREIGN KEY (YukleyenID)    REFERENCES kullanici(KullaniciID)   ON DELETE RESTRICT,
    FOREIGN KEY (OncekiDosyaID) REFERENCES excel_dosya(DosyaID)     ON DELETE SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Dosya bazlı özel yetki kısıtlaması
CREATE TABLE IF NOT EXISTS dosya_yetki (
    ID           INT         AUTO_INCREMENT PRIMARY KEY,
    DosyaID      VARCHAR(36) NOT NULL,
    KullaniciID  VARCHAR(10) NOT NULL,
    FOREIGN KEY (DosyaID)     REFERENCES excel_dosya(DosyaID)      ON DELETE CASCADE,
    FOREIGN KEY (KullaniciID) REFERENCES kullanici(KullaniciID)     ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Onay / red geçmişi
CREATE TABLE IF NOT EXISTS excel_onay (
    OnayID       INT         AUTO_INCREMENT PRIMARY KEY,
    DosyaID      VARCHAR(36) NOT NULL,
    OnaylayanID  VARCHAR(10) NOT NULL,
    Karar        ENUM('onaylandi','reddedildi') NOT NULL,
    Aciklama     VARCHAR(500) NULL,
    KararTarihi  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (DosyaID)     REFERENCES excel_dosya(DosyaID)       ON DELETE CASCADE,
    FOREIGN KEY (OnaylayanID) REFERENCES kullanici(KullaniciID)      ON DELETE RESTRICT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Tablo yükleme konfigürasyonu
CREATE TABLE IF NOT EXISTS tablo_konfig (
    KonfigID       INT          AUTO_INCREMENT PRIMARY KEY,
    TabloAdi       VARCHAR(100) NOT NULL UNIQUE,
    YukleModu      ENUM('truncate','incremental') NOT NULL DEFAULT 'truncate',
    BeforeSP       VARCHAR(200) NULL,
    AfterSP        VARCHAR(200) NULL,
    ArtanAnahtar   VARCHAR(100) NULL,
    OnayGerekli    BOOLEAN      NOT NULL DEFAULT TRUE,
    AktifMi        BOOLEAN      NOT NULL DEFAULT TRUE,
    Aciklama       VARCHAR(300) NULL,
    GuncellemeTarihi DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Kalite kontrol kuralları
CREATE TABLE IF NOT EXISTS kalite_kural (
    KuralID      INT          AUTO_INCREMENT PRIMARY KEY,
    TabloAdi     VARCHAR(100) NOT NULL,
    SutunAdi     VARCHAR(100) NOT NULL,
    KuralTipi    ENUM('tip','bos','min','max','regex','anomali') NOT NULL,
    KuralDeger   VARCHAR(300) NULL,
    HataSeviyesi ENUM('uyari','hata') NOT NULL DEFAULT 'hata',
    Aciklama     VARCHAR(300) NULL,
    AktifMi      BOOLEAN      NOT NULL DEFAULT TRUE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Periyodik SP görevleri
CREATE TABLE IF NOT EXISTS cron_gorev (
    GorevID       INT          AUTO_INCREMENT PRIMARY KEY,
    GorevAdi      VARCHAR(100) NOT NULL,
    SpAdi         VARCHAR(200) NOT NULL,
    CronIfade     VARCHAR(100) NOT NULL,
    SonCalisma    DATETIME     NULL,
    SonDurum      ENUM('basarili','hata','calisiyor') NULL,
    SonMesaj      TEXT         NULL,
    Aktif         BOOLEAN      NOT NULL DEFAULT TRUE,
    OlusturanID   VARCHAR(10)  NULL,
    FOREIGN KEY (OlusturanID) REFERENCES kullanici(KullaniciID) ON DELETE SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Yükleme detay logu (kalite, SP, işleme adımları)
CREATE TABLE IF NOT EXISTS yukle_log (
    LogID        INT         AUTO_INCREMENT PRIMARY KEY,
    DosyaID      VARCHAR(36) NOT NULL,
    IslemTipi    ENUM('kalite_kontrol','before_sp','veri_yukleme','after_sp','cron_sp') NOT NULL,
    Durum        ENUM('basarili','hata','uyari') NOT NULL,
    Mesaj        TEXT        NULL,
    Detay        TEXT        NULL,
    EklenenSatir INT         NULL,
    HataliSatir  INT         NULL,
    SureMs       INT         NULL,
    Tarih        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (DosyaID) REFERENCES excel_dosya(DosyaID) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Sistem içi bildirimler
CREATE TABLE IF NOT EXISTS bildirim (
    BildirimID   INT         AUTO_INCREMENT PRIMARY KEY,
    AliciID      VARCHAR(10) NOT NULL,
    Tip          ENUM('onay_bekliyor','onaylandi','reddedildi','kalite_hatasi','cron_hata','sistem') NOT NULL,
    Baslik       VARCHAR(200) NOT NULL,
    Mesaj        VARCHAR(500) NULL,
    DosyaID      VARCHAR(36) NULL,
    Okundu       BOOLEAN     NOT NULL DEFAULT FALSE,
    Tarih        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (AliciID)  REFERENCES kullanici(KullaniciID) ON DELETE CASCADE,
    FOREIGN KEY (DosyaID)  REFERENCES excel_dosya(DosyaID)   ON DELETE SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ─── YENİ YETKİLER ───────────────────────────────────────────────────────────
INSERT IGNORE INTO yetki (YetkiID, YetkiAdi) VALUES
    ('Y000007', 'Dizin Yönetimi'),
    ('Y000008', 'Excel Dosya Yükleme'),
    ('Y000009', 'Excel Dosya Onaylama'),
    ('Y000010', 'Tablo Konfigürasyonu'),
    ('Y000011', 'Kalite Kural Yönetimi'),
    ('Y000012', 'Cron Görev Yönetimi');

-- Admin rolüne yeni yetkiler
INSERT IGNORE INTO rol_yetki (RolID, YetkiID) VALUES
    ('R000001', 'Y000007'),
    ('R000001', 'Y000008'),
    ('R000001', 'Y000009'),
    ('R000001', 'Y000010'),
    ('R000001', 'Y000011'),
    ('R000001', 'Y000012');

-- ─── ÖRNEK DİZİNLER ──────────────────────────────────────────────────────────
INSERT IGNORE INTO dizin (DizinID, DizinAdi, UstDizinID, Aciklama) VALUES
    ('D000001', 'Satış',   NULL, 'Satış bölümü dosyaları'),
    ('D000002', 'Finans',  NULL, 'Finans bölümü dosyaları'),
    ('D000003', 'İK',      NULL, 'İnsan kaynakları dosyaları'),
    ('D000004', 'Aylık Hedefler',  'D000001', 'Satış aylık hedef dosyaları'),
    ('D000005', 'Müşteri Listesi', 'D000001', 'Satış müşteri listeleri');
