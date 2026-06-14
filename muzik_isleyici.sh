#!/data/data/com.termux/files/usr/bin/bash

# --- OTOMATİK TEMİZLİK (CTRL+Z ASILI KALANLARI ÖLDÜRÜR) ---
MEVCUT_PID=$$
ESKI_SURECLER=$(pgrep -f "muzik_isleyici.sh")
for pid in $ESKI_SURECLER; do
    if [ "$pid" != "$MEVCUT_PID" ]; then kill -9 "$pid" 2>/dev/null; fi
done

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

# === SEÇENEK 1: VİDEODAN MP3'E DÖNÜŞTÜRÜCÜ ===
video_to_mp3() {
    clear
    echo -e "${CYAN}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│        🚀  SEÇENEK 1: VİDEO -> MP3 SES MOTORU          │${RESET}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────┘${RESET}"
    
    read -p "  [ENTER] veya Video Klasör Yolu: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then echo -e "  ${RED}✗ Klasör bulunamadı!${RESET}"; sleep 2; return; fi
    
    read -p "  [ENTER] veya Kapak Resmi Yolu: " girilen_resim
    [ -z "$girilen_resim" ] && girilen_resim="$VARSAYILAN_RESIM"
    if [ ! -f "$girilen_resim" ]; then echo -e "  ${RED}✗ Resim bulunamadı!${RESET}"; sleep 2; return; fi

    VARSAYILAN_KLASOR="$girilen_klasor"; VARSAYILAN_RESIM="$girilen_resim"; _kaydet_ayarlar
    
    TEMP_LIST="$HOME/.mp3_conv_tmp.txt"
    find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) > "$TEMP_LIST" 2>/dev/null
    toplam=$(wc -l < "$TEMP_LIST")
    
    if [ "$toplam" -eq 0 ]; then echo -e "  ${RED}✗ Video bulunamadı!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; return; fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/MP3_Muzikler"
    mkdir -p "$CIKTI_DIR"

    echo -e "\n  ${GREEN}➔ Dönüştürme ve Zal Film Kapak Gömme Başladı...${RESET}"
    islem=0
    while IFS= read -r video; do
        islem=$((islem + 1))
        _ilerleme_goster "$islem" "$toplam"
        isim=$(basename "$video"); isim_base="${isim%.*}"
        
        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -vn -map 0:a:0 -map 1:v:0 -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 -c:v mjpeg -pix_fmt yuvj420p -disposition:v attached_pic -id3v2_version 3 -metadata title="$isim_base" -metadata album="Zal Film" "$CIKTI_DIR/${PREFIX}${isim_base}.mp3" -y -loglevel quiet 2>/dev/null
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"
    echo -e "\n\n  ${GREEN}✓ MP3 Dönüşümü Bitti! Klasör: $CIKTI_DIR${RESET}"; read -p "  Enter..." _; return
}

# === SEÇENEK 2: HAZIR MP3'LERİN KAPAK RESMİNİ VE ETİKETİNİ GÜNCELLEME ===
mp3_kapak_degistir() {
    clear
    echo -e "${YELLOW}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${YELLOW}│      🎶  SEÇENEK 2: MP3 KAPAK & ZAL FİLM ETİKETLEME    │${RESET}"
    echo -e "${YELLOW}└────────────────────────────────────────────────────────┘${RESET}"
    
    read -p "  [ENTER] veya MP3 Klasör Yolu: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then echo -e "  ${RED}✗ Klasör bulunamadı!${RESET}"; sleep 2; return; fi
    
    read -p "  [ENTER] veya Yeni Kapak Resmi Yolu: " girilen_resim
    [ -z "$girilen_resim" ] && girilen_resim="$VARSAYILAN_RESIM"
    if [ ! -f "$girilen_resim" ]; then echo -e "  ${RED}✗ Resim bulunamadı!${RESET}"; sleep 2; return; fi

    VARSAYILAN_KLASOR="$girilen_klasor"; VARSAYILAN_RESIM="$girilen_resim"; _kaydet_ayarlar
    
    TEMP_LIST="$HOME/.mp3_tag_tmp.txt"
    find "$VARSAYILAN_KLASOR" -maxdepth 1 -iname "*.mp3" > "$TEMP_LIST" 2>/dev/null
    toplam=$(wc -l < "$TEMP_LIST")
    
    if [ "$toplam" -eq 0 ]; then echo -e "  ${RED}✗ Klasörde MP3 bulunamadı!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; return; fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/ZalFilm_Kapakli_MP3ler"
    mkdir -p "$CIKTI_DIR"

    echo -e "\n  ${GREEN}➔ MP3 Kapakları Değiştiriliyor ve Etiket Basılıyor...${RESET}"
    islem=0
    while IFS= read -r mp3; do
        islem=$((islem + 1))
        _ilerleme_goster "$islem" "$toplam"
        isim=$(basename "$mp3"); isim_base="${isim%.*}"
        
        # Eğer ismin başında zaten prefix varsa çift eklemesin diye temizliyoruz
        if [[ "$isim_base" == "$PREFIX"* ]]; then temiz_isim="${isim_base#$PREFIX}"; else temiz_isim="$isim_base"; fi
        
        # Sadece kapak ve metadata günceller, sesi bozmaz veya sıkıştırmaz (-c:a copy)
        ffmpeg -i "$mp3" -i "$VARSAYILAN_RESIM" -map 0:a:0 -map 1:v:0 -c:a copy -c:v mjpeg -pix_fmt yuvj420p -disposition:v attached_pic -id3v2_version 3 -metadata title="$temiz_isim" -metadata album="Zal Film" "$CIKTI_DIR/${PREFIX}${temiz_isim}.mp3" -y -loglevel quiet 2>/dev/null
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"
    echo -e "\n\n  ${GREEN}✓ Kapak Değiştirme Bitti! Klasör: $CIKTI_DIR${RESET}"; read -p "  Enter..." _; return
}

# === SEÇENEK 3: İSİM VE METADATA TEMİZLEYİCİ ===
mp3_isim_temizle() {
    clear
    echo -e "${RED}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${RED}│      🧹  SEÇENEK 3: SAF MP3 / METADATA & İSİM SİLİCİ    │${RESET}"
    echo -e "${RED}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${YELLOW}Not: Bu işlem isimdeki tüm etiketleri siler ve metadatayı sıfırlar!${RESET}"
    
    read -p $'\n  [ENTER] veya Temizlenecek MP3 Klasör Yolu: ' girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then echo -e "  ${RED}✗ Klasör bulunamadı!${RESET}"; sleep 2; return; fi

    VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar
    
    TEMP_LIST="$HOME/.mp3_clean_tmp.txt"
    find "$VARSAYILAN_KLASOR" -maxdepth 1 -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.mp3" > "$TEMP_LIST" 2>/dev/null
    toplam=$(wc -l < "$TEMP_LIST")
    
    if [ "$toplam" -eq 0 ]; then echo -e "  ${RED}✗ Klasörde dosya bulunamadı!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; return; fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/Temiz_Muzikler"
    mkdir -p "$CIKTI_DIR"

    echo -e "\n  ${GREEN}➔ Tüm yazılar ve metadatalar kazınıyor...${RESET}"
    islem=0
    while IFS= read -r dosya; do
        islem=$((islem + 1))
        _ilerleme_goster "$islem" "$toplam"
        isim=$(basename "$dosya"); isim_base="${isim%.*}"
        
        # İsimdeki tüm reklam, parantez ve prefix sembollerini kazıyalım
        temiz_isim="$isim_base"
        temiz_isim="${temiz_isim#$PREFIX}" # Bizim prefixi siler
        temiz_isim=$(echo "$temiz_isim" | sed -e 's/〖[^〗]*〗//g' -e 's/【[^】]*】//g' -e 's/\[[^]*]\]//g' -e 's/([^)]*)//g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Eğer isim tamamen boş kalırsa korumaya alalım
        [ -z "$temiz_isim" ] && temiz_isim="Muzik_$islem"

        # -map_metadata -1 komutu şarkının içindeki tüm gizli yazı, site adı ve albümleri tamamen siler siler. Kapağı da sıfırlar.
        if [[ "$dosya" == *".mp3" || "$dosya" == *".MP3" ]]; then
            ffmpeg -i "$dosya" -map_metadata -1 -c:a copy "$CIKTI_DIR/${temiz_isim}.mp3" -y -loglevel quiet 2>/dev/null
        else
            ffmpeg -i "$dosya" -vn -map_metadata -1 -c:a libmp3lame -b:a 192k "$CIKTI_DIR/${temiz_isim}.mp3" -y -loglevel quiet 2>/dev/null
        fi
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"
    echo -e "\n\n  ${GREEN}✓ Temizlik bitti! Sadece tertemiz .mp3 dosyaları kaldı. Klasör: $CIKTI_DIR${RESET}"; read -p "  Enter..." _; return
}

# --- ANA MENÜ PANELİ ---
ana_menu() {
    clear
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${MAGENTA}│${CYAN}    🎬   ZAL FİLM OTO-MATRİX SES VE ETİKET PANELİ        ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Aktif Klasör :${WHITE} ${VARSAYILAN_KLASOR:-'Ayarlanmamış'}${RESET}"
    echo -e "  ${CYAN}Aktif Kapak  :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} Video to MP3 Dönüştür ${MAGENTA}(Zal Film Kapağı Gömerek)${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} Mevcut MP3'lerin Kapak Resmini ve Etiketini Değiştir${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} MP3 İsimlerini ve Metadataları Temizle ${RED}(Sadece .mp3 Bırak)${RESET}"
    echo -e "  ${RED}[4]${WHITE} Güvenli Çıkış${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçiminiz [1-4]: " secim

    case $secim in
        1) video_to_mp3; ana_menu ;;
        2) mp3_kapak_degistir; ana_menu ;;
        3) mp3_isim_temizle; ana_menu ;;
        4) exit 0 ;;
        *) ana_menu ;;
    esac
}

ana_menu
