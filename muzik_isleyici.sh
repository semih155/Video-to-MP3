# Önce eskisini tamamen siliyoruz
rm -rf ~/Video-to-MP3

# Klasörü ve dosyayı tertemiz oluşturuyoruz
mkdir -p ~/Video-to-MP3
cat > ~/Video-to-MP3/muzik_isleyici.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# --- AYARLAR ---
AYARLAR="$HOME/.muzik_isleyici.conf"
[ -f "$AYARLAR" ] && source "$AYARLAR"

# --- KAPAK GÖMME VE DÖNÜŞTÜRME MOTORU ---
# Burada en stabil FFmpeg parametrelerini kullanıyoruz
# Hem kapak resmi gömülür hem de dosya temiz olur.
donustur() {
    local video="$1"
    local kapak="$VARSAYILAN_RESIM"
    local cikti="${video%.*}.mp3"
    
    # FFmpeg ile kapağı MP3 içine ID3v2 tag olarak gömüyoruz
    ffmpeg -i "$video" -i "$kapak" -map 0:a:0 -map 1:v:0 -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 -c:v mjpeg -disposition:v:1 attached_pic -id3v2_version 3 -y -loglevel quiet "$cikti"
}

# --- MENÜ ---
clear
echo "--- MUZİK İŞLEYİCİ (KAPAK GÖMME AKTİF) ---"
read -p "Video Klasör Yolu: " yol
read -p "Kapak Resmi Yolu: " resim
VARSAYILAN_RESIM="$resim"
echo "VARSAYILAN_RESIM=\"$resim\"" > "$AYARLAR"

cd "$yol"
for dosya in *.{mp4,mkv,webm}; do
    [ -f "$dosya" ] || continue
    echo "İşleniyor: $dosya"
    donustur "$dosya"
done
echo "İşlem bitti kanka!"
EOF

# Çalıştırma izinlerini veriyoruz
chmod +x ~/Video-to-MP3/muzik_isleyici.sh

# Alias (Kısayol) kontrolü
sed -i '/alias mp3=/d' ~/.bashrc
echo "alias mp3='bash ~/Video-to-MP3/muzik_isleyici.sh'" >> ~/.bashrc
source ~/.bashrc

echo "Sistem eski sadeliğine geri döndü kanka! Artık 'mp3' yazıp direkt çalıştırabilirsin."
