cat > ~/muzik_isleyici.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.muzik_ayarlari.conf" ] && source "$HOME/.muzik_ayarlari.conf"

KILIT_DOSYA="$HOME/.muzik_script.lock"
if [ -f "$KILIT_DOSYA" ]; then
    eski_pid=$(cat "$KILIT_DOSYA" 2>/dev/null)
    if [ -n "$eski_pid" ] && kill -0 "$eski_pid" 2>/dev/null; then
        echo "⚠️  UYARI: Script zaten başka bir oturumda çalışıyor!"
        exit 1
    fi
fi
echo $$ > "$KILIT_DOSYA"
trap 'rm -f "$KILIT_DOSYA"' EXIT

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; RESET='\033[0m'
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
    printf "\r  [%s] %3d%%  (%d/%d)" "$bar" "$yuzde" "$mevcut" "$toplam"
}

_kapak_jpg_hazirla() {
    KAPAK_JPG=""
    [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ] && return 1
    local hedef="$HOME/.muzik_kapak_cache.jpg"
    
    ffmpeg -i "$VARSAYILAN_RESIM" -vf "scale='min(1280,iw)':-2" \
        -frames:v 1 "$hedef" -y -loglevel quiet 2>/dev/null
    
    [ -f "$hedef" ] && { KAPAK_JPG="$hedef"; return 0; }
    return 1
}

_klasor_sec_oneri() {
    local baslik="$1"
    local son_deger="$2"

    echo -e "\n${YELLOW}[ $baslik ]${RESET}"
    echo -e "  📌 Klasör Seçenekleri:"
    echo -e "  [v] VidMate İndirmeleri  ${GREEN}(🔥 En Çok Kullanılan)${RESET}"
    echo -e "  [s] SnapTube İndirmeleri"
    echo -e "  [m] Telefonun Ana Müzik Klasörü (Music)"
    echo -e "  [o] Özel Dizin Yolu Gir"
    echo -e "  [x] Geri Dön"
    if [ -n "$son_deger" ]; then
        echo -e "  ${CYAN}[Enter] Son kullandığın klasörle devam et: $son_deger${RESET}"
    fi
    read -p "Seçiminizi yapın: " _src

    case "$_src" in
        "")
            if [ -n "$son_deger" ]; then
                SECILEN_KLASOR="$son_deger"
            else
                echo -e "${RED}Kayıtlı klasör yok! Lütfen bir harf seçin.${RESET}"; SECILEN_KLASOR=""; return 1
            fi
            ;;
        v|V) SECILEN_KLASOR="/storage/emulated/0/VidMate/download" ;;
        s|S) SECILEN_KLASOR="/storage/emulated/0/snaptube/download/SnapTube Video" ;;
        m|M) SECILEN_KLASOR="/storage/emulated/0/Music" ;;
        o|O)
           read -p "Dizin yolunu girin: " _custom
           if [ -z "$_custom" ] || [ ! -d "$_custom" ]; then
               echo -e "${RED}Geçersiz dizin!${RESET}"; SECILEN_KLASOR=""; return 1
           fi
           SECILEN_KLASOR="$_custom"
           ;;
        x|X) return 2 ;;
        *) echo -e "${RED}Geçersiz seçim!${RESET}"; SECILEN_KLASOR=""; return 1 ;;
    esac
    return 0
}

mp3_donustur_menu() {
    while true; do
        clear
        echo -e "${CYAN}========================================${RESET}"
        echo -e "${CYAN}        Video -> MP3 Dönüştürme${RESET}"
        echo -e "${CYAN}========================================${RESET}"

        if [ -n "$SON_MP3_KAYNAK" ]; then
            echo -e "  ${YELLOW}━━━ Hafızadaki Son Ayarların ━━━${RESET}"
            echo -e "  Klasör: $SON_MP3_KAYNAK"
            echo -e "  Kalite: ${SON_MP3_KALITE:-'320k'}"
            echo ""
            echo -e "  👉 ${GREEN}[Enter]  Aynen Devam Et (Hızlı & Önerilen Mod)${RESET}"
            echo -e "  👉 ${CYAN}[d]      Ayarları Sıfırla (Klasör/Kalite Değiştir)${RESET}"
            echo -e "  👉 ${RED}[x]      Ana Menüye Dön${RESET}"
            read -p "  Hangi adımla ilerleyelim?: " hizli_sec
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

            echo -e "\n${YELLOW}[ Ses Kalitesi Seçimi ]${RESET}"
            echo -e "  👉 ${GREEN}[Enter] 320k (Önerilen - En Net, Stüdyo Kalitesi Ses)${RESET}"
            echo -e "     [192]   192k (Orta Kalite - Standart)"
            echo -e "     [128]   128k (Düşük Kalite - Boyutu Küçük Olur)"
            read -p "Kalite Seçiminiz: " q
            case "$q" in
                128) SON_MP3_KALITE="128k" ;;
                192) SON_MP3_KALITE="192k" ;;
                *) SON_MP3_KALITE="320k" ;;
            esac
            _kaydet_ayarlar
        fi

        VIDEO_LISTESI="$HOME/.mp3_donustur_tmp.txt"
        > "$VIDEO_LISTESI"
        if [[ -d "$SON_MP3_KAYNAK" ]]; then
            find "$SON_MP3_KAYNAK" -maxdepth 1 -type f \
                \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) >> "$VIDEO_LISTESI"
        fi

        toplam=$(wc -l < "$VIDEO_LISTESI")
        if [[ "$toplam" -eq 0 ]]; then
            echo -e "${RED}  Seçilen klasörde dönüştürülecek video bulunamadı!${RESET}"
            rm -f "$VIDEO_LISTESI"; SON_MP3_KAYNAK=""; sleep 2; continue
        fi

        clear
        echo -e "${CYAN} Dönüştürme Başlatıldı, Lütfen Bekleyin...${RESET}"
        _kapak_jpg_hazirla

        basarili=0; atlanan=0; hatali=0; sayac=0
        while IFS= read -r video; do
            [[ -z "$video" ]] && continue
            sayac=$((sayac + 1))
            isim_base="$(basename "${video%.*}")"
            cikti_dosya="$(dirname "$video")/${isim_base}.mp3"

            if [[ -f "$cikti_dosya" ]]; then
                ((atlanan++)); _ilerleme_goster "$sayac" "$toplam"; continue
            fi

            _ilerleme_goster "$sayac" "$toplam"
            ffmpeg_err=$(mktemp)

            if [ -n "$KAPAK_JPG" ]; then
                ffmpeg -i "$video" -i "$KAPAK_JPG" \
                    -map 0:a:0 -map 1:0 \
                    -acodec libmp3lame -ab "$SON_MP3_KALITE" -ar 44100 \
                    -c:v:0 mjpeg -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" \
                    "$cikti_dosya" -y -loglevel error 2> "$ffmpeg_err"
                sonuc=$?
            else
                sonuc=1
            fi

            if [ $sonuc -ne 0 ]; then
                rm -f "$cikti_dosya"
                ffmpeg -i "$video" -vn -acodec libmp3lame -ab "$SON_MP3_KALITE" -ar 44100 \
                    "$cikti_dosya" -y -loglevel error 2> "$ffmpeg_err"
                sonuc=$?
            fi

            if [ $sonuc -eq 0 ]; then
                ((basarili++))
            else
                ((hatali++)); rm -f "$cikti_dosya"
                echo "$video -> Başarısız" >> "$HATA_LOG"
            fi
            rm -f "$ffmpeg_err"
        done < "$VIDEO_LISTESI"

        rm -f "$VIDEO_LISTESI"
        echo -e "\n\n${GREEN}✓ Dönüşen: $basarili${RESET} | ${BLUE}→ Zaten Var (Atlanan): $atlanan${RESET} | ${RED}✗ Hatalı: $hatali${RESET}"
        echo -e "\n${YELLOW}💡 Öneri: Ana menüye hızlıca dönmek için [Enter]'a bas.${RESET}"
        read -p "" _
        return
    done
}

muzik_kapak_menu() {
    while true; do
        clear
        echo -e "${CYAN}========================================${RESET}"
        echo -e "${CYAN}       Müziklere Kapak Resmi Ekle${RESET}"
        echo -e "${CYAN}========================================${RESET}"

        if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
            echo -e "${RED}HATA: Önce Ana Menüden bir albüm kapağı ayarlamalısın!${RESET}"
            sleep 2; return
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
            echo -e "${RED}Seçilen klasörün içinde ses dosyası bulunamadı!${RESET}"
            rm -f "$MUZIK_LISTESI"; SON_MUZIK_KLASOR=""; sleep 2; continue
        fi

        _kapak_jpg_hazirla
        sayac=0; basarili=0; hatali=0
        echo -e "${GREEN}Kapak resimleri müzik kutularına uyumlu şekilde gömülüyor...${RESET}"

        while IFS= read -r muzik; do
            [[ -z "$muzik" ]] && continue
            sayac=$((sayac + 1))
            _ilerleme_goster "$sayac" "$toplam"

            uzanti="${muzik##*.}"
            temp_muzik="$(dirname "$muzik")/.tmp_mzk_$$_${sayac}.${uzanti}"

            if [[ "${uzanti,,}" == "mp3" ]]; then
                ffmpeg -i "$muzik" -i "$KAPAK_JPG" -map 0:a:0 -map 1:0 -acodec copy -c:v:0 mjpeg \
                    -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" \
                    "$temp_muzik" -y -loglevel quiet
            else
                ffmpeg -i "$muzik" -i "$KAPAK_JPG" -map 0:a:0 -map 1:0 -acodec copy -c:v:0 mjpeg \
                    -disposition:v:0 attached_pic "$temp_muzik" -y -loglevel quiet
            fi

            if [[ $? -eq 0 ]]; then
                mv "$temp_muzik" "$muzik"
                ((basarili++))
            else
                rm -f "$temp_muzik"
                ((hatali++))
            fi
        done < "$MUZIK_LISTESI"

        rm -f "$MUZIK_LISTESI"
        echo -e "\n\n${GREEN}✓ Kapak Eklendi: $basarili Dosya${RESET} | ${RED}✗ Hata: $hatali Dosya${RESET}"
        echo -e "\n${YELLOW}💡 Öneri: Ana menüye hızlıca dönmek için [Enter]'a bas.${RESET}"
        read -p "" _
        return
    done
}

ana_menu() {
    while true; do
        clear
        echo "========================================="
        echo "          MÜZİK VE SES KUTUSU            "
        echo "========================================="
        echo "  Mevcut Kapak : ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
        echo "  Hafıza Klasör: ${SON_MP3_KAYNAK:-'Kayıt yok'}"
        echo "  Kayıtlı Kalite: ${SON_MP3_KALITE:-'Kayıt yok'}"
        echo "-----------------------------------------"
        echo "  📌 Akıllı Öneri Menüsü:"
        echo "  [v] Video -> MP3 Dönüştür   ${GREEN}(🔥 Önerilen - Hafızalı Hızlı Mod)${RESET}"
        echo "  [k] Müziklere Kapak Ekle    ${YELLOW}(Müzik çalarda resimli gösterir)${RESET}"
        echo "  [r] Albüm Kapağı Seç/Değiştir"
        echo "  [s] Hafızayı Sıfırla"
        echo "  [x] Çıkış"
        echo "========================================="
        read -p "Yapmak istediğiniz işlem (Harf girin): " secim

        case $secim in
            v|V) mp3_donustur_menu ;;
            k|K) muzik_kapak_menu ;;
            r|R)
                read -p "Gömülecek resmin tam yolunu girin: " yeni_r
                if [ -f "$yeni_r" ]; then
                    VARSAYILAN_RESIM="$yeni_r"
                    _kaydet_ayarlar
                    echo "Albüm kapağı başarıyla kaydedildi."
                else
                    echo "Hata: Belirttiğiniz dosya yolu bulunamadı!"
                fi
                sleep 1
                ;;
            s|S)
                rm -f "$HOME/.muzik_ayarlari.conf"
                VARSAYILAN_RESIM=""; SON_MP3_KAYNAK=""; SON_MP3_KALITE=""; SON_MUZIK_KLASOR=""
                echo "Bütün hafıza kayıtları başarıyla sıfırlandı."
                sleep 1
                ;;
            x|X) echo "Çıkış yapılıyor..."; exit 0 ;;
            *) echo "Geçersiz harf! Lütfen menüdeki harflerden birini seçin."; sleep 1 ;;
        esac
    done
}

ana_menu
EOF
chmod +x ~/muzik_isleyici.sh
echo -e "\n✅ Dosya başarıyla oluşturuldu!"
