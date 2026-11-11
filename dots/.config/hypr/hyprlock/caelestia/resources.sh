#!/usr/bin/env bash
# caelestia4 hyprlock: resources card (CPU, memory, GPU)
source "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/scripts/caelestia4/tr.sh" 2>/dev/null || { tr_() { printf '%s' "$1"; }; tr_pad() { printf '%s  ' "$1"; }; }
read -r _ a b c idle rest < /proc/stat; t1=$((a+b+c+idle)); i1=$idle; sleep 0.4
read -r _ a b c idle rest < /proc/stat; t2=$((a+b+c+idle)); i2=$idle
cpu=$(( (100 * ((t2-t1) - (i2-i1))) / ((t2-t1) > 0 ? (t2-t1) : 1) ))
mem=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "%.1f / %.0f GiB", (t-a)/1048576, t/1048576}' /proc/meminfo) # locale-independent
# The GPU driving a screen: NVIDIA's through its tool, others' from sysfs. Any other is left alone (a laptop's second
# GPU): reading it, every 3 s while locked, wakes it or keeps it from going to sleep.
sys="${CAELESTIA4_SYSFS:-/sys}"
gpu=""
for pass in nvidia sysfs; do
    for dev in "$sys"/class/drm/card*/device; do
        [[ $dev =~ /card[0-9]+/device$ ]] || continue # not the connectors (card1-DP-1)
        [[ $(cat "$dev/power/runtime_status" 2>/dev/null) == suspended ]] && continue
        grep -qsx connected "${dev%/device}"-*/status || continue
        if [[ $pass == nvidia ]]; then
            [[ $(cat "$dev/vendor" 2>/dev/null) == 0x10de ]] || continue
            gpu=$(nvidia-smi --id="$(basename "$(readlink -f "$dev")")" --query-gpu=utilization.gpu,temperature.gpu,memory.used --format=csv,noheader,nounits 2>/dev/null |
                awk -F', ' 'NR == 1 && $1 ~ /^[0-9]+$/ {printf "%s%%", $1
                    if ($2 ~ /^[0-9]+(\.[0-9]+)?$/) printf " · %d°C", int($2 + 0.5) # some drivers give decimals
                    if ($3 ~ /^[0-9]+$/) printf " · %.1f GiB", $3/1024}') # it prints its errors here too
        else
            busy=$(cat "$dev/gpu_busy_percent" 2>/dev/null) || continue
            [[ -n $busy ]] || continue
            gpu="$busy%"
            temp=$(cat "$dev"/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
            [[ -n $temp ]] && gpu+=" · $((temp / 1000))°C"
            vram=$(cat "$dev/mem_info_vram_used" 2>/dev/null)
            [[ -n $vram ]] && gpu+=$(awk -v b="$vram" 'BEGIN {printf " · %.1f GiB", b/1073741824}')
        fi
        [[ -n $gpu ]] && break 2
    done
done
printf '<span alpha="70%%">CPU</span>     %s%%\n' "$cpu"
printf '<span alpha="70%%">%s</span>%s\n' "$(tr_pad "$(tr_ "Memory")" 8)" "$mem"
[[ -n "$gpu" ]] && printf '<span alpha="70%%">GPU</span>     %s\n' "$gpu"
