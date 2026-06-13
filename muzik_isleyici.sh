#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.muzik_ayarlari.conf" ] && source "$HOME/.muzik_ayarlari.conf"

RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; BLUE='\e[1;34m'
MAGENTA='\e[1;35m'; CYAN='\e[1;36m'; WHITE='\e[1;37m'; RESET='\e[0m'
HATA_LOG="$HOME/muzik_hata_log.txt"
PREFIX="〖ذال فیلم تقدیم میکندょ〗"

_kaydet_ayarlar() {
    cat > "$HOME/.muzik_ayarlari.conf" << CONF
VARSAYILAN_RESIM="$VARSAYILAN_RESIM"
SON_MP3_KAYNAK="$SON_MP3_KAYNAK"
SON_MP3_KALITE="$SON_MP3_KALITE"
SON_MUZIK_KLASOR="$SON_MUZIK_KLASOR"
CONF
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
    echo -e "${YELLOW}┃${RESET}  ${CYAN}[1]${RESET} UC Downloads Videos  ${GREEN}(🔥 Senin Klasör)${RESET}"
    echo -e "${YELLOW}┃${RESET}  ${CYAN}[2]${RESET} VidMate İndirmeleri"
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
        1) SECILEN_KLASOR="/storage/emulated/0/Download/UCDownloads/video" ;;
        2) SECILEN_KLASOR="/storage/emulated/0/VidMate/download" ;;
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

        if [ ! -d "$SON_MP3_KAYNAK" ]; then
            echo -e "${RED}❌ Klasör bulunamadı!${RESET}"; SON_MP3_KAYNAK=""; sleep 2; continue
        fi

        clear
        echo -e "${CYAN}🚀 Dönüştürme Başlatıldı, Lütfen Bekleyin...${RESET}"
        _kapak_jpg_hazirla
        > "$HATA_LOG"

        export PREFIX SON_MP3_KALITE KAPAK_JPG HATA_LOG
        basarili=0; atlanan=0; hatali=0

        # Karakter sorununu kökten çözen find-exec mekanizması
        while IFS=':' read -r durum; do
            case "$durum" in
                "OK") ((basarili++)) ;;
                "SKIP") ((atlanan++)) ;;
                "ERR") ((hatali++)) ;;
            esac
            printf "\r  ${CYAN}[Processing]${RESET} ✓ Başarılı: %d | → Atlanan: %d | ✗ Hatalı: %d" "$basarili" "$atlanan" "$hatali"
        done < <(find "$SON_MP3_KAYNAK" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -exec bash -c '
            for video; do
                dizin="$(dirname "$video")"
                isim_base="$(basename "${video%.*}")"
                
                if [[ "$isim_base" == "$PREFIX"* ]]; then
                    cikti_dosya="$dizin/${isim_base}.mp3"
                else
                    cikti_dosya="$dizin/${PREFIX}${isim_base}.mp3"
                fi

                if [[ -f "$cikti_dosya" ]]; then
                    echo "SKIP"
                    continue
                fi

                if [ -n "$KAPAK_JPG" ] && [ -f "$KAPAK_JPG" ]; then
                    ffmpeg -i "$video" -i "$KAPAK_JPG" -map 0:a:0 -map 1:0 -acodec libmp3lame -ab "$SON_MP3_KALITE" -ar 44100 -c:v:0 mjpeg -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "$cikti_dosya" -y -loglevel quiet 2>/dev/null
                    sonuc=$?
                else
                    sonuc=1
                fi

                if [ $sonuc -ne 0 ]; then
                    rm -f "$cikti_dosya"
                    ffmpeg -i "$video" -vn -acodec libmp3lame -ab "$SON_MP3_KALITE" -ar 44100 "$cikti_dosya" -y -loglevel quiet 2>/dev/null
                    sonuc=$?
                fi

                if [ $sonuc -eq 0 ]; then
                    echo "OK"
                else
                    rm -f "$cikti_dosya"
                    echo "$video -> Başarısız" >> "$HATA_LOG"
                    echo "ERR"
                fi
            done
        ' _ {} +)

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

        clear
        echo -e "${GREEN}Kapak resimleri müzik dosyalarına işleniyor...${RESET}"
        _kapak_jpg_hazirla

        export KAPAK_JPG
        basarili=0; hatali=0

        while IFS=':' read -r durum; do
            case "$durum" in
                "OK") ((basarili++)) ;;
                "ERR") ((hatali++)) ;;
            esac
            printf "\r  ${CYAN}[İşleniyor]${RESET} ✓ Başarılı: %d | ✗ Hatalı: %d" "$basarili" "$hatali"
        done < <(find "$SON_MUZIK_KLASOR" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.m4a" \) -exec bash -c '
            for muzik; do
                dizin="$(dirname "$muzik")"
                uzanti="${muzik##*.}"
                temp_muzik="$dizin/.tmp_mzk_$$\_${uzanti}"

                if [[ "${uzanti,,}" == "mp3" ]]; then
                    ffmpeg -i "$muzik" -i "$KAPAK_JPG" -map 0:a:0 -map 1:0 -acodec copy -c:v:0 mjpeg -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "$temp_muzik" -y -loglevel quiet 2>/dev/null
                else
                    ffmpeg -i "$muzik" -i "$KAPAK_JPG" -map 0:a:0 -map 1:0 -acodec copy -c:v:0 mjpeg -disposition:v:0 attached_pic "$temp_muzik" -y -loglevel quiet 2>/dev/null
                fi

                if [[ $? -eq 0 ]]; then
                    mv "$temp_muzik" "$muzik"
                    echo "OK"
                else
                    rm -f "$temp_muzik"
                    echo "ERR"
                fi
            done
        ' _ {} +)

        echo -e "\n\n${GREEN}📊 ÖZET: ✓ Kapak Eklendi: $basarili${RESET} | ${RED}✗ Hata: $hatali${RESET}"
        read -p "Geri dönmek için [Enter]'a bas..." _
        return
    done
}

ana_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${GREEN}  ____    _    __  __ ___ _   _ _   _ _        _    _   _   ${RESET}"
        echo -e "${GREEN} / ___|  / \  |  \/  |_ _| | | | | | | |      / \  | | | |  ${RESET}"
        echo -e "${GREEN} \___ \ / _ \ | |\/| || || | | | | | | |     / _ \ | |_| |  ${RESET}"
        echo -e "${GREEN}  ___) / ___ \| |  | || || |_| | |_| | |___ / ___ \|  _  |  ${RESET}"
        echo -e "${GREEN} |____/_/   \_\_|  |_|____\___/ \___/|_____/_/   \_\_| |_|  ${RESET}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
        echo -e "                  ${MAGENTA}🎶 MÜZİK VE SES KUTUSU 🎶${RESET}\n"
        
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

