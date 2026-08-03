# ── Build aşaması ──────────────────────────────────────────────────────────
FROM python:3.11-slim AS base

WORKDIR /app

# Sistem bağımlılıkları (mysql-connector için)
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-libmysqlclient-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Önce sadece requirements kopyala (katman önbellekleme için)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama kodunu kopyala
COPY . .

# Yükleme klasörünü oluştur
RUN mkdir -p uploads

# Güvenlik: root olmayan kullanıcı ile çalıştır
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser:appuser /app
USER appuser

# Port
EXPOSE 5000

# Üretim için gunicorn kullan
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "--timeout", "120", "app:app"]
