#!/data/data/com.termux/files/usr/bin/bash

# ===== BOT INFO =====
TOKEN="7872249481:AAG8R90P-FiYZd98LDKTyFRu0ov7YRiGuhQ"
CHAT_ID="6801143820"
INTERVAL=15
IMG="/sdcard/screen.png"

APPS_PACKAGE=("com.roblox.betaw2" "com.roblox.beta" "com.roblox.betav")

# ===== Helper Functions =====
send_msg() {
  curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$1"
}

edit_msg() {
  local msg_id=$1
  local text=$2
  curl -s -X POST "https://api.telegram.org/bot$TOKEN/editMessageText" \
    -d chat_id="$CHAT_ID" \
    -d message_id="$msg_id" \
    -d text="$text" >/dev/null
}

send_photo() {
  curl -s -F chat_id="$CHAT_ID" -F photo=@"$IMG" \
    "https://api.telegram.org/bot$TOKEN/sendPhoto"
}

edit_photo() {
  local photo_id=$1
  curl -s -X POST "https://api.telegram.org/bot$TOKEN/editMessageMedia" \
    -F chat_id="$CHAT_ID" \
    -F message_id="$photo_id" \
    -F media="{\"type\":\"photo\",\"media\":\"attach://$IMG\"}" \
    -F attach://$IMG="$IMG" >/dev/null
}

draw_bar() {
  local percent=$1
  local width=20
  local filled=$((percent * width / 100))
  local empty=$((width - filled))
  bar=$(printf '█%.0s' $(seq 1 $filled))
  bar+=$(printf '░%.0s' $(seq 1 $empty))
  echo "$bar $percent%"
}

get_cpu() { top -bn1 | awk '/%cpu/ {print int(100-$8)}'; }
get_temp() { awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n1; }
get_bat() { cat /sys/class/power_supply/battery/capacity 2>/dev/null; }

get_mem() {
  MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  MEM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
  RAM_PCT=$((MEM_USED * 100 / MEM_TOTAL))

  SWAP_TOTAL=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
  SWAP_FREE=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
  SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
  if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_PCT=$((SWAP_USED * 100 / SWAP_TOTAL))
  else
    SWAP_PCT=0
  fi
}

to_gb() { awk "BEGIN {printf \"%.2f\", $1/1024/1024}"; }

get_active_apps() {
  su -c "dumpsys activity processes" 2>/dev/null \
    | grep ProcessRecord \
    | awk '{print $4}' \
    | sort -u \
    | head -n 10
}

get_app_ram() {
  local pkg=$1
  RAM_KB=$(su -c "dumpsys meminfo $pkg" 2>/dev/null | awk '/TOTAL/ {print $2}')
  RAM_GB=$(awk "BEGIN {printf \"%.2f\", $RAM_KB/1024/1024}")
}

get_app_fps() {
  local pkg=$1
  FPS=$(su -c "dumpsys gfxinfo $pkg framestats" 2>/dev/null \
    | awk '
      /Draw:/ {for(i=2;i<=NF;i++){sum+=$i; count++}}
      END{if(count>0){fps=int(1000/(sum/count)); print fps}else{print 0}}')
}

# ===== Kirim pesan awal =====
MSG="Inisialisasi monitor..."
res_text=$(send_msg "$MSG")
TEXT_ID=$(echo $res_text | awk -F'"message_id":' '{print $2}' | awk -F',' '{print $1}')

su -c "screencap -p $IMG"
res_photo=$(send_photo)
PHOTO_ID=$(echo $res_photo | awk -F'"message_id":' '{print $2}' | awk -F',' '{print $1}')

echo "Bot monitor aktif..."

# ===== Loop monitor =====
while true; do
  CPU=$(get_cpu)
  TEMP=$(get_temp)
  BAT=$(get_bat)
  get_mem
  ACTIVE_APPS=$(get_active_apps)

  APP_MSG=""
  for pkg in "${APPS_PACKAGE[@]}"; do
    get_app_ram "$pkg"
    get_app_fps "$pkg"
    APP_MSG+="$pkg RAM: ${RAM_GB} GB, FPS: $FPS"$'\n'
  done

  RAM_BAR=$(draw_bar $RAM_PCT)
  SWAP_BAR=$(draw_bar $SWAP_PCT)

  MSG="CPU   : $CPU%
RAM   : $RAM_BAR ($(to_gb $MEM_USED)GB / $(to_gb $MEM_TOTAL)GB)
SWAP  : $SWAP_BAR ($(to_gb $SWAP_USED)GB / $(to_gb $SWAP_TOTAL)GB)
Temp  : ${TEMP}°C
Bat   : ${BAT}%

Roblox info:
$APP_MSG
Apps aktif:
$ACTIVE_APPS"

  # Edit teks + foto
  edit_msg "$TEXT_ID" "$MSG"
  su -c "screencap -p $IMG"
  edit_photo "$PHOTO_ID"

  sleep $INTERVAL
done
