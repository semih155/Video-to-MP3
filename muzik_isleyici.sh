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
        if [ $i -lt 5 ]; then bar+="${RED}█"; elif [ $i -lt 10 ]; then bar+="${YELLOW}█"; elif [ $i -lt 15 ]; then bar+="${GREEN}█"; else bar+="${CYAN}█"; fi
    done
    for ((i=0; i<b; i++)); do bar+="${WHITE}░"; done
    printf "\r  ${BOLD}${MAGENTA}🔮 İŞLENİYOR:${RESET} [ %s${RESET} ] ${BOLD}${YELLOW}%3d%%${RESET} ${WHITE}(%d/%d)${RESET}" "$bar" "$y" "$m" "$t"
}

_klasor_sec() {
    echo -e "\n${BOLD}${CYAN}👉 Klasör Yolunu Girin:${RESET}"
    read -p " ❯❯ " _yol
    if [ -d "$_yol" ]; then SON_KLASOR="$_yol"; _kaydet_ayarlar; return 0; else echo -e "${BLINK}${RED}❌ KLASÖR BULUNAMADI!${RESET}"; sleep 1.5; return 1; fi
}

# 1 NUMARALI SEÇENEK: İSİM + İÇERİK TEMİZLEME
isim_temizle_ve_etiketle() {
    _klasor_sec || return
    mapfile -t dosyalar < <(find "$SON_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \))
    toplam=${#dosyalar[@]}; [[ $toplam -eq 0 ]] && { echo -e "${RED}Müzik bulunamadı!${RESET}"; return; }
    
    basarili=0; sayac=0
    echo -e "\n${BOLD}${YELLOW}✨ Dosya adları ve içindeki tüm kirli veriler (metadata) siliniyor...${RESET}\n"
    for muzik in "${dosyalar[@]}"; do
        ((sayac++)); dizin="$(dirname "$muzik")"; dosya_adi="$(basename "$muzik")"; uzanti="${dosya_adi##*.}"
        temiz=$(echo "${dosya_adi%.*}" | sed "s/〖[^〗]*〗//g" | sed "s/ょ//g" | sed -E "s/^[[:space:]\.-]+//g")
        yeni_tam_yol="$dizin/${PREFIX}${temiz}.${uzanti}"
        
        # FFmpeg ile dosyayı kopyalarken -map_metadata -1 parametresi tüm kirli açıklamaları ve etiketleri çöpe atar
        # Sadece title etiketine senin istediğin yazıyı basar.
        mv "$muzik" "$yeni_tam_yol" 2>/dev/null
        ffmpeg -i "$yeni_tam_yol" -map_metadata -1 -metadata title="${PREFIX}${temiz}" -c copy -y -loglevel quiet "${yeni_tam_yol}_tmp.${uzanti}" && mv "${yeni_tam_yol}_tmp.${uzanti}" "$yeni_tam_yol"
        
        ((basarili++))
        _ilerleme_goster $sayac $toplam
    done
    echo -e "\n\n${BOLD}${GREEN}🎉 BAŞARIYLA TEMİZLENDİ!${RESET}"; sleep 2
}

kapak_gom() {
    if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then echo -e "${RED}Önce resim seç!${RESET}"; sleep 2; return; fi
    _klasor_sec || return
    mapfile -t dosyalar < <(find "$SON_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \))
    toplam=${#dosyalar[@]}; [[ $toplam -eq 0 ]] && return
    
    basarili=0; hatali=0; sayac=0
    for muzik in "${dosyalar[@]}"; do
        ((sayac++)); tmp="$SON_KLASOR/.tmp_$$.tmp"
        # Kapak gömerken eski meta verileri de korumasın diye yine map_metadata -1 kullanıyoruz
        ffmpeg -i "$muzik" -i "$VARSAYILAN_RESIM" -map 0:a:0 -map 1:0 -map_metadata -1 -acodec copy -id3v2_version 3 -c:v:0 mjpeg -disposition:v:0 attached_pic -y -loglevel quiet "$tmp" && mv "$tmp" "$muzik" && ((basarili++)) || ((hatali++))
        _ilerleme_goster $sayac $toplam
    done
    echo -e "\n\n${BOLD}${GREEN}✅ Başarılı: $basarili${RESET}"; sleep 2
}

# [Menü kısmı aynı, sadece isim_temizle_ve_etiketle fonksiyonunu güncelledik]
# Kodun geri kalanını yukarıdakiyle aynı bırak kanka, GitHub'a bunu yükle.
