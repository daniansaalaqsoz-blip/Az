#!/data/data/com.termux/files/usr/bin/bash

# ================= AUTO MODULE =================
need_pkg(){ command -v "$1" >/dev/null 2>&1 || pkg install -y "$1"; }
need_pkg coreutils
need_pkg util-linux
need_pkg wget
need_pkg curl
need_pkg bc

pause(){ read -p "Enter lanjut..."; }
need_root(){ if ! su -c "echo root" >/dev/null 2>&1; then echo "❌ Root required!"; exit 1; fi }

# ================= DEVICE INFO =================
PHONE="$(getprop ro.product.brand) $(getprop ro.product.model)"
DEVICE="$(getprop ro.product.device)"
CHIPSET="$(getprop ro.soc.model)"
BIT="$(getconf LONG_BIT)"

# ================= CPU / SWAP =================
cpu_boost(){
    need_root
    MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
    MIN=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
    echo "[1] Lock MAX MHz"; echo "[2] Balik NORMAL"; echo "[b] Back"; read -p "Pilih: " c
    case $c in
        1) su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > \$f; done"; su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do echo $MAX > \$f; done"; su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo $MAX > \$f; done"; echo "✅ CPU di-lock MAX MHz"; pause ;;
        2) su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo schedutil > \$f; done"; su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do echo $MIN > \$f; done"; su -c "for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo $MAX > \$f; done"; echo "✅ Balik normal"; pause ;;
        b) return ;; *) echo "Pilihan salah"; pause ;;
    esac
}

cpu_core_manager(){
    need_root
    CORES=$(ls /sys/devices/system/cpu/ | grep cpu[0-9] | wc -l)
    echo "[1] All ON"; echo "[2] Little cores"; echo "[3] Custom"; echo "[b] Back"; read -p "Pilih: " c
    case $c in
        1) for i in $(seq 0 $((CORES-1))); do su -c "echo 1 > /sys/devices/system/cpu/cpu$i/online"; done; echo "✅ Semua core ON"; pause ;;
        2) for i in $(seq 0 $((CORES-1))); do if [ $i -le 3 ]; then su -c "echo 1 > /sys/devices/system/cpu/cpu$i/online"; else su -c "echo 0 > /sys/devices/system/cpu/cpu$i/online"; fi; done; echo "✅ Little cores aktif"; pause ;;
        3) echo "Masukkan core (spasi pisah)"; read -a CUSTOM; for i in $(seq 0 $((CORES-1))); do if [[ " ${CUSTOM[@]} " =~ " $i " ]]; then su -c "echo 1 > /sys/devices/system/cpu/cpu$i/online"; else su -c "echo 0 > /sys/devices/system/cpu/cpu$i/online"; fi; done; echo "✅ Custom core aktif"; pause ;;
        b) return ;; *) echo "Pilihan salah"; pause ;;
    esac
}

swap_manager(){
    need_root
    SWAPFILE="/data/local/tmp/swapfile"
    echo "[1] Buat & Aktifkan Swap"; echo "[2] Matikan Swap"; echo "[3] Hapus Swap"; echo "[4] Status"; read -p "Pilih: " s
    case $s in
        1) read -p "Ukuran swap (MB): " SIZE; su -c "swapoff $SWAPFILE 2>/dev/null"; su -c "rm -f $SWAPFILE"; su -c "dd if=/dev/zero of=$SWAPFILE bs=1M count=$SIZE status=progress"; su -c "chmod 600 $SWAPFILE"; su -c "mkswap $SWAPFILE"; su -c "swapon $SWAPFILE"; echo "✅ Swap aktif ${SIZE}MB"; pause ;;
        2) su -c "swapoff $SWAPFILE"; echo "❌ Swap OFF"; pause ;;
        3) su -c "swapoff $SWAPFILE"; su -c "rm -f $SWAPFILE"; echo "🗑 Swap dihapus"; pause ;;
        4) su -c "free -h"; su -c "cat /proc/swaps"; pause ;;
        *) echo "Pilihan salah"; pause ;;
    esac
}

bg_kill(){ 
    need_root
    echo "Masukkan package background apps (spasi pisah):"; read -a PCKS
    for p in "${PCKS[@]}"; do su -c "am kill $p"; done
    echo "✅ Background apps mati"; pause
}

# ================= GAME BOOST =================
game_boost(){
    need_root
    echo "===== GAME BOOST MENU ====="
    echo "[1] Lock CPU Max"
    echo "[2] Kill Background Apps"
    echo "[3] Swap Boost"
    echo "[4] Low Shadow / Texture / AA (rekomendasi manual)"
    echo "[5] High FPS Mode (gabung semua tweak)"
    echo "[b] Back"
    read -p "Pilih: " g

    case $g in
        1) cpu_boost ;;
        2) bg_kill ;;
        3) swap_manager ;;
        4) echo "📌 Masuk ke config game atau rekomendasi manual"; pause ;;
        5)
            echo "🔥 Applying High FPS Mode..."
            cpu_boost; bg_kill; swap_manager
            echo "✅ High FPS Mode ON"; pause ;;
        b) return ;;
        *) echo "Pilihan salah"; pause ;;
    esac
}

# ================= MENU =================
main_menu(){
    clear
    echo "===== PERFORMANCE & GAME BOOSTER ====="
    echo "[1] Device Info"
    echo "[2] CPU Boost"
    echo "[3] CPU Core Manager"
    echo "[4] Swap Manager"
    echo "[5] Kill Background Apps"
    echo "[6] Game Boost"
    echo "[q] Exit"
    read -p "Pilih: " opt
    case $opt in
        1) echo "Phone: $PHONE | Device: $DEVICE | Chipset: $CHIPSET | $BIT-bit"; pause ;;
        2) cpu_boost ;;
        3) cpu_core_manager ;;
        4) swap_manager ;;
        5) bg_kill ;;
        6) game_boost ;;
        q) exit ;;
        *) main_menu ;;
    esac
    main_menu
}

main_menu
