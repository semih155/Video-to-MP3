mkdir -p ~/Video-to-MP3 && cat > ~/Video-to-MP3/muzik_isleyici.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.muzik_ayarlari.conf" ] && source "$HOME/.muzik_ayarlari.conf"

KILIT_DOSYA="$HOME/.muzik_script.lock"
if [ -f "$KILIT_DOSYA" ]; then
    eski_pid=$(cat "$KILIT_DOSYA" 2>/dev/null)
    if [ -n "$eski_pid" ] && kill -0 "$eski_pid" 2>/dev/null; then
        echo -e "\e[1;31m⚠️  UYARI: Script zaten başka bir oturumda çalışıyor!\e[0m"
        exit 1
    fi
fi
echo $$ > "$KILIT_DOSYA"
trap 'rm -f "$KILIT_DOSYA"' EXIT

# Renk Tanımlamaları
RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; BLUE='\e[1;34m'
MAGENTA='\e[1;35m'; CYAN='\e[1;36m'; WHITE='\e[1;37m'; RESET='\e[0m'
HATA_LOG="$HOME/muzik_hata_log.txt"

_kaydet_ayarlar() {
    cat > "$HOME/.muzik_ayarlari.conf" << CONF
VARSAYILAN_RESIM="$VARSAYILAN_RESIM"
SON_MP3_KAYNAK="$SON_MP3_KAYNAK"
SON_MP3_KALITE="$SON_MP3_KALITE"
SON_MUZIK_KLASOR="$SON_MUZIK_KLASOR"
CONF
}

_ilerleme_goster() {
    local mevcut=$1 toplam=$2
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 )) bos=$(( 20 - yuzde / 5 ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  ${CYAN}[%s]${RESET} ${WHITE}%3d%%${RESET}  (%d/%d)" "$bar" "$yuzde" "$mevcut" "$toplam"
}

_kapak_jpg_hazirla() {
    KAPAK_JPG=""
    [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ] && return 1
    local hedef="$HOME/.muzik_kapak_cache.jpg"
    ffmpeg -i "$VARSAYILAN_RESIM" -vf "scale='min(1280,iw)':-2" -frames:v 1 "$hedef" -y -loglevel quiet 2>/dev/null
    [ -f "$hedef" ] && { KAPAK_JPG="$hedef"; return 0; }
    return 1
}

_klasor_sec_oneri() {
    local baslik="$1"
    local son_deger="$2"
    echo -e "\n${YELLOW}╭━━ [ $baslik ]${RESET}"
    echo -e "${YELLOW}┃${RESET}  ${CYAN}[1]${RESET} VidMate İndirmeleri  ${GREEN}(🔥 En Çok Kullanılan)${RESET}"
    echo -e "${YELLOW}┃${RESET}  ${CYAN}[2]${RESET} SnapTube İndirmeleri"
    echo -e "${YELLOW}┃${RESET}  ${CYAN}[3]${RESET} Telefonun Ana Müzik Klasörü (Music)"
    echo -e "${YELLOW}┃${RESET}  ${CYAN}[4]${RESET} Özel Dizin Yolu Gir"
    echo -e "${YELLOW}┃${RESET}  ${RED}[0]${RESET} Geri Dön"
    if [ -n "$son_deger" ]; then
        echo -e "${YELLOW}┃${RESET}  ${MAGENTA}[Enter]${RESET} Son kullanılan klasör: $son_deger"
    fi
    echo -e "${YELLOW}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    read -p " Seçiminiz: " _src

    case "$_src" in
        "")
            if [ -n "$son_deger" ]; then SECILEN_KLASOR="$son_deger"
            else echo -e "${RED}❌ Kayıtlı klasör yok! Seçim yapın.${RESET}"; return 1; fi ;;
        1) SECILEN_KLASOR="/storage/emulated/0/VidMate/download" ;;
        2) SECILEN_KLASOR="/storage/emulated/0/snaptube/download/SnapTube Video" ;;
        3) SECILEN_KLASOR="/storage/emulated/0/Music" ;;
        4) read -p "Dizin yolunu girin: " _custom
           if [ -z "$_custom" ] || [ ! -d "$_custom" ]; then echo -e "${RED}❌ Geçersiz dizin!${RESET}"; return 1; fi
           SECILEN_KLASOR="$_custom" ;;
        0) return 2 ;;
        *) echo -e "${RED}❌ Geçersiz seçim!${RESET}"; return 1 ;;
    esac
    return 0
}

mp3_donustur_menu() {
    while true; do
        clear
        echo -e "${MAGENTA}━━━━━━━🌟 VIDEO -> MP3 DÖNÜŞTÜRÜCÜ 🌟━━━━━━━${RESET}"
        if [ -n "$SON_MP3_KAYNAK" ]; then
            echo -e "  ${YELLOW}📂 Son Kullanılan Klasör:${RESET} $SON_MP3_KAYNAK"
            echo -e "  ${YELLOW}⚡ Ses Kalitesi          :${RESET} ${SON_MP3_KALITE:-'320k'}\n"
            echo -e "  ${GREEN}[Enter]${RESET} Aynen Devam Et ${GREEN}(Hızlı Mod)${RESET}"
            echo -e "  ${CYAN}[d]${RESET}     Ayarları Sıfırla (Klasör/Kalite Değiştir)"
            echo -e "  ${RED}[x]${RESET}     Geri Dön"
            read -p "  Seçiminiz: " hizli_sec
            case "$hizli_sec" in
                "") : ;; 
                x|X) return ;;
                d|D) SON_MP3_KAYNAK="" ;;
                *) echo -e "${RED}Geçersiz tuşlama!${RESET}"; sleep 1; continue ;;
            esac
        fi

        if [ -z "$SON_MP3_KAYNAK" ]; then
            _klasor_sec_oneri "Kaynak Klasörü Seçin" "$SON_MP3_KAYNAK"
            local ret=$?
            [ $ret -eq 2 ] && return
            [ $ret -ne 0 ] && { sleep 1; continue; }
            SON_MP3_KAYNAK="$SECILEN_KLASOR"

            echo -e "\n${YELLOW}╭━━ [ Ses Kalitesi Seçimi ]${RESET}"
            echo -e "${YELLOW}┃${RESET}  ${GREEN}[1] 320k (Önerilen - En Yüksek Stüdyo Kalitesi)${RESET}"
            echo -e "${YELLOW}┃${RESET}  [2] 192k (Standart Kalite)"
            echo -e "${YELLOW}┃${RESET}  [3] 128k (Düşük Kalite - Küçük Boyut)"
            echo -e "${YELLOW}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
            read -p " Seçiminiz [Önerilen için Enter]: " q
            case "$q" in
                2) SON_MP3_KALITE="192k" ;;
                3) SON_MP3_KALITE="128k" ;;
                *) SON_MP3_KALITE="320k" ;;
            esac
            _kaydet_ayarlar
        fi

        VIDEO_LISTESI="$HOME/.mp3_donustur_tmp.txt"
        > "$VIDEO_LISTESI"
        [ -d "$SON_MP3_KAYNAK" ] && find "$SON_MP3_KAYNAK" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) >> "$VIDEO_LISTESI"

        toplam=$(wc -l < "$VIDEO_LISTESI")
        if [[ "$toplam" -eq 0 ]]; then
            echo -e "${RED}❌ Klasörde video bulunamadı!${RESET}"; rm -f "$VIDEO_LISTESI"; SON_MP3_KAYNAK=""; sleep 2; continue
        fi

        clear
        echo -e "${CYAN}🚀 Dönüştürme Başlatıldı, Lütfen Bekleyin...${RESET}"
        _kapak_jpg_hazirla

        basarili=0; atlanan=0; hatali=0; sayac=0
        while IFS= read -r video; do
            [[ -z "$video" ]] && continue
            sayac=$((sayac + 1))
            isim_base="$(basename "${video%.*}")"
            cikti_dosya="$(dirname "$video")/${isim_base}.mp3"

            if [[ -f "$cikti_dosya" ]]; then ((atlanan++)); _ilerleme_goster "$sayac" "$toplam"; continue; fi

            _ilerleme_goster "$sayac" "$toplam"
            ffmpeg_err=$(mktemp)

            if [ -n "$KAPAK_JPG" ]; then
                ffmpeg -i "$video" -i "$KAPAK_JPG" -map 0:a:0 -map 1:0 -acodec libmp3lame -ab "$SON_MP3_KALITE" -ar 44100 -c:v:0 mjpeg -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "$cikti_dosya" -y -loglevel error 2> "$ffmpeg_err"
                sonuc=$?
            else sonuc=1; fi

            if [ $sonuc -ne 0 ]; then
                rm -f "$cikti_dosya"
                ffmpeg -i "$video" -vn -acodec libmp3lame -ab "$SON_MP3_KALITE" -ar 44100 "$cikti_dosya" -y -loglevel error 2> "$ffmpeg_err"
                sonuc=$?
            fi

            if [ $sonuc -eq 0 ]; then ((basarili++))
            else ((hatali++)); rm -f "$cikti_dosya"; echo "$video -> Başarısız" >> "$HATA_LOG"; fi
            rm -f "$ffmpeg_err"
        done < "$VIDEO_LISTESI"

        rm -f "$VIDEO_LISTESI"
        echo -e "\n\n${GREEN}📊 ÖZET: ✓ Dönüşen: $basarili${RESET} | ${BLUE}→ Atlanan: $atlanan${RESET} | ${RED}✗ Hatalı: $hatali${RESET}"
        read -p "Geri dönmek için [Enter]'a bas..." _
        return
    done
}

muzik_kapak_menu() {
    while true; do
        clear
        echo -e "${MAGENTA}━━━━━━━🎨 MÜZİKLERE KAPAK RESMİ EKLE ━━━━━━━${RESET}"
        if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
            echo -e "${RED}❌ HATA: Önce ana menüden bir albüm kapağı resmi seçmelisin!${RESET}"; sleep 2; return
        fi

        _klasor_sec_oneri "Müzik Klasörünü Seçin" "$SON_MUZIK_KLASOR"
        local ret=$?
        [ $ret -eq 2 ] && return
        [ $ret -ne 0 ] && { sleep 1; continue; }
        SON_MUZIK_KLASOR="$SECILEN_KLASOR"
        _kaydet_ayarlar

        MUZIK_LISTESI="$HOME/.muzik_kapak_tmp.txt"
        find "$SON_MUZIK_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \) > "$MUZIK_LISTESI"
        toplam=$(wc -l < "$MUZIK_LISTESI")

        if [[ "$toplam" -eq 0 ]]; then
            echo -e "${RED}❌ Klasörde müzik dosyası bulunamadı!${RESET}"; rm -f "$MUZIK_LISTESI"; SON_MUZIK_KLASOR=""; sleep 2; continue
        fi

        _kapak_jpg_hazirla
        sayac=0; basarili=0; hatali=0
        echo -e "${GREEN}Kapak resimleri müzik dosyalarına işleniyor...${RESET}"

        while IFS= read -r muzik; do
            [[ -z "$muzik" ]] && continue
            sayac=$((sayac + 1))
            _ilerleme_goster "$sayac" "$toplam"

            uzanti="${muzik##*.}"
            temp_muzik="$(dirname "$muzik")/.tmp_mzk_$$_${sayac}.${uzanti}"

            if [[ "${uzanti,,}" == "mp3" ]]; then
                ffmpeg -i "$muzik" -i "$KAPAK_JPG" -map 0:a:0 -map 1:0 -acodec copy -c:v:0 mjpeg -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "$temp_muzik" -y -loglevel quiet
            else
                ffmpeg -i "$muzik" -i "$KAPAK_JPG" -map 0:a:0 -map 1:0 -acodec copy -c:v:0 mjpeg -disposition:v:0 attached_pic "$temp_muzik" -y -loglevel quiet
            fi

            if [[ $? -eq 0 ]]; then mv "$temp_muzik" "$muzik"; ((basarili++))
            else rm -f "$temp_muzik"; ((hatali++)); fi
        done < "$MUZIK_LISTESI"

        rm -f "$MUZIK_LISTESI"
        echo -e "\n\n${GREEN}📊 ÖZET: ✓ Kapak Eklendi: $basarili${RESET} | ${RED}✗ Hata: $hatali${RESET}"
        read -p "Geri dönmek için [Enter]'a bas..." _
        return
    done
}

ana_menu() {
    while true; do
        clear
        # Şekilli Şukullu Rengarenk ASCII Yasin/Samiullah Başlığı
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${GREEN}  ____    _    __  __ ___ _   _ _   _ _        _    _   _   ${RESET}"
        echo -e "${GREEN} / ___|  / \  |  \/  |_ _| | | | | | | |      / \  | | | |  ${RESET}"
        echo -e "${GREEN} \___ \ / _ \ | |\/| || || | | | | | | |     / _ \ | |_| |  ${RESET}"
        echo -e "${GREEN}  ___) / ___ \| |  | || || |_| | |_| | |___ / ___ \|  _  |  ${RESET}"
        echo -e "${GREEN} |____/_/   \_\_|  |_|____\___/ \___/|_____/_/   \_\_| |_|  ${RESET}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
        echo -e "                  ${MAGENTA}🎶 MÜZİK VE SES KUTUSU 🎶${RESET}\n"
        
        # Durum Çubuğu bilgileri
        echo -e "  ${WHITE}🖼️  Mevcut Kapak   :${RESET} ${YELLOW}${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
        echo -e "  ${WHITE}📂 Hafıza Klasör   :${RESET} ${BLUE}${SON_MP3_KAYNAK:-'Kayıt yok'}${RESET}"
        echo -e "  ${WHITE}⚡ Kayıtlı Kalite  :${RESET} ${CYAN}${SON_MP3_KALITE:-'Kayıt yok'}${RESET}"
        echo -e "${CYAN}--------------------------------------------------------------${RESET}"
        echo -e "  📌 ${YELLOW}İŞLEM MENÜSÜ:${RESET}"
        echo -e "  ${GREEN}[1]${RESET} Video -> MP3 Dönüştür        ${GREEN}(🔥 Hafızalı Hızlı Mod)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Müziklere Albüm Kapağı Ekle  ${YELLOW}(Müzik çalarda resimli gösterir)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Albüm Kapağı Resmi Seç / Değiştir"
        echo -e "  ${GREEN}[4]${RESET} Bütün Hafıza Kayıtlarını Sıfırla"
        echo -e "  ${RED}[0]${RESET} Güvenli Çıkış"
        echo -e "${CYAN}==============================================================${RESET}"
        read -p " Yapmak istediğiniz işlem numarasını girin: " secim

        case $secim in
            1) mp3_donustur_menu ;;
            2) muzik_kapak_menu ;;
            3)  read -p "Gömülecek resmin tam yolunu girin: " yeni_r
                if [ -f "$yeni_r" ]; then
                    VARSAYILAN_RESIM="$yeni_r"
                    _kaydet_ayarlar
                    echo -e "${GREEN}✓ Albüm kapağı başarıyla kaydedildi.${RESET}"
                else echo -e "${RED}❌ Hata: Belirttiğiniz dosya yolu bulunamadı!${RESET}"; fi
                sleep 1.5 ;;
            4)  rm -f "$HOME/.muzik_ayarlari.conf"
                VARSAYILAN_RESIM=""; SON_MP3_KAYNAK=""; SON_MP3_KALITE=""; SON_MUZIK_KLASOR=""
                echo -e "${YELLOW}✓ Bütün hafıza kayıtları temizlendi.${RESET}"
                sleep 1.5 ;;
            0) echo -e "${CYAN}Güle güle kanka! Çıkış yapıldı.${RESET}"; exit 0 ;;
            *) echo -e "${RED}Geçersiz numara! Lütfen menüdeki rakamlardan seçin.${RESET}"; sleep 1.5 ;;
        esac
    done
}

ana_menu
EOF
chmod +x ~/Video-to-MP3/muzik_isleyici.sh
grep -q 'alias mp3=' ~/.bashrc || echo "alias mp3='bash ~/Video-to-MP3/muzik_isleyici.sh'" >> ~/.bashrc
source ~/.bashrc
echo -e "\n\e[1;32m✅ YENİ ŞEKİLLİ MENÜ BAŞARIYLA AYARLANDI!\e[0m\n👉 Şimdi sadece \e[1;36mmp3\e[0m yazıp Enter'a bas kanka!"

