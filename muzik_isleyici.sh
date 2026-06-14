cat > ~/muzik_isleyici.sh << 'ENDOFSCRIPT'
#!/data/data/com.termux/files/usr/bin/bash

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

_oku() {
    local prompt="$1"
    local varname="$2"
    printf "%b" "$prompt" > /dev/tty
    IFS= read -r "$varname" < /dev/tty
}

_kaydet_ayarlar() {
    printf 'VARSAYILAN_KLASOR="%s"\nVARSAYILAN_RESIM="%s"\n' \
        "$VARSAYILAN_KLASOR" "$VARSAYILAN_RESIM" > "$AYARLAR"
}

_hafiza_kontrol() {
    local hash
    hash=$(stat -c "%n|%s|%Y" "$1" 2>/dev/null)
    grep -qxF "$hash" "$HAFIZA_DB" 2>/dev/null
}

_hafiza_ekle() {
    local hash
    hash=$(stat -c "%n|%s|%Y" "$1" 2>/dev/null)
    echo "$hash" >> "$HAFIZA_DB"
}

_ilerleme_goster() {
    local simdi=$1 toplam=$2 isim="$3"
    local yuzde=$(( simdi * 100 / toplam ))
    local dolu=$(( yuzde / 4 )) bos=$(( 25 - dolu ))
    local bar="" i
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++)); do bar+="░"; done
    local kisa="${isim:0:30}"
    [ ${#isim} -gt 30 ] && kisa="${kisa}…"
    printf "\r  \033[1;36m[\033[1;32m%s\033[1;36m]\033[1;33m %3d%% \033[1;37m(%d/%d)\033[0m \033[1;35m%s\033[0m          " \
        "$bar" "$yuzde" "$simdi" "$toplam" "$kisa" > /dev/tty
}

_baslik() {
    local renk="$1" ikon="$2" metin="$3"
    printf "\n%b┌────────────────────────────────────────────────────┐%b\n" "$renk" "$RESET"
    printf "%b│  %s  %-48s│%b\n" "$renk" "$ikon" "$metin" "$RESET"
    printf "%b└────────────────────────────────────────────────────┘%b\n\n" "$renk" "$RESET"
}

kapak_ayarla() {
    printf "\033[H\033[J"
    _baslik "$BLUE" "🖼 " "KAPAK RESMİ AYARLA"
    printf "  %bŞu anki kapak: %b%s%b\n\n" "$CYAN" "$WHITE" "${VARSAYILAN_RESIM:-Ayarlanmamış}" "$RESET"
    _oku "  Tam yol yaz (örn: /sdcard/kapak.jpg)\n  > " yeni_resim
    if [ -z "$yeni_resim" ]; then
        printf "  %b✗ İptal.%b\n" "$RED" "$RESET"; sleep 1; return
    fi
    if [ ! -f "$yeni_resim" ]; then
        printf "  %b✗ Dosya bulunamadı!%b\n" "$RED" "$RESET"; sleep 2; return
    fi
    VARSAYILAN_RESIM="$yeni_resim"
    _kaydet_ayarlar
    printf "  %b✓ Kapak ayarlandı.%b\n" "$GREEN" "$RESET"
    sleep 2
}

video_to_mp3() {
    printf "\033[H\033[J"
    _baslik "$CYAN" "🚀" "VİDEO → MP3 DÖNÜŞTÜRÜCÜ"
    _oku "  MP4/MKV/WEBM Klasör Yolu [ENTER=varsayılan]: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then
        printf "  %b✗ Klasör bulunamadı!%b\n" "$RED" "$RESET"; sleep 2; return
    fi
    VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar

    if [ ! -f "$VARSAYILAN_RESIM" ]; then
        printf "  %b✗ Kapak ayarlanmamış! Önce [4] Kapak Ayarla.%b\n" "$RED" "$RESET"; sleep 2; return
    fi

    TEMP_LIST=$(mktemp)
    find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) | sort > "$TEMP_LIST"
    toplam_ham=$(wc -l < "$TEMP_LIST")

    if [ "$toplam_ham" -eq 0 ]; then
        printf "  %b✗ Video bulunamadı!%b\n" "$RED" "$RESET"; rm -f "$TEMP_LIST"; sleep 2; return
    fi

    FILTERED=$(mktemp)
    atlanan=0
    while IFS= read -r video; do
        if _hafiza_kontrol "$video"; then atlanan=$((atlanan+1))
        else echo "$video" >> "$FILTERED"; fi
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"

    toplam=$(wc -l < "$FILTERED")
    printf "  %bToplam:%b %d  %bAtlanacak:%b %d  %bİşlenecek:%b %d\n\n" \
        "$CYAN" "$WHITE" "$toplam_ham" "$YELLOW" "$WHITE" "$atlanan" "$GREEN" "$WHITE" "$toplam"

    if [ "$toplam" -eq 0 ]; then
        printf "  %b✓ Hepsi zaten işlenmiş.%b\n" "$GREEN" "$RESET"
        rm -f "$FILTERED"; sleep 2; return
    fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/MP3_Muzikler"
    mkdir -p "$CIKTI_DIR"
    printf "  %b➔ Dönüştürme başladı...%b\n\n" "$GREEN" "$RESET"

    islem=0
    while IFS= read -r video; do
        islem=$((islem+1))
        isim=$(basename "$video"); isim_base="${isim%.*}"
        _ilerleme_goster "$islem" "$toplam" "$isim_base"
        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
            -vn -map 0:a:0 -map 1:v:0 \
            -c:a libmp3lame -b:a 192k -ar 44100 -ac 2 \
            -c:v mjpeg -pix_fmt yuvj420p -disposition:v attached_pic \
            -id3v2_version 3 \
            -metadata title="$isim_base" -metadata album="Zal Film" \
            "$CIKTI_DIR/${PREFIX}${isim_base}.mp3" \
            -y -loglevel quiet 2>/dev/null
        [ $? -eq 0 ] && _hafiza_ekle "$video"
    done < "$FILTERED"
    rm -f "$FILTERED"

    printf "\n\n  %b✓ Tamamlandı! → %s%b\n" "$GREEN" "$CIKTI_DIR" "$RESET"
    _oku "  Enter..." _
}

mp3_kapak_degistir() {
    printf "\033[H\033[J"
    _baslik "$YELLOW" "🎶" "MP3 KAPAK & ETİKET GÜNCELLE"
    _oku "  MP3 Klasör Yolu [ENTER=varsayılan]: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then
        printf "  %b✗ Klasör bulunamadı!%b\n" "$RED" "$RESET"; sleep 2; return
    fi
    VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar

    if [ ! -f "$VARSAYILAN_RESIM" ]; then
        printf "  %b✗ Kapak ayarlanmamış! Önce [4] Kapak Ayarla.%b\n" "$RED" "$RESET"; sleep 2; return
    fi

    TEMP_LIST=$(mktemp)
    find "$VARSAYILAN_KLASOR" -maxdepth 1 -iname "*.mp3" | sort > "$TEMP_LIST"
    toplam_ham=$(wc -l < "$TEMP_LIST")

    if [ "$toplam_ham" -eq 0 ]; then
        printf "  %b✗ MP3 bulunamadı!%b\n" "$RED" "$RESET"; rm -f "$TEMP_LIST"; sleep 2; return
    fi

    FILTERED=$(mktemp)
    atlanan=0
    while IFS= read -r mp3; do
        if _hafiza_kontrol "$mp3"; then atlanan=$((atlanan+1))
        else echo "$mp3" >> "$FILTERED"; fi
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"

    toplam=$(wc -l < "$FILTERED")
    printf "  %bToplam:%b %d  %bAtlanacak:%b %d  %bİşlenecek:%b %d\n\n" \
        "$CYAN" "$WHITE" "$toplam_ham" "$YELLOW" "$WHITE" "$atlanan" "$GREEN" "$WHITE" "$toplam"

    if [ "$toplam" -eq 0 ]; then
        printf "  %b✓ Hepsi zaten işlenmiş.%b\n" "$GREEN" "$RESET"
        rm -f "$FILTERED"; sleep 2; return
    fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/ZalFilm_Kapakli_MP3ler"
    mkdir -p "$CIKTI_DIR"
    printf "  %b➔ Kapaklar değiştiriliyor...%b\n\n" "$GREEN" "$RESET"

    islem=0
    while IFS= read -r mp3; do
        islem=$((islem+1))
        isim=$(basename "$mp3"); isim_base="${isim%.*}"
        _ilerleme_goster "$islem" "$toplam" "$isim_base"

        if [[ "$isim_base" == "$PREFIX"* ]]; then
            temiz_isim="${isim_base#$PREFIX}"
        else
            temiz_isim="$isim_base"
        fi

        ffmpeg -i "$mp3" -i "$VARSAYILAN_RESIM" \
            -map 0:a:0 -map 1:v:0 \
            -c:a copy -c:v mjpeg -pix_fmt yuvj420p \
            -disposition:v attached_pic -id3v2_version 3 \
            -metadata title="$temiz_isim" -metadata album="Zal Film" \
            "$CIKTI_DIR/${PREFIX}${temiz_isim}.mp3" \
            -y -loglevel quiet 2>/dev/null
        [ $? -eq 0 ] && _hafiza_ekle "$mp3"
    done < "$FILTERED"
    rm -f "$FILTERED"

    printf "\n\n  %b✓ Bitti! → %s%b\n" "$GREEN" "$CIKTI_DIR" "$RESET"
    _oku "  Enter..." _
}

mp3_isim_temizle() {
    printf "\033[H\033[J"
    _baslik "$RED" "🧹" "METADATA & İSİM TEMİZLE + ZAL FİLM PREFIX"
    printf "  %bNot: Tüm metadata silinir, prefix eklenir.%b\n\n" "$YELLOW" "$RESET"

    _oku "  Klasör Yolu [ENTER=varsayılan]: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ ! -d "$girilen_klasor" ]; then
        printf "  %b✗ Klasör bulunamadı!%b\n" "$RED" "$RESET"; sleep 2; return
    fi
    VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar

    TEMP_LIST=$(mktemp)
    find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.mp3" \) | sort > "$TEMP_LIST"
    toplam_ham=$(wc -l < "$TEMP_LIST")

    if [ "$toplam_ham" -eq 0 ]; then
        printf "  %b✗ Dosya bulunamadı!%b\n" "$RED" "$RESET"; rm -f "$TEMP_LIST"; sleep 2; return
    fi

    FILTERED=$(mktemp)
    atlanan=0
    while IFS= read -r dosya; do
        if _hafiza_kontrol "$dosya"; then atlanan=$((atlanan+1))
        else echo "$dosya" >> "$FILTERED"; fi
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"

    toplam=$(wc -l < "$FILTERED")
    printf "  %bToplam:%b %d  %bAtlanacak:%b %d  %bİşlenecek:%b %d\n\n" \
        "$CYAN" "$WHITE" "$toplam_ham" "$YELLOW" "$WHITE" "$atlanan" "$GREEN" "$WHITE" "$toplam"

    if [ "$toplam" -eq 0 ]; then
        printf "  %b✓ Hepsi zaten işlenmiş.%b\n" "$GREEN" "$RESET"
        rm -f "$FILTERED"; sleep 2; return
    fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/Temiz_Muzikler"
    mkdir -p "$CIKTI_DIR"
    printf "  %b➔ Temizleniyor...%b\n\n" "$GREEN" "$RESET"

    islem=0
    while IFS= read -r dosya; do
        islem=$((islem+1))
        isim=$(basename "$dosya"); isim_base="${isim%.*}"
        _ilerleme_goster "$islem" "$toplam" "$isim_base"

        temiz_isim="$isim_base"
        temiz_isim="${temiz_isim#$PREFIX}"
        temiz_isim=$(printf '%s' "$temiz_isim" | sed \
            -e 's/〖[^〗]*〗//g' \
            -e 's/【[^】]*】//g' \
            -e 's/\[[^]]*\]//g' \
            -e 's/([^)]*)//g' \
            -e 's/^[[:space:]]*//' \
            -e 's/[[:space:]]*$//')
        [ -z "$temiz_isim" ] && temiz_isim="Muzik_$islem"

        if [[ "$dosya" == *.mp3 || "$dosya" == *.MP3 ]]; then
            ffmpeg -i "$dosya" \
                -map_metadata -1 -map 0:a:0 -c:a copy \
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
    done < "$FILTERED"
    rm -f "$FILTERED"

    printf "\n\n  %b✓ Bitti! → %s%b\n" "$GREEN" "$CIKTI_DIR" "$RESET"
    _oku "  Enter..." _
}

_hafiza_temizle() {
    printf "  %b⚠  Hafıza sıfırlansın mı? (e/h): %b" "$YELLOW" "$RESET"
    _oku "" onay
    if [[ "$onay" == "e" || "$onay" == "E" ]]; then
        rm -f "$HAFIZA_DB"
        printf "  %b✓ Hafıza sıfırlandı.%b\n" "$GREEN" "$RESET"
    else
        printf "  %bİptal.%b\n" "$CYAN" "$RESET"
    fi
    sleep 1
}

ana_menu() {
    printf "\033[H\033[J"
    local hafiza_sayi=0
    [ -f "$HAFIZA_DB" ] && hafiza_sayi=$(wc -l < "$HAFIZA_DB")

    printf "%b╔══════════════════════════════════════════════════════╗%b\n" "$MAGENTA" "$RESET"
    printf "%b║%b  👑  SAMIULLAH DILSUZ PRODUCTION  👑               %b║%b\n" "$MAGENTA" "$YELLOW" "$MAGENTA" "$RESET"
    printf "%b╠══════════════════════════════════════════════════════╣%b\n" "$MAGENTA" "$RESET"
    printf "%b║%b  🎬  ZAL FİLM OTO-MATRİX SES & ETİKET PANELİ      %b║%b\n" "$MAGENTA" "$CYAN" "$MAGENTA" "$RESET"
    printf "%b╚══════════════════════════════════════════════════════╝%b\n" "$MAGENTA" "$RESET"
    printf "\n"
    printf "  %b📁 Klasör :%b %s%b\n" "$CYAN" "$WHITE" "${VARSAYILAN_KLASOR:-Ayarlanmamış}" "$RESET"
    printf "  %b🖼  Kapak  :%b %s%b\n" "$CYAN" "$GREEN" "${VARSAYILAN_RESIM:-⚠  Ayarlanmamış}" "$RESET"
    printf "  %b🧠 Hafıza :%b %d dosya kayıtlı%b\n" "$CYAN" "$YELLOW" "$hafiza_sayi" "$RESET"
    printf "\n"
    printf "%b──────────────────────────────────────────────────────%b\n" "$MAGENTA" "$RESET"
    printf "  %b[1]%b 🚀  Video → MP3 Dönüştür %b(Zal Film Kapağıyla)%b\n" "$YELLOW" "$WHITE" "$MAGENTA" "$RESET"
    printf "  %b[2]%b 🎶  MP3 Kapak & Etiket Değiştir%b\n" "$YELLOW" "$WHITE" "$RESET"
    printf "  %b[3]%b 🧹  Metadata & İsim Temizle %b+ Zal Film Prefix%b\n" "$YELLOW" "$WHITE" "$RED" "$RESET"
    printf "  %b[4]%b 🖼   Kapak Resmi Ayarla%b\n" "$YELLOW" "$WHITE" "$RESET"
    printf "  %b[5]%b 🧠  Hafızayı Sıfırla%b\n" "$YELLOW" "$WHITE" "$RESET"
    printf "  %b[6]%b 🚪  Çıkış%b\n" "$RED" "$WHITE" "$RESET"
    printf "%b──────────────────────────────────────────────────────%b\n" "$MAGENTA" "$RESET"
    _oku "  Seçiminiz [1-6]: " secim

    case $secim in
        1) video_to_mp3 ;;
        2) mp3_kapak_degistir ;;
        3) mp3_isim_temizle ;;
        4) kapak_ayarla ;;
        5) _hafiza_temizle ;;
        6) exit 0 ;;
    esac
    ana_menu
}

ana_menu
ENDOFSCRIPT
chmod +x ~/muzik_isleyici.sh && bash ~/muzik_isleyici.sh
