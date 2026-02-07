#!/data/data/com.termux/files/usr/bin/bash

# ================= AUTO INSTALL =================
need_pkg() {
    if ! command -v "$1" >/dev/null 2>&1; then
        clear
        echo "Sedang menginstal modul, wait.. ($1)"
        pkg install -y "$1"
        exec "$0"
    fi
}

need_pkg bc
need_pkg curl
need_pkg coreutils
need_pkg  wget


# ================= COLOR (100% TERMUX SAFE) =================
RED="\033[31m"
YEL="\033[33m"
GRN="\033[32m"
NC="\033[0m"

color_percent() {
    p=$1
    if [ "$p" -ge 80 ]; then
        echo -e "${RED}${p}${NC}"
    elif [ "$p" -ge 50 ]; then
        echo -e "${YEL}${p}${NC}"
    else
        echo -e "${GRN}${p}${NC}"
    fi
}

# ================= BASIC INFO =================
PHONE="$(getprop ro.product.brand) $(getprop ro.product.model)"
DEVICE=$(getprop ro.product.device)
CHIPSET=$(getprop ro.soc.model)
BIT=$(getconf LONG_BIT)

# ================= UTILS =================
pause(){
    read -p "Enter lanjut..."
}

back_menu(){
    read -p "[Enter] balik | q keluar : " c
    [ "$c" != "q" ] && main_menu || exit
}

get_cpu(){
    top -bn1 | grep -o '[0-9]\+%' | head -1 | tr -d '%'
}

get_ram(){
    read t u <<< $(free -m | awk '/Mem:/ {print $2,$3}')
    echo $((u*100/t))
}

get_temp(){
    for t in /sys/class/thermal/thermal_zone*/temp; do
        [ -f "$t" ] && echo $(($(cat $t)/1000)) && return
    done
    echo "?"
}

get_battery_info() {
    BASE="/sys/class/power_supply/battery"
    cap=$(cat $BASE/capacity 2>/dev/null)
    stat=$(cat $BASE/status 2>/dev/null)
    health=$(cat $BASE/health 2>/dev/null)

    if [ -f "$BASE/temp" ]; then
        raw=$(cat $BASE/temp)
        temp=$((raw/10))
    else
        temp="?"
    fi

    if [ "$temp" != "?" ]; then
        if [ "$temp" -ge 45 ]; then
            tcolor="\033[31m"
        elif [ "$temp" -ge 38 ]; then
            tcolor="\033[33m"
        else
            tcolor="\033[32m"
        fi
        temp="${tcolor}${temp}°C\033[0m"
    fi

    echo "${cap}% | ${temp} | ${stat} | ${health}"
}

# ================= MODE 1 =================
info_mode() {
clear
echo "===== DEVICE INFO ====="
echo
echo "Phone   : $PHONE"
echo "Device  : $DEVICE"
echo "Chipset : $CHIPSET"
echo "Arch    : ${BIT}-bit"

# ===== STORAGE =====
read total_k used_k avail_k <<< $(df -k /data | awk 'NR==2 {print $2,$3,$4}')
sto_p=$((used_k*100/total_k))
sto_c=$(color_percent $sto_p)

printf "Storage : %.2fG free / %.2fG (%s%%)\n" \
"$(echo "$avail_k/1024/1024" | bc -l)" \
"$(echo "$total_k/1024/1024" | bc -l)" \
"$sto_c"

# ===== RAM =====
read total used <<< $(free -m | awk '/Mem:/ {print $2,$3}')
ram_p=$((used*100/total))
ram_c=$(color_percent $ram_p)

printf "RAM     : %.2fG / %.2fG (%s%%)\n" \
"$(echo "$used/1024" | bc -l)" \
"$(echo "$total/1024" | bc -l)" \
"$ram_c"

# ===== SWAP =====
read swapt swapu <<< $(free -m | awk '/Swap:/ {print $2,$3}')
if [ "$swapt" -gt 0 ]; then
    swap_p=$((swapu*100/swapt))
else
    swap_p=0
fi
swap_c=$(color_percent $swap_p)

printf "Swap    : %.2fG / %.2fG (%s%%)\n" \
"$(echo "$swapu/1024" | bc -l)" \
"$(echo "$swapt/1024" | bc -l)" \
"$swap_c"

# ===== BATTERY =====
bat=$(get_battery_info)
echo "Battery : $bat"

pause
}

# ================= MODE 2 =================
monitor_mode(){
echo "Live mode (CTRL+C buat stop)"
sleep 1
while true; do
clear
CPU=$(get_cpu)
RAM=$(get_ram)
TEMP=$(get_temp)
echo    "┏━⧉ 「 update v0.8 beta」──"
echo -e "│CPU  : $(color_percent $CPU)%"
echo -e "│RAM  : $(color_percent $RAM)%"
echo    "│Temp : ${TEMP}°C"
echo    "│Battery : $(get_battery_info)"
echo    "╰────────────────"

sleep 2
done
}

# ================= MODE 3 =================
install_apk_mode() {
read -p "Lanjut download & install? (y/n): " confirm
case "$confirm" in
y|Y) ;;
*) echo "Batal."; sleep 1; main_menu ;;
esac
clear

LINKS=(
"https://apponthego.com/uploads/file_69875b7294f95.apk"
"https://apponthego.com/uploads/file_69877b39e8361.apk"
"https://apponthego.com/uploads/file_69877bc9bead2.apk"
"https://apponthego.com/uploads/file_69877e1ade66d.apk"
)


# ================= MAIN =================

TMPDIR="$HOME/apk_tmp"
mkdir -p "$TMPDIR"

echo "===== AUTO DOWNLOAD & INSTALL APK ====="

for LINK in "${LINKS[@]}"; do

    FILE="$TMPDIR/app_$(date +%s%N).apk"

    echo
    echo "=============================="
    echo "[+] Downloading:"
    echo "$LINK"

    curl -L \
        --connect-timeout 15 \
        --max-time 300 \
        --retry 3 \
        -o "$FILE" "$LINK"

    # cek file valid
    if [ ! -s "$FILE" ]; then
        echo "❌ download gagal / file kosong"
        continue
    fi

    SIZE=$(du -h "$FILE" | cut -f1)
    echo "[+] Size: $SIZE"

    echo "[+] Installing..."
    su -c "pm install -r \"$FILE\""

    if [ $? -eq 0 ]; then
        echo "✅ Install sukses"
    else
        echo "❌ Install gagal (APK rusak / bukan APK / permission)"
    fi

done


echo
echo "[+] Cleaning..."
rm -rf "$TMPDIR"

echo "[ installer v 1.2 Beta ]"
echo "by ziel ★"
echo "===== DONE ====="
pause
main_menu
}

# ================ INFO UPDATE ================
info_update_mode(){

echo "╭─⧉ 「 update v1.0 beta」──"
echo "┃ # AUTO DOWNLOAD & INSTALL APK (v0.6)"
echo "┃ # fix bug"
echo "┃ # fix module"
echo "┃ # new module"
echo "┃ # support root / no root"
echo "┃ # root  : auto install"
echo "┃ # no root : manual install/devheck"
echo "┃ # new UI"
echo "┃ # cpu max mhz 
echo "┃ # swap ram
echo "╰────────────────"

pause
main_menu
}
cpu_boost_mode() {

clear
echo "===== CPU PERFORMANCE MODE ====="
echo
echo "[1] ON  (lock max MHz)"
echo "[2] OFF (balik normal auto scale)"
echo "[b] Back"
echo
read -p "Pilih: " c

case $c in
1)
    echo "[+] Lock MAX performance..."

    MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)

    su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > \$f; done"
    su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do echo $MAX > \$f; done"
    su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo $MAX > \$f; done"

    echo "✅ Locked ke max speed"
    pause
    main_menu
    ;;

2)
    echo "[+] Balikin NORMAL (auto scaling)..."

    MIN=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
    MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)

    su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo schedutil > \$f; done"
    su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do echo $MIN > \$f; done"
    su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo $MAX > \$f; done"

    echo "✅ Balik normal (bisa turun ke low MHz lagi)"
    pause
    main_menu
    ;;

b) main_menu ;;
*) cpu_boost_mode ;;
esac
}
# ================= SWAP MODE PRO =================
swap_mode() {

SWAPFILE="/data/local/tmp/swapfile"

while true; do
clear
echo "===== SWAP MANAGER ====="
echo
echo "[1] Buat & Aktifkan Swap"
echo "[2] Matikan Swap"
echo "[3] Hapus Swap"
echo "[4] Status"
echo "[0] Kembali"
echo

read -p "Pilih: " s

case $s in

1)
    read -p "Masukkan ukuran swap (MB): " SIZE

    if ! [[ "$SIZE" =~ ^[0-9]+$ ]]; then
        echo "❌ angka doang jir"
        sleep 1
        continue
    fi

    echo "[+] Membuat ${SIZE}MB..."

    su -c "swapoff $SWAPFILE 2>/dev/null"
    su -c "rm -f $SWAPFILE"

    su -c "dd if=/dev/zero of=$SWAPFILE bs=1M count=$SIZE status=progress"
    su -c "chmod 600 $SWAPFILE"
    su -c "mkswap $SWAPFILE"
    su -c "swapon $SWAPFILE"

    echo "✅ Swap aktif ${SIZE}MB"
    sleep 2
    ;;

2)
    su -c "swapoff $SWAPFILE 2>/dev/null"
    echo "❌ Swap OFF"
    sleep 1
    ;;

3)
    su -c "swapoff $SWAPFILE 2>/dev/null"
    su -c "rm -f $SWAPFILE"
    echo "🗑 Swap dihapus"
    sleep 1
    ;;

4)
    echo
    su -c "free -h"
    echo
    su -c "cat /proc/swaps"
    pause
    ;;

0)
    main_menu
    return
    ;;

*)
    ;;
esac

done
}
# ================= MENU =================
main_menu(){
clear
echo "┏━ ⊑ Welcome to tools 1.0 Beta ⊒" 
echo "│✎ 1 Device Info"
echo "│✎ 2 Live Monitor"
echo "│✎ 3 Install APK via Link"
echo "│✎ 4 Info Update"
echo "│✎ 5 CPU Max Performance"
echo "│✎ 6 Swap Manager"
echo "│✎ q Exit"
echo "╰──────────────"
echo 
read -p "Pilih: " opt
case $opt in
1) info_mode; back_menu ;;
2) monitor_mode; back_menu ;;
3) install_apk_mode ;;
4) info_update_mode ;;
5) cpu_boost_mode ;;
6) swap_mode ;;
q) exit ;;
*) main_menu ;;
esac
}

main_menu
