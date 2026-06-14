#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.muzik_ayarlari.conf" ] && source "$HOME/.muzik_ayarlari.conf"

RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; BLUE='\e[1;34m'
MAGENTA='\e[1;35m'; CYAN='\e[1;36m'; WHITE='\e[1;37m'; RESET='\e[0m'
BOLD='\e[1m'; BLINK='\e[5m'; BG_PURPLE='\e[45m'; TEXT_BLACK='\e[30m'

PREFIX="〖ذال فیلم تقدیم میکندょ〗"

_kaydet_ayarlar() { cat > "$HOME/.muzik_ayarlari.conf" << CONF
VARSAYILAN_RESIM="$VARSAYILAN_RESIM"
SON_KLASOR="$SON_KLASOR"
CONF
}

_ilerleme_goster() {
    local m=$1 t=$2; local y=$(( m * 100 / t ))
    local d=$(( y / 5 )); local b=$(( 20 - d ))
    local bar=""
    for ((i=0; i<d; i++)); do 
        if [ $i -lt 5 ]; then bar+="${RED}█";
        elif [ $i -lt 10 ]; then bar+="${YELLOW}█";
        elif [ $i -lt 15 ]; then bar+="${GREEN}█";
        else bar+="${CYAN}█"; fi
    done
    for ((i=0; i<b; i++)); do bar+="${WHITE}░"; done
    printf "\r  ${BOLD}${MAGENTA}🔮 İŞLENİYOR:${RESET} [ %s${RESET} ] ${BOLD}${YELLOW}%3d%%${RESET} ${WHITE}(%d/%d)${RESET}" "$bar" "$y" "$m" "$t"
}

_klasor_sec() {
    echo -e "\n${BOLD}${CYAN}👉 Klasör Yolunu Girin:${RESET}"
    read -p " ❯❯ " _yol
    if [ -d "$_yol" ]; then SON_KLASOR="$_yol"; _kaydet_ayarlar; return 0; else echo -e "${BLINK}${RED}❌ KLASÖR BULUNAMADI!${RESET}"; sleep 1.5; return 1; fi
}

isim_temizle_ve_etiketle() {
    _klasor_sec || return
    mapfile -t dosyalar < <(find "$SON_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \))
    toplam=${#dosyalar[@]}; [[ $toplam -eq 0 ]] && { echo -e "${RED}Müzik bulunamadı!${RESET}"; sleep 1.5; return; }
    
    basarili=0; sayac=0
    echo -e "\n${BOLD}${YELLOW}✨ İsimler pürüzsüz hale getiriliyor...${RESET}\n"
    for muzik in "${dosyalar[@]}"; do
        ((sayac++)); dizin="$(dirname "$muzik")"; dosya_adi="$(basename "$muzik")"; uzanti="${dosya_adi##*.}"
        temiz=$(echo "${dosya_adi%.*}" | sed -E "s/\([0-9]+\)//g" | sed "s/〖[^〗]*〗//g" | sed "s/ょ//g" | sed -E "s/^[[:space:]:-]+//g" | sed -E "s/[[:space:]:-]+$//g")
        yeni_tam_yol="$dizin/${PREFIX}${temiz}.${uzanti}"
        
        if [ "$muzik" != "$yeni_tam_yol" ]; then
            mv "$muzik" "$yeni_tam_yol" 2>/dev/null
            ffmpeg -i "$yeni_tam_yol" -c copy -metadata title="${PREFIX}${temiz}" -y -loglevel quiet "${yeni_tam_yol}_tmp.${uzanti}" && mv "${yeni_tam_yol}_tmp.${uzanti}" "$yeni_tam_yol"
            ((basarili++))
        fi
        _ilerleme_goster $sayac $toplam
    done
    echo -e "\n\n${BOLD}${GREEN}🎉 BAŞARIYLA TAMAMLANDI! $basarili Dosya Yenilendi.${RESET}"; sleep 2.5
}

komple_temizlik_yap() {
    _klasor_sec || return
    mapfile -t dosyalar < <(find "$SON_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \))
    toplam=${#dosyalar[@]}; [[ $toplam -eq 0 ]] && { echo -e "${RED}Müzik bulunamadı!${RESET}"; sleep 1.5; return; }
    
    basarili=0; sayac=0
    echo -e "\n${BOLD}${BLINK}${RED}🔥 ESKİ İSİMLER TAMAMEN KAZINIYOR...${RESET}\n"
    for muzik in "${dosyalar[@]}"; do
        ((sayac++)); dizin="$(dirname "$muzik")"; dosya_adi="$(basename "$muzik")"; uzanti="${dosya_adi##*.}"
        yeni_tam_yol="$dizin/${PREFIX}.${uzanti}"
        
        if [ -f "$yeni_tam_yol" ] && [ "$muzik" != "$yeni_tam_yol" ]; then
            yeni_tam_yol="$dizin/${PREFIX}_${sayac}.${uzanti}"
        fi
        
        if [ "$muzik" != "$yeni_tam_yol" ]; then
            mv "$muzik" "$yeni_tam_yol" 2>/dev/null
            ffmpeg -i "$yeni_tam_yol" -c copy -metadata title="${PREFIX}" -y -loglevel quiet "${yeni_tam_yol}_tmp.${uzanti}" && mv "${yeni_tam_yol}_tmp.${uzanti}" "$yeni_tam_yol"
            ((basarili++))
        fi
        _ilerleme_goster $sayac $toplam
    done
    echo -e "\n\n${BOLD}${BG_PURPLE}${TEXT_BLACK} ✨ Komple temizlik bitti. $basarili dosya sıfırlandı. ${RESET}"; sleep 2.5
}

kapak_gom() {
    if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then 
        echo -e "${BLINK}${RED}❌ Önce [4] tuşuna basıp geçerli bir resim seç kanka!${RESET}"; sleep 2.5; return; 
    fi
    _klasor_sec || return
    mapfile -t dosyalar < <(find "$SON_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \))
    toplam=${#dosyalar[@]}; [[ $toplam -eq 0 ]] && { echo -e "${RED}Klasörde müzik yok!${RESET}"; sleep 1.5; return; }
    
    basarili=0; hatali=0; sayac=0
    echo -e "\n${BOLD}${CYAN}🖼️  Kapak resimleri doğrudan gömülüyor...${RESET}\n"
    
    for muzik in "${dosyalar[@]}"; do
        ((sayac++))
        dizin="$(dirname "$muzik")"
        uzanti="${muzik##*.}"
        tmp="$dizin/.tmp_mzk_${ANON_VAR}_$$.${uzanti}"
        
        # Aracısız, doğrudan senin seçtiğin orijinal resmi gömen en sağlam FFmpeg komutu
        ffmpeg -i "$muzik" -i "$VARSAYILAN_RESIM" -map 0:a:0 -map 1:0 -acodec copy -id3v2_version 3 -c:v:0 mjpeg -disposition:v:0 attached_pic -y -loglevel quiet "$tmp"
        
        if [[ $? -eq 0 ]] && [ -s "$tmp" ]; then
            mv "$tmp" "$muzik"
            ((basarili++))
        else
            rm -f "$tmp"
            ((hatali++))
        fi
        _ilerleme_goster $sayac $toplam
    done
    echo -e "\n\n${BOLD}${GREEN}✅ BAŞARILI GÖMÜLEN: $basarili${RESET} | ${BOLD}${RED}❌ HATALI: $hatali${RESET}"; sleep 3
}

while true; do
    clear
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}  ██████╗  █████╗ ██╗         ███████╗██╗██╗     ███╗   ███╗${RESET}"
    echo -e "${BOLD}${YELLOW}  ╚════██╗██╔══██╗██║         ██╔════╝██║██║     ████╗ ████║${RESET}"
    echo -e "${BOLD}${GREEN}   █████╔╝███████║██║         █████╗  ██║██║     ██╔████╔██║${RESET}"
    echo -e "${BOLD}${BLUE}   ██╔═══╝ ██╔══██║██║         ██╔══╝  ██║██║     ██║╚██╔╝██║${RESET}"
    echo -e "${BOLD}${MAGENTA}   ███████╗██║  ██║███████╗    ██║     ██║███████╗██║ ╚═╝ ██║${RESET}"
    echo -e "${BOLD}${CYAN}   ╚══════╝╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "                   ${BOLD}${BLINK}${BG_PURPLE}${TEXT_BLACK} 🌟 ZAL FILM SOUNDBOX v4.0 🌟 ${RESET}\n"
    
    echo -e "  ${WHITE}🖼️  Kapak Resmi :${RESET} ${BOLD}${YELLOW}${VARSAYILAN_RESIM:-'AYARLANMAMIŞ'}${RESET}"
    echo -e "  ${WHITE}📂 Aktif Dizin  :${RESET} ${BOLD}${BLUE}${SON_KLASOR:-'SEÇİLMEMİŞ'}${RESET}"
    echo -e "${BOLD}${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}${MAGENTA}⚡ ŞEKİLLİ MENÜ SEÇENEKLERİ:${RESET}"
    echo -e "  ${BOLD}${GREEN}[1]${RESET} 🏷️  İsimleri Düzenle + Reklam Ekle (Normal Mod)"
    echo -e "  ${BOLD}${GREEN}[2]${RESET} 🖼️  Müziklere Albüm Kapağı Göm"
    echo -e "  ${BOLD}${RED}[3]💥 KOMPLE TEMİZLİK YAP (İsimleri Sil, Sadece Marka Bırak)${RESET}"
    echo -e "  ${BOLD}${GREEN}[4]${RESET} 🎨 Albüm Kapağı Seç / Değiştir"
    echo -e "  ${BOLD}${YELLOW}[0]${RESET} 🚪 Güvenli Çıkış"
    echo -e "${BOLD}${CYAN}==============================================================${RESET}"
    read -p "  İşlem Numarası ❯ " secim

    case $secim in
        1) isim_temizle_ve_etiketle ;;
        2) kapak_gom ;;
        3) komple_temizlik_yap ;;
        4) read -p "  Resim Yolu (Tam Yol Girin) ❯ " yeni_r
           if [ -f "$yeni_r" ]; then
               VARSAYILAN_RESIM="$yeni_r"
               _kaydet_ayarlar
               echo -e "${GREEN}✓ Resim başarıyla seçildi kanka.${RESET}"; sleep 1
           else
               echo -e "${RED}❌ HATA: Dosya bulunamadı! Doğru yol girdiğinden emin ol.${RESET}"; sleep 2
           fi ;;
        0) echo -e "\n${BOLD}${CYAN}Zal Film Soundbox kapandı. Görüşürüz kanka! 👋${RESET}"; exit 0 ;;
        *) echo -e "${BLINK}${RED}Geçersiz Tuşlama!${RESET}"; sleep 1 ;;
    esac
done
