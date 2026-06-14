#!/data/data/com.termux/files/usr/bin/bash

# --- OTOMATİK TEMİZLİK (CTRL+Z ASILI KALANLARI ÖLDÜRÜR) ---
MEVCUT_PID=$$
ESKI_SURECLER=$(pgrep -f "muzik_isleyici.sh")
for pid in $ESKI_SURECLER; do
    if [ "$pid" != "$MEVCUT_PID" ]; then 
        kill -9 "$pid" 2>/dev/null
    fi
done

# --- AYARLAR VE HAFIZA ---
AYARLAR="$HOME/.muzik_isleyici.conf"
[ -f "$AYARLAR" ] && source "$AYARLAR"

PREFIX="〖ذال فیلم تقدیم میکندょ〗"

# Neon Renk Seti
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
WHITE='\033[1;37m'; RESET='\033[0m'

_kaydet_ayarlar() {
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$AYARLAR"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$AYARLAR"
}

_ilerleme_goster() {
    local yuzde=$(( $1 * 100 / $2 ))
    local dolu=$(( yuzde / 5 )); local bos=$(( 20 - dolu ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  ${CYAN}[${GREEN}%s${CYAN}] ${YELLOW}%3d%% ${MAGENTA}(%d/%d)${RESET}" "$bar" "$yuzde" "$1" "$2"
}

# --- ANA MOTOR ---
clear
echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
# Görünen PC modu yazısı tamamen kaldırıldı, ekran tertemiz
echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
echo -e "${MAGENTA}│${CYAN}    🎬   VİDEO -> MP3 SES VE KAPAK MOTORU                ${MAGENTA}│${RESET}"
echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
echo -e "  ${CYAN}Son Resim :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"

# Kullanıcı Girişleri
read -p $'\n  Video Klasör Yolu: ' girilen_klasor
[ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
if [ -z "$girilen_klasor" ] || [ ! -d "$girilen_klasor" ]; then
    echo -e "  ${RED}✗ HATA: Klasör bulunamadı!${RESET}"; sleep 2; exit 1
fi

read -p "  Kapak Resmi Yolu: " girilen_resim
[ -z "$girilen_resim" ] && girilen_resim="$VARSAYILAN_RESIM"
if [ -z "$girilen_resim" ] || [ ! -f "$girilen_resim" ]; then
    echo -e "  ${RED}✗ HATA: Resim dosyası bulunamadı!${RESET}"; sleep 2; exit 1
fi

VARSAYILAN_KLASOR="$girilen_klasor"
VARSAYILAN_RESIM="$girilen_resim"
_kaydet_ayarlar

# Bulunduğu klasörde listeleme yapar (Kopyalama Asla Yok!)
TEMP_LIST="$HOME/.mp3_tarama_tmp.txt"
find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) > "$TEMP_LIST" 2>/dev/null
toplam=$(wc -l < "$TEMP_LIST")

if [ "$toplam" -eq 0 ]; then
    echo -e "  ${RED}✗ Klasörde işlenecek video bulunamadı!${RESET}"
    rm -f "$TEMP_LIST"; sleep 2; exit 1
fi

# Çıktı klasörü videoların hemen yanında açılır
CIKTI_DIR="$VARSAYILAN_KLASOR/MP3_Muzikler"
mkdir -p "$CIKTI_DIR"

echo -e "\n  ${GREEN}➔ İşlem Başladı, Dönüştürülüyor...${RESET}"
islem_sayisi=0

while IFS= read -r video; do
    islem_sayisi=$((islem_sayisi + 1))
    _ilerleme_goster "$islem_sayisi" "$toplam"
    
    isim=$(basename "$video")
    isim_base="${isim%.*}"
    
    # Prefix temizleme kontrolü (Çift etiket olmasın diye)
    if [[ "$isim_base" == "$PREFIX"* ]]; then
        temiz_isim="${isim_base#$PREFIX}"
    else
        temiz_isim="$isim_base"
    fi

    # --- KESİN ÇÖZÜM PARAMETRELERİ ---
    # Videonun olduğu yerde temp oluşturur, kopyalama yapmaz.
    # -disposition:v attached_pic -> Resmi müzik çalar albüm kapağı yapar.
    # -id3v2_version 3 -> MT Manager'da resmin doğrudan görünmesini sağlar.
    ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -vn \
        -map 0:a:0 -map 1:v:0 -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 \
        -c:v mjpeg -pix_fmt yuvj420p -disposition:v attached_pic \
        -id3v2_version 3 -metadata title="$temiz_isim" -metadata album="Zal Film" \
        "$CIKTI_DIR/${PREFIX}${temiz_isim}.mp3" -y -loglevel quiet 2>/dev/null

done < "$TEMP_LIST"
rm -f "$TEMP_LIST"

echo -e "\n\n${GREEN}  ✓ İşlem Başarıyla Bitti Kanka!${RESET}"
echo -e "  ${BLUE}➔ Müzikler şurada: $CIKTI_DIR${RESET}\n"
exit 0
