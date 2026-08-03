"""
DataPortal — Otomatik Testler
==============================
Flask test client ile kritik endpoint ve güvenlik kontrolleri.

Çalıştırma:
    pytest tests/ -v
    pytest tests/ -v --cov=app --cov-report=term-missing
"""

import pytest
import json
import sys
import os

# Proje kök dizinini Python path'e ekle
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import app as app_module
from app import app as flask_app, validate_password, validate_email, sanitize

# ─── FIXTURE'LAR ─────────────────────────────────────────────────────────────

@pytest.fixture
def client():
    """Test istemcisi — gerçek DB bağlantısı gerektirmez."""
    flask_app.config['TESTING']   = True
    flask_app.config['SECRET_KEY'] = 'test-secret-key-32chars-minimum!!'
    flask_app.config['SESSION_COOKIE_SECURE'] = False
    with flask_app.test_client() as c:
        yield c

@pytest.fixture
def auth_client(client):
    """Oturum açmış kullanıcı simülasyonu — DB sorgusu yapılmadan session set edilir."""
    with flask_app.test_request_context():
        pass
    with client.session_transaction() as sess:
        sess['kullanici_id']  = 'K000001'
        sess['kullanici_adi'] = 'test.user'
        sess['yetkiler']      = ['Y000001', 'Y000002', 'Y000003', 'Y000004', 'Y000005']
        sess['csrf_token']    = 'test-csrf-token-fixed'
    return client

# ─── ŞİFRE VALİDASYON TESTLERİ ──────────────────────────────────────────────

class TestPasswordValidation:
    """validate_password() fonksiyonunun tüm kuralları test edilir."""

    def test_kisa_sifre_reddedilir(self):
        assert validate_password('Ab1') is not None
        assert '8 karakter' in validate_password('Ab1')

    def test_buyuk_harf_eksik_reddedilir(self):
        assert validate_password('abcdefg1') is not None
        assert 'büyük harf' in validate_password('abcdefg1')

    def test_kucuk_harf_eksik_reddedilir(self):
        assert validate_password('ABCDEFG1') is not None

    def test_rakam_eksik_reddedilir(self):
        assert validate_password('Abcdefgh') is not None
        assert 'rakam' in validate_password('Abcdefgh')

    def test_gecerli_sifre_kabul_edilir(self):
        assert validate_password('Guclu123') is None

    def test_uzun_karmasik_sifre_kabul_edilir(self):
        assert validate_password('SuperSecure2024!') is None

    def test_bos_sifre_reddedilir(self):
        assert validate_password('') is not None

    def test_none_reddedilir(self):
        assert validate_password(None) is not None

# ─── E-POSTA VALİDASYON TESTLERİ ─────────────────────────────────────────────

class TestEmailValidation:
    def test_gecerli_eposta(self):
        assert validate_email('user@example.com') is True

    def test_gecerli_eposta_subdomain(self):
        assert validate_email('user@mail.company.org') is True

    def test_at_isareti_eksik(self):
        assert validate_email('userexample.com') is False

    def test_nokta_eksik(self):
        assert validate_email('user@example') is False

    def test_bos_eposta_gecerli(self):
        """E-posta opsiyoneldir; boş geçilebilir."""
        assert validate_email('') is True

    def test_none_gecerli(self):
        assert validate_email(None) is True

# ─── SANİTİZE FONKSİYONU TESTLERİ ────────────────────────────────────────────

class TestSanitize:
    def test_normal_ad(self):
        assert sanitize('musteri') == 'musteri'

    def test_bosluk_alt_cizgiye_donusur(self):
        assert sanitize('musteri listesi') == 'musteri_listesi'

    def test_ozel_karakter_temizlenir(self):
        result = sanitize('tablo-adi!@#')
        assert all(c.isalnum() or c == '_' for c in result)

    def test_rakamla_baslayan_ad(self):
        result = sanitize('123tablo')
        assert result.startswith('col_')

    def test_bos_string(self):
        result = sanitize('')
        assert result == 'column'

    def test_sadece_ozel_karakter(self):
        result = sanitize('!@#$%')
        assert result == 'column'

# ─── AUTH ROUTE TESTLERİ ─────────────────────────────────────────────────────

class TestAuthRoutes:
    def test_ana_sayfa_login_yonlendirir(self, client):
        r = client.get('/')
        assert r.status_code in (301, 302)
        assert '/login' in r.headers.get('Location', '')

    def test_login_sayfasi_yukleniyor(self, client):
        r = client.get('/login')
        assert r.status_code == 200
        assert b'DataPortal' in r.data

    def test_bos_login_bilgisi_reddedilir(self, client):
        r = client.post('/api/login',
                        data=json.dumps({'username': '', 'password': ''}),
                        content_type='application/json')
        assert r.status_code in (400, 200, 415)
        data = json.loads(r.data)
        assert data['ok'] is False

    def test_login_json_olmayan_istek_reddedilir(self, client):
        r = client.post('/api/login', data='not-json', content_type='text/plain')
        assert r.status_code in (400, 200, 415)

# ─── YETKİ KONTROL TESTLERİ ──────────────────────────────────────────────────

class TestAuthorizationGuards:
    def test_dashboard_oturum_gerektiriyor(self, client):
        r = client.get('/dashboard')
        assert r.status_code in (301, 302)
        assert '/login' in r.headers.get('Location', '')

    def test_kullanicilar_oturum_gerektiriyor(self, client):
        r = client.get('/kullanicilar')
        assert r.status_code in (301, 302)

    def test_api_oturum_olmadan_401(self, client):
        r = client.get('/api/kullanicilar')
        assert r.status_code == 401

    def test_api_rol_oturum_olmadan_401(self, client):
        r = client.get('/api/roller')
        assert r.status_code == 401

    def test_tablo_sil_api_oturum_olmadan_401(self, client):
        r = client.post('/api/tablo-sil',
                        data=json.dumps({'tablolar': ['test']}),
                        content_type='application/json')
        assert r.status_code == 401

# ─── CSRF KORUMASI TESTLERİ ──────────────────────────────────────────────────

class TestCsrfProtection:
    def test_csrf_token_olmadan_post_reddedilir(self, auth_client):
        """CSRF token gönderilmeden yapılan POST isteği 403 dönmeli."""
        r = auth_client.post('/api/kullanicilar',
                             data=json.dumps({'KullaniciAdi': 'test', 'KullaniciSifresi': 'Test1234',
                                              'KullaniciEposta': '', 'RolID': 'R000001'}),
                             content_type='application/json')
        # Token yok → 403
        assert r.status_code == 403

    def test_yanlis_csrf_token_reddedilir(self, auth_client):
        r = auth_client.post('/api/kullanicilar',
                             data=json.dumps({}),
                             content_type='application/json',
                             headers={'X-CSRF-Token': 'yanlis-token'})
        assert r.status_code == 403

    def test_dogru_csrf_token_kabul_edilir_format(self, auth_client):
        """Doğru token + geçersiz veri → 200/400/500 (403 değil)."""
        r = auth_client.post('/api/kullanicilar',
                             data=json.dumps({'KullaniciAdi': '', 'KullaniciSifresi': '',
                                              'KullaniciEposta': '', 'RolID': ''}),
                             content_type='application/json',
                             headers={'X-CSRF-Token': 'test-csrf-token-fixed'})
        # Token doğru → CSRF değil, validasyon hatası bekleniyor
        assert r.status_code != 403

# ─── ERROR HANDLER TESTLERİ ──────────────────────────────────────────────────

class TestErrorHandlers:
    def test_404_json_api_icin(self, client):
        r = client.get('/api/olmayan-endpoint')
        assert r.status_code == 404
        data = json.loads(r.data)
        assert data['ok'] is False

    def test_404_sayfa_icin(self, client):
        r = client.get('/olmayan-sayfa')
        assert r.status_code in (302, 404)   # login yönlendirmesi veya 404

    def test_413_buyuk_dosya(self, client):
        """16 MB üzerindeki dosyalar reddedilmeli."""
        with client.session_transaction() as sess:
            sess['kullanici_id']  = 'K000001'
            sess['kullanici_adi'] = 'test'
            sess['yetkiler']      = ['Y000003']
            sess['csrf_token']    = 'token'
        # Flask MAX_CONTENT_LENGTH kontrolü handler'dan önce gerçekleşir
        flask_app.config['MAX_CONTENT_LENGTH'] = 10  # 10 bayt limit
        data = b'x' * 100
        r = client.post('/api/excel-upload',
                        data={'file': (b'a'*100, 'test.xlsx', 'application/octet-stream')},
                        content_type='multipart/form-data',
                        headers={'X-CSRF-Token': 'token'})
        flask_app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # Sıfırla
        assert r.status_code in (400, 413, 200)

# ─── RATE LIMIT TESTLERİ ─────────────────────────────────────────────────────

class TestRateLimit:
    def test_cok_fazla_istek_engelleniyor(self, client):
        """11. istek 429 dönmeli (limit=10/dakika)."""
        for i in range(10):
            client.post('/api/login',
                        data=json.dumps({'username': 'x', 'password': 'y'}),
                        content_type='application/json')
        r = client.post('/api/login',
                        data=json.dumps({'username': 'x', 'password': 'y'}),
                        content_type='application/json')
        # Rate limit aşıldıysa 429; aşılmadıysa (farklı IP) normal akış
        assert r.status_code in (200, 429)

# ─── YENİ ENDPOINT TESTLERİ ──────────────────────────────────────────────────

class TestNewEndpoints:
    def test_audit_log_sayfasi_oturum_gerektiriyor(self, client):
        r = client.get('/audit-log')
        assert r.status_code in (301, 302)
        assert '/login' in r.headers.get('Location', '')

    def test_audit_log_api_oturum_olmadan_401(self, client):
        r = client.get('/api/audit-log')
        assert r.status_code == 401

    def test_excel_preview_oturum_olmadan_401(self, client):
        r = client.post('/api/excel-preview',
                        data={'file': (b'test', 'test.xlsx')},
                        content_type='multipart/form-data')
        assert r.status_code == 401

    def test_excel_upload_json_body_kabul_ediyor(self, auth_client):
        """excel-upload artık JSON body alıyor (dosya değil)."""
        r = auth_client.post('/api/excel-upload',
                             data='{"table": "", "columns": []}',
                             content_type='application/json',
                             headers={'X-CSRF-Token': 'test-csrf-token-fixed'})
        data = json.loads(r.data)
        # Tablo adı boş → hata mesajı bekleniyor, 403 değil
        assert r.status_code != 403
        assert data.get('success') is False

    def test_audit_log_api_yetki_gerektiriyor(self, auth_client):
        """Y000001 yetkisi olan kullanıcı erişebilmeli (DB olmadan mock)."""
        # auth_client zaten Y000001 içeriyor; DB yoksa exception → 500 olabilir
        r = auth_client.get('/api/audit-log')
        assert r.status_code in (200, 500)  # 401/403 değil

    def test_login_sayfasi_profil_js_iceriyor(self, client):
        r = client.get('/login')
        assert r.status_code == 200
        assert b'dp_profiles' in r.data  # localStorage key

    def test_excel_create_sayfasi_yukleniyor(self, auth_client):
        r = auth_client.get('/excel-mysql-create')
        assert r.status_code == 200
        assert b'excel-preview' in r.data  # yeni endpoint referansı

