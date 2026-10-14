#!/usr/bin/env bash
# caelestia4 hyprlock: resources card (CPU, memory, GPU)
read -r _ a b c idle rest < /proc/stat; t1=$((a+b+c+idle)); i1=$idle; sleep 0.4
read -r _ a b c idle rest < /proc/stat; t2=$((a+b+c+idle)); i2=$idle
cpu=$(( (100 * ((t2-t1) - (i2-i1))) / ((t2-t1) > 0 ? (t2-t1) : 1) ))
mem=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "%.1f / %.0f GiB", (t-a)/1048576, t/1048576}' /proc/meminfo) # locale-independent
gpu=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used --format=csv,noheader,nounits 2>/dev/null | awk -F', ' '{printf "%s%% · %s°C · %.1f GiB", $1, $2, $3/1024}')
printf '<span alpha="70%%">CPU</span>     %s%%\n' "$cpu"
printf '<span alpha="70%%">Bộ nhớ</span>  %s\n' "$mem"
[[ -n "$gpu" ]] && printf '<span alpha="70%%">GPU</span>     %s\n' "$gpu"
