#!/bin/bash
# DataPortal — Contabo VPS Kurulum Scripti
# Kullanım: bash deploy.sh
# Çalıştır: /root/DataPortal_son/ dizininde

set -e

echo "═══════════════════════════════════════"
echo "  DataPortal Kurulum"
echo "═══════════════════════════════════════"

# .env kontrolü
if [ ! -f .env ]; then
    echo "❌ .env dosyası bulunamadı!"
    echo "   cp .env.example .env  →  sonra düzenle"
    exit 1
fi

# Dizinler
mkdir -p uploads excel_store
touch dataportal.log

# Docker compose
echo "▶ Docker image build ediliyor..."
docker compose build --no-cache

echo "▶ Servisler başlatılıyor..."
docker compose up -d

echo "▶ DB hazır olana kadar bekleniyor..."
sleep 15

echo "▶ Servis durumları:"
docker compose ps

echo ""
echo "✅ Tamamlandı!"
echo "   Uygulama: http://$(hostname -I | awk '{print $1}'):5001"
echo ""
echo "⚠️  İlk girişten önce admin şifresini init.sql'e göre ayarlayın!"
echo "   Veya container içinde şifre üretin:"
echo "   docker exec dataportal_son-web-1 python3 -c \\"
echo "     \"from werkzeug.security import generate_password_hash; print(generate_password_hash('YeniSifre123!'))\""
