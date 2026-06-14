#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.muzik_ayarlari.conf" ] && source "$HOME/.muzik_ayarlari.conf"

RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; BLUE='\e[1;34m'; MAGENTA='\e[1;35m'; CYAN='\e[1;36m'; WHITE='\e[1;37m'; RESET='\e[0m'
PREFIX="〖ذال فیلم تقدیم میکندょ〗"

_kaydet_ayarlar() { cat > "$HOME/.muzik_ayarlari.conf" << CONF
VARSAYILAN_RESIM="$VARSAYILAN_RESIM"
SON_KLASOR="$SON_KLASOR"
CONF
}

_klasor_sec() {
    echo -e "\n${YELLOW}Klasör Yolunu Girin (Örn: /storage/emulated/0/Download/Muziklerim):${RESET}"
    read -p ">> " _yol
    if [ -d "$_yol" ]; then
        SON_KLASOR="$_yol"
        _kaydet_ayarlar
        return 0
    else
        echo -e "${RED}Böyle bir klasör yok kanka!${RESET}"; return 1
    fi
}

isim_temizle_ve_etiketle() {
    _klasor_sec || return
    echo -e "${CYAN}Sadece '$SON_KLASOR' içindeki müzikler işleniyor...${RESET}"
    
    # Sadece seçilen klasörde çalışır, alt dizinlere girmez (-maxdepth 1)
    find "$SON_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \) | while read -r muzik; do
        dizin="$(dirname "$muzik")"
        dosya_adi="$(basename "$muzik")"
        uzanti="${dosya_adi##*.}"
        temiz_ad=$(echo "${dosya_adi%.*}" | sed -E "s/\([0-9]+\)//g" | sed "s/〖[^〗]*〗//g" | sed "s/ょ//g" | sed -E "s/^[[:space:]:-]+//g" | sed -E "s/[[:space:]:-]+$//g")
        
        yeni_ad="${PREFIX}${temiz_ad}.${uzanti}"
        yeni_tam_yol="$dizin/$yeni_ad"

        if [ "$muzik" != "$yeni_tam_yol" ]; then
            mv "$muzik" "$yeni_tam_yol"
            ffmpeg -i "$yeni_tam_yol" -c copy -metadata title="${PREFIX}${temiz_ad}" -y -loglevel quiet "${yeni_tam_yol}_tmp.${uzanti}" && mv "${yeni_tam_yol}_tmp.${uzanti}" "$yeni_tam_yol"
        fi
    done
    echo -e "${GREEN}✓ İşlem tamamlandı!${RESET}"; sleep 2
}

kapak_gom() {
    [ ! -f "$VARSAYILAN_RESIM" ] && { echo -e "${RED}Önce resim seç kanka!${RESET}"; sleep 2; return; }
    _klasor_sec || return
    echo -e "${CYAN}Sadece '$SON_KLASOR' klasöründeki resimler işleniyor...${RESET}"
    
    find "$SON_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \) | while read -r muzik; do
        tmp="$SON_KLASOR/.tmp_$$.tmp"
        ffmpeg -i "$muzik" -i "$VARSAYILAN_RESIM" -map 0:a:0 -map 1:0 -acodec copy -id3v2_version 3 -c:v:0 mjpeg -disposition:v:0 attached_pic -y -loglevel quiet "$tmp" && mv "$tmp" "$muzik"
    done
    echo -e "${GREEN}✓ Kapak işleme bitti!${RESET}"; sleep 2
}

# ANA MENÜ
while true; do
    clear
    echo -e "${MAGENTA}--- 🎶 ÖZEL MÜZİK KONTROLÜ 🎶 ---${RESET}"
    echo -e "  [1] İsimleri Temizle + Prefix Ekle"
    echo -e "  [2] Kapak Resmi Ekle (Sadece Seçili Klasör)"
    echo -e "  [3] Albüm Kapağı Seç (Resim Yolu)"
    echo -e "  [0] Çıkış"
    read -p " Seçim: " secim
    case $secim in
        1) isim_temizle_ve_etiketle ;;
        2) kapak_gom ;;
        3) read -p "Resim yolu: " yeni_r; [ -f "$yeni_r" ] && VARSAYILAN_RESIM="$yeni_r" && _kaydet_ayarlar ;;
        0) break ;;
    esac
done
