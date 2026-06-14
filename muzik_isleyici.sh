cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# --- OTOMATİK TEMİZLİK ---
MEVCUT_PID=$$
ESKI_SURECLER=$(pgrep -f "kapak_degistir.sh")
for pid in $ESKI_SURECLER; do
    if [ "$pid" != "$MEVCUT_PID" ]; then kill -9 "$pid" 2>/dev/null; fi
done

[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"
ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

PREFIX="〖ذال فیلم تقدیم میکندょ〗"

# Neon Renk Seti
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
WHITE='\033[1;37m'; RESET='\033[0m'

_kaydet_ayarlar() {
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_MP3_KLASOR=\"$VARSAYILAN_MP3_KLASOR\"" >> "$HOME/.kapak_ayarlari.conf"
}

_zaten_islendi_mi() {
    local aranan="$1"
    while IFS= read -r satir; do [ "$satir" = "$aranan" ] && return 0; done < "$ISLENENLER_LISTESI"
    return 1
}

_ilerleme_goster() {
    local mevcut=$1; local toplam=$2
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 )); local bos=$(( 20 - dolu ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  ${CYAN}[${GREEN}%s${CYAN}] ${YELLOW}%3d%% ${MAGENTA}(%d/%d)${RESET}" "$bar" "$yuzde" "$mevcut" "$toplam"
}

mp3_donusturucu_menu() {
    clear
    echo -e "${YELLOW}┌────────────────────────────────────────┐${RESET}"
    echo -e "${YELLOW}│      🎶  VİDEO -> MP3 SES MOTORU       │${RESET}"
    echo -e "${YELLOW}└────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Aktif Resim :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "${YELLOW}──────────────────────────────────────────${RESET}"
    
    if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}✗ HATA: Önce resim seçin!${RESET}"; sleep 2; ana_menu; return
    fi

    read -p "  [ENTER] veya Video Klasör Yolu: " girilen_mp3_klasor
    [ -z "$girilen_mp3_klasor" ] && girilen_mp3_klasor="$VARSAYILAN_MP3_KLASOR"
    
    if [ ! -d "$girilen_mp3_klasor" ]; then
        echo -e "  ${RED}✗ HATA: Geçersiz klasör!${RESET}"; sleep 2; ana_menu; return
    fi

    VARSAYILAN_MP3_KLASOR="$girilen_mp3_klasor"; _kaydet_ayarlar
    TEMP_MP3_LIST="$HOME/.mp3_listesi_tmp.txt"
    find "$VARSAYILAN_MP3_KLASOR" \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) > "$TEMP_MP3_LIST" 2>/dev/null
    toplam_mp3=$(wc -l < "$TEMP_MP3_LIST")

    [ "$toplam_mp3" -eq 0 ] && { echo -e "  ${RED}✗ Videolu dosya bulunamadı!${RESET}"; rm -f "$TEMP_MP3_LIST"; sleep 2; ana_menu; return; }

    # ÇIKTI KLASÖRÜ: Videolar neredeyse onun içinde "MP3_Muzikler" adında açılır
    CIKTI_MP3_DIR="$VARSAYILAN_MP3_KLASOR/MP3_Muzikler"
    mkdir -p "$CIKTI_MP3_DIR"
    
    echo -e "\n  ${GREEN}➔ Dönüştürme ve Kapak Gömme Başladı...${RESET}"
    mp3_islem_sayisi=0
    while IFS= read -r video; do
        isim=$(basename "$video")
        isim_base="${isim%.*}"
        mp3_islem_sayisi=$((mp3_islem_sayisi + 1))
        _ilerleme_goster "$mp3_islem_sayisi" "$toplam_mp3"
        
        # RESMİ TAM GÖMEN KESİN FFMEG PARAMETRELERİ
        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -vn -map 0:a:0 -map 1:v:0 -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 -c:v mjpeg -pix_fmt yuvj420p -id3v2_version 3 -metadata title="$isim_base" -metadata album="Zal Film" -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "$CIKTI_MP3_DIR/${PREFIX}${isim_base}.mp3" -y -loglevel quiet 2>/dev/null
    done < "$TEMP_MP3_LIST"
    rm -f "$TEMP_MP3_LIST"
    echo -e "\n\n  ${GREEN}✓ MP3 Dönüşümü Bitti! Klasör: $CIKTI_MP3_DIR${RESET}"; read -p "  Enter..." _; ana_menu
}

ana_menu() {
    clear
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${MAGENTA}│${CYAN}    🎬   🎬   ZAL FİLM OTO-MATRİX SİSTEMİ                ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Aktif Kapak :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} Videoların Kapağını Güncelle ${MAGENTA}(Olduğu Yerde/Kopyalamadan)${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} Videoları MP3'e Çevir ve Kapak Göm${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} Hafıza Geçmişini Temizle${RESET}"
    echo -e "  ${YELLOW}[4]${WHITE} Kapak Resmini Seç/Değiştir${RESET}"
    echo -e "  ${RED}[5]${WHITE} Güvenli Çıkış${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçiminiz [1-5]: " secim

    case $secim in
        1)
            if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
                echo -e "  ${RED}✗ HATA: Önce resim seçin (Seçenek 4)!${RESET}"; sleep 2; ana_menu; return
            fi
            echo ""
            read -p "  [ENTER] veya Video Klasör Yolu: " girilen_klasor
            [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
            if [ -z "$girilen_klasor" ] || [ ! -d "$girilen_klasor" ]; then
                echo -e "  ${RED}✗ HATA: Klasör bulunamadı!${RESET}"; sleep 2; ana_menu; return
            fi

            VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar
            TEMP_LIST="$HOME/.video_listesi_tmp.txt"
            
            find "$VARSAYILAN_KLASOR" \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST" 2>/dev/null
            toplam=$(wc -l < "$TEMP_LIST")

            if [ "$toplam" -eq 0 ]; then
                echo -e "  ${RED}✗ Klasörde video yok!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; ana_menu; return
            fi

            islem_sayisi=0
            while IFS= read -r video; do
                isim=$(basename "$video"); klasor=$(dirname "$video")
                _zaten_islendi_mi "$isim" && continue

                islem_sayisi=$((islem_sayisi + 1))
                _ilerleme_goster "$islem_sayisi" "$toplam"

                temp_dosya="$klasor/temp_${MEVCUT_PID}_${islem_sayisi}.mp4"
                ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "$temp_dosya" -y -loglevel quiet 2>/dev/null

                if [ $? -eq 0 ]; then
                    if [[ "$isim" == "$PREFIX"* ]]; then
                        mv "$temp_dosya" "$video" 2>/dev/null; yeni_isim="$isim"
                    else
                        yeni_isim="${PREFIX}${isim}"
                        mv "$temp_dosya" "$klasor/$yeni_isim" 2>/dev/null; rm -f "$video"
                    fi
                    echo "$yeni_isim" >> "$ISLENENLER_LISTESI"
                else
                    rm -f "$temp_dosya"
                fi
            done < "$TEMP_LIST"
            rm -f "$TEMP_LIST"
            echo -e "\n\n  ${GREEN}✓ Videoların kapağı olduğu yerde güncellendi!${RESET}"; read -p "  Enter..." _; ana_menu ;;
        2) mp3_donusturucu_menu ;;
        3) rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"; echo -e "  ${GREEN}✓ Hafıza temizlendi.${RESET}"; sleep 1; ana_menu ;;
        4)
            echo ""
            read -p "  Yeni Resim Tam Yolu: " yeni_r
            if [ -f "$yeni_r" ]; then
                VARSAYILAN_RESIM="$yeni_r"; _kaydet_ayarlar
                echo -e "  ${GREEN}✓ Kapak resmi başarıyla tanımlandı.${RESET}"
            else
                echo -e "  ${RED}✗ Dosya bulunamadı! Tıkla, doğru yolu yaz.${RESET}"
            fi
            sleep 1; ana_menu ;;
        5) exit 0 ;;
        *) ana_menu ;;
    esac
}

ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
