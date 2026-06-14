cat > ~/muzik_isleyici.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# --- OTOMATİK TEMİZLİK ---
MEVCUT_PID=$$
for pid in $(pgrep -f "muzik_isleyici.sh"); do
    [ "$pid" != "$MEVCUT_PID" ] && kill -9 "$pid" 2>/dev/null
done

AYARLAR="$HOME/.muzik_isleyici.conf"
HAFIZA_DB="$HOME/.muzik_isleyici_hafiza.txt"
[ -f "$AYARLAR" ] && source "$AYARLAR"

PREFIX="〖ذال فیلم تقدیم میکندょ〗"

RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
WHITE='\033[1;37m'; RESET='\033[0m'

_kaydet_ayarlar() {
    {
        echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\""
        echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\""
    } > "$AYARLAR"
}

# === HAFIZA SİSTEMİ ===
_hafiza_kontrol() {
    local dosya_yolu="$1"
    local dosya_hash
    dosya_hash=$(stat -c "%n|%s|%Y" "$dosya_yolu" 2>/dev/null)
    grep -qxF "$dosya_hash" "$HAFIZA_DB" 2>/dev/null
}

_hafiza_ekle() {
    local dosya_yolu="$1"
    local dosya_hash
    dosya_hash=$(stat -c "%n|%s|%Y" "$dosya_yolu" 2>/dev/null)
    echo "$dosya_hash" >> "$HAFIZA_DB"
}

_hafiza_temizle() {
    echo -e "\n  ${YELLOW}⚠  Hafıza sıfırlansın mı? (e/h): ${RESET}"
    read -p "  > " onay
    if [[ "$onay" == "e" || "$onay" == "E" ]]; then
        rm -f "$HAFIZA_DB"
        echo -e "  ${GREEN}✓ Hafıza sıfırlandı.${RESET}"
    else
        echo -e "  ${CYAN}İptal.${RESET}"
    fi
    sleep 1
}

# === İLERLEME ÇUBUĞU ===
_ilerleme_goster() {
    local simdi=$1 toplam=$2 isim="$3"
    local yuzde=$(( simdi * 100 / toplam ))
    local dolu=$(( yuzde / 4 )) bos=$(( 25 - yuzde / 4 ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++)); do bar+="░"; done
    # İsmi kırp
    local kisa_isim="${isim:0:35}"
    [ ${#isim} -gt 35 ] && kisa_isim="${kisa_isim}…"
    printf "\r  ${CYAN}[${GREEN}%s${CYAN}]${YELLOW} %3d%% ${WHITE}(%d/%d)${RESET} ${MAGENTA}%s${RESET}%-20s" \
        "$bar" "$yuzde" "$simdi" "$toplam" "$kisa_isim" " "
}

_baslik() {
    local renk="$1" ikon="$2" metin="$3"
    echo -e "\n${renk}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${renk}│  ${ikon}  ${WHITE}${metin}${renk}$(printf '%*s' $((52 - ${#metin})) '')│${RESET}"
    echo -e "${renk}└────────────────────────────────────────────────────────┘${RESET}\n"
}

# === SEÇENEK: KAPAK RESMİ AYARLA ===
kapak_ayarla() {
    _baslik "$BLUE" "🖼 " "KAPAK RESMİ AYARLA"
    echo -e "  ${CYAN}Şu anki kapak: ${WHITE}${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}\n"
    echo -e "  ${YELLOW}Tam yolu yaz (örn: /sdcard/kapak.jpg):${RESET}"
    read -p "  > " yeni_resim
    if [ -z "$yeni_resim" ]; then
        echo -e "  ${RED}✗ İptal edildi.${RESET}"; sleep 1; return
    fi
    if [ ! -f "$yeni_resim" ]; then
        echo -e "  ${RED}✗ Dosya bulunamadı: $yeni_resim${RESET}"; sleep 2; return
    fi
    VARSAYILAN_RESIM="$yeni_resim"
    _kaydet_ayarlar
    echo -e "  ${GREEN}✓ Kapak resmi ayarlandı: $VARSAYILAN_RESIM${RESET}"
    sleep 2
}

# === SEÇENEK 1: VİDEO → MP3 ===
video_to_mp3() {
    _baslik "$CYAN" "🚀" "VİDEO → MP3 DÖNÜŞTÜRÜCÜ (Zal Film Kapağı)"

    read -p "  MP4/MKV/WEBM Klasör Yolu [ENTER=varsayılan]: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then echo -e "  ${RED}✗ Klasör bulunamadı!${RESET}"; sleep 2; return; fi
    VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar

    if [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}✗ Kapak resmi ayarlanmamış! Önce Seçenek 4'ten ayarla.${RESET}"; sleep 2; return
    fi

    TEMP_LIST="$HOME/.mp3_conv_tmp.txt"
    find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) | sort > "$TEMP_LIST"
    toplam_ham=$(wc -l < "$TEMP_LIST")

    if [ "$toplam_ham" -eq 0 ]; then
        echo -e "  ${RED}✗ Video bulunamadı!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; return
    fi

    # Hafıza filtresi
    FILTERED_LIST="$HOME/.mp3_conv_filtered.txt"
    > "$FILTERED_LIST"
    atlanan=0
    while IFS= read -r video; do
        if _hafiza_kontrol "$video"; then
            atlanan=$((atlanan + 1))
        else
            echo "$video" >> "$FILTERED_LIST"
        fi
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"

    toplam=$(wc -l < "$FILTERED_LIST")
    echo -e "  ${CYAN}Toplam bulundu: ${WHITE}$toplam_ham${CYAN} | Zaten işlenmiş: ${YELLOW}$atlanan${CYAN} | İşlenecek: ${GREEN}$toplam${RESET}\n"

    if [ "$toplam" -eq 0 ]; then
        echo -e "  ${GREEN}✓ Tüm dosyalar zaten işlenmiş, atlıyorum.${RESET}"
        rm -f "$FILTERED_LIST"; sleep 2; return
    fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/MP3_Muzikler"
    mkdir -p "$CIKTI_DIR"
    echo -e "  ${GREEN}➔ Dönüştürme başladı...${RESET}\n"

    islem=0
    while IFS= read -r video; do
        islem=$((islem + 1))
        isim=$(basename "$video"); isim_base="${isim%.*}"
        _ilerleme_goster "$islem" "$toplam" "$isim_base"

        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
            -vn -map 0:a:0 -map 1:v:0 \
            -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 \
            -c:v mjpeg -pix_fmt yuvj420p -disposition:v attached_pic \
            -id3v2_version 3 \
            -metadata title="$isim_base" \
            -metadata album="Zal Film" \
            "$CIKTI_DIR/${PREFIX}${isim_base}.mp3" \
            -y -loglevel quiet 2>/dev/null

        [ $? -eq 0 ] && _hafiza_ekle "$video"
    done < "$FILTERED_LIST"
    rm -f "$FILTERED_LIST"

    echo -e "\n\n  ${GREEN}✓ Tamamlandı! Klasör: $CIKTI_DIR${RESET}"
    read -p "  Enter..." _
}

# === SEÇENEK 2: MP3 KAPAK DEĞİŞTİR ===
mp3_kapak_degistir() {
    _baslik "$YELLOW" "🎶" "MP3 KAPAK & ZAL FİLM ETİKETLEME"

    read -p "  MP3 Klasör Yolu [ENTER=varsayılan]: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then echo -e "  ${RED}✗ Klasör bulunamadı!${RESET}"; sleep 2; return; fi
    VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar

    if [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}✗ Kapak resmi ayarlanmamış! Önce Seçenek 4'ten ayarla.${RESET}"; sleep 2; return
    fi

    TEMP_LIST="$HOME/.mp3_tag_tmp.txt"
    find "$VARSAYILAN_KLASOR" -maxdepth 1 -iname "*.mp3" | sort > "$TEMP_LIST"
    toplam_ham=$(wc -l < "$TEMP_LIST")

    if [ "$toplam_ham" -eq 0 ]; then
        echo -e "  ${RED}✗ MP3 bulunamadı!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; return
    fi

    FILTERED_LIST="$HOME/.mp3_tag_filtered.txt"
    > "$FILTERED_LIST"
    atlanan=0
    while IFS= read -r mp3; do
        if _hafiza_kontrol "$mp3"; then
            atlanan=$((atlanan + 1))
        else
            echo "$mp3" >> "$FILTERED_LIST"
        fi
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"

    toplam=$(wc -l < "$FILTERED_LIST")
    echo -e "  ${CYAN}Toplam: ${WHITE}$toplam_ham${CYAN} | Atlanacak: ${YELLOW}$atlanan${CYAN} | İşlenecek: ${GREEN}$toplam${RESET}\n"

    if [ "$toplam" -eq 0 ]; then
        echo -e "  ${GREEN}✓ Tüm dosyalar zaten işlenmiş.${RESET}"
        rm -f "$FILTERED_LIST"; sleep 2; return
    fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/ZalFilm_Kapakli_MP3ler"
    mkdir -p "$CIKTI_DIR"
    echo -e "  ${GREEN}➔ Kapaklar değiştiriliyor...${RESET}\n"

    islem=0
    while IFS= read -r mp3; do
        islem=$((islem + 1))
        isim=$(basename "$mp3"); isim_base="${isim%.*}"
        _ilerleme_goster "$islem" "$toplam" "$isim_base"

        # Prefix varsa çıkar
        if [[ "$isim_base" == "$PREFIX"* ]]; then
            temiz_isim="${isim_base#$PREFIX}"
        else
            temiz_isim="$isim_base"
        fi

        ffmpeg -i "$mp3" -i "$VARSAYILAN_RESIM" \
            -map 0:a:0 -map 1:v:0 \
            -c:a copy -c:v mjpeg -pix_fmt yuvj420p \
            -disposition:v attached_pic -id3v2_version 3 \
            -metadata title="$temiz_isim" \
            -metadata album="Zal Film" \
            "$CIKTI_DIR/${PREFIX}${temiz_isim}.mp3" \
            -y -loglevel quiet 2>/dev/null

        [ $? -eq 0 ] && _hafiza_ekle "$mp3"
    done < "$FILTERED_LIST"
    rm -f "$FILTERED_LIST"

    echo -e "\n\n  ${GREEN}✓ Kapak değiştirme bitti! Klasör: $CIKTI_DIR${RESET}"
    read -p "  Enter..." _
}

# === SEÇENEK 3: METADATA & İSİM TEMİZLE ===
mp3_isim_temizle() {
    _baslik "$RED" "🧹" "METADATA & İSİM TEMİZLEYİCİ + ZAL FİLM PREFIX"
    echo -e "  ${YELLOW}Not: Tüm metadata silinir, isim temizlenir, Zal Film prefix eklenir.${RESET}\n"

    read -p "  Klasör Yolu [ENTER=varsayılan]: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then echo -e "  ${RED}✗ Klasör bulunamadı!${RESET}"; sleep 2; return; fi
    VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar

    TEMP_LIST="$HOME/.mp3_clean_tmp.txt"
    find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.mp3" \) | sort > "$TEMP_LIST"
    toplam_ham=$(wc -l < "$TEMP_LIST")

    if [ "$toplam_ham" -eq 0 ]; then
        echo -e "  ${RED}✗ Dosya bulunamadı!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; return
    fi

    FILTERED_LIST="$HOME/.mp3_clean_filtered.txt"
    > "$FILTERED_LIST"
    atlanan=0
    while IFS= read -r dosya; do
        if _hafiza_kontrol "$dosya"; then
            atlanan=$((atlanan + 1))
        else
            echo "$dosya" >> "$FILTERED_LIST"
        fi
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"

    toplam=$(wc -l < "$FILTERED_LIST")
    echo -e "  ${CYAN}Toplam: ${WHITE}$toplam_ham${CYAN} | Atlanacak: ${YELLOW}$atlanan${CYAN} | İşlenecek: ${GREEN}$toplam${RESET}\n"

    if [ "$toplam" -eq 0 ]; then
        echo -e "  ${GREEN}✓ Tüm dosyalar zaten işlenmiş.${RESET}"
        rm -f "$FILTERED_LIST"; sleep 2; return
    fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/Temiz_Muzikler"
    mkdir -p "$CIKTI_DIR"
    echo -e "  ${GREEN}➔ Temizleniyor...${RESET}\n"

    islem=0
    while IFS= read -r dosya; do
        islem=$((islem + 1))
        isim=$(basename "$dosya"); isim_base="${isim%.*}"
        _ilerleme_goster "$islem" "$toplam" "$isim_base"

        # İsmi temizle: prefix, Farsça köşeli parantez, normal parantez, boşluk
        temiz_isim="$isim_base"
        temiz_isim="${temiz_isim#$PREFIX}"
        temiz_isim=$(echo "$temiz_isim" | sed \
            -e 's/〖[^〗]*〗//g' \
            -e 's/【[^】]*】//g' \
            -e 's/\[[^]]*\]//g' \
            -e 's/([^)]*)//g' \
            -e 's/^[[:space:]]*//' \
            -e 's/[[:space:]]*$//')
        [ -z "$temiz_isim" ] && temiz_isim="Muzik_$islem"

        if [[ "$dosya" == *.mp3 || "$dosya" == *.MP3 ]]; then
            ffmpeg -i "$dosya" \
                -map_metadata -1 -map 0:a:0 \
                -c:a copy \
                -id3v2_version 3 \
                -metadata title="${PREFIX}${temiz_isim}" \
                "$CIKTI_DIR/${PREFIX}${temiz_isim}.mp3" \
                -y -loglevel quiet 2>/dev/null
        else
            ffmpeg -i "$dosya" \
                -vn -map_metadata -1 -map 0:a:0 \
                -c:a libmp3lame -b:a 192k \
                -id3v2_version 3 \
                -metadata title="${PREFIX}${temiz_isim}" \
                "$CIKTI_DIR/${PREFIX}${temiz_isim}.mp3" \
                -y -loglevel quiet 2>/dev/null
        fi

        [ $? -eq 0 ] && _hafiza_ekle "$dosya"
    done < "$FILTERED_LIST"
    rm -f "$FILTERED_LIST"

    echo -e "\n\n  ${GREEN}✓ Temizlik bitti! Klasör: $CIKTI_DIR${RESET}"
    read -p "  Enter..." _
}

# --- ANA MENÜ ---
ana_menu() {
    clear
    local hafiza_sayi=0
    [ -f "$HAFIZA_DB" ] && hafiza_sayi=$(wc -l < "$HAFIZA_DB")

    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAGENTA}║${YELLOW}      👑   SAMIULLAH DILSUZ PRODUCTION   👑             ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}╠══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${MAGENTA}║${CYAN}       🎬  ZAL FİLM OTO-MATRİX SES & ETİKET PANELİ      ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo -e ""
    echo -e "  ${CYAN}📁 Klasör :${WHITE} ${VARSAYILAN_KLASOR:-'Ayarlanmamış'}${RESET}"
    echo -e "  ${CYAN}🖼  Kapak  :${GREEN} ${VARSAYILAN_RESIM:-'⚠  Ayarlanmamış'}${RESET}"
    echo -e "  ${CYAN}🧠 Hafıza :${YELLOW} $hafiza_sayi dosya kayıtlı${RESET}"
    echo -e ""
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} 🚀  Video → MP3 Dönüştür${MAGENTA} (Zal Film Kapağıyla)${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} 🎶  MP3 Kapak & Etiket Değiştir${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} 🧹  Metadata & İsim Temizle${RED} + Zal Film Prefix Ekle${RESET}"
    echo -e "  ${YELLOW}[4]${WHITE} 🖼   Kapak Resmi Ayarla${RESET}"
    echo -e "  ${YELLOW}[5]${WHITE} 🧠  Hafızayı Sıfırla${CYAN} (tüm dosyaları tekrar işle)${RESET}"
    echo -e "  ${RED}[6]${WHITE} 🚪  Çıkış${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçiminiz [1-6]: " secim

    case $secim in
        1) video_to_mp3; ana_menu ;;
        2) mp3_kapak_degistir; ana_menu ;;
        3) mp3_isim_temizle; ana_menu ;;
        4) kapak_ayarla; ana_menu ;;
        5) _hafiza_temizle; ana_menu ;;
        6) exit 0 ;;
        *) ana_menu ;;
    esac
}

ana_menu
EOF
chmod +x ~/muzik_isleyici.sh && bash ~/muzik_isleyici.sh
