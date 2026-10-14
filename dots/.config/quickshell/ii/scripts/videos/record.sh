#!/usr/bin/env bash
# caelestia4: screen recording with gpu-screen-recorder (as Caelestia's `caelestia record`), replacing end-4's
# wf-recorder: NVENC encoding (HEVC at 7680x2160, where H.264 tops out at 4096 wide) and a real pause.
# Same flags as end-4's script, so every caller keeps working:
#   record.sh [--fullscreen] [--sound] [--region "X,Y WxH"]   start; or stop if a recording is running
#   record.sh --pause                                           pause / resume the running recording
# Without --fullscreen or --region a region is picked with slurp. Coordinates are logical (layout) pixels, like
# slurp's; gpu-screen-recorder scales them itself. The recorder runs as its own unit (uwsm-app), so restarting the
# shell doesn't cut a recording. gpu-screen-recorder can't report whether it's paused, so the pause state is kept
# in $XDG_RUNTIME_DIR/caelestia4-recording-paused (read by the shell's Recorder adapter).

RECORDER=gpu-screen-recorder
CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
PAUSED_FILE="${XDG_RUNTIME_DIR:-/tmp}/caelestia4-recording-paused"

CUSTOM_PATH=$(jq -r '.screenRecord.savePath // empty' "$CONFIG_FILE" 2>/dev/null)
RECORDING_DIR="${CUSTOM_PATH:-$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")}"

# pidof, not pgrep -x / pkill -x: process names are cut to 15 characters ("gpu-screen-reco"), so -x never matches
running() { pidof "$RECORDER" >/dev/null; }
signal() { local pids; pids=$(pidof "$RECORDER") && kill "-$1" $pids; }

REGION=""
SOUND=0
FULLSCREEN=0
PAUSE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --region)
            [[ -n "${2:-}" ]] || { notify-send -a Recorder "Đã huỷ ghi màn hình" "Thiếu vùng cho --region"; exit 1; }
            REGION="$2"; shift 2 ;;
        --sound) SOUND=1; shift ;;
        --fullscreen) FULLSCREEN=1; shift ;;
        --pause) PAUSE=1; shift ;;
        *) shift ;;
    esac
done

# ---------------------------------------------------------------- pause / resume
if [[ $PAUSE -eq 1 ]]; then
    running || exit 0
    signal USR2
    if [[ -e "$PAUSED_FILE" ]]; then rm -f -- "$PAUSED_FILE"; else : > "$PAUSED_FILE"; fi
    exit 0
fi

# ---------------------------------------------------------------- stop
if running; then
    signal INT # finish and close the file properly
    for _ in $(seq 1 100); do running || break; sleep 0.1; done
    rm -f -- "$PAUSED_FILE"
    last=$(ls -t "$RECORDING_DIR"/recording_*.mp4 2>/dev/null | head -1)
    # The notification waits for a click, so it lives in its own process
    (
        action=$(notify-send -a Recorder -A watch="Xem" -A open="Mở thư mục" \
            "Đã dừng ghi màn hình" "Đã lưu ${last:-vào $RECORDING_DIR}") || exit 0
        case "$action" in
            watch) [[ -n "$last" ]] && exec xdg-open "$last" ;;
            open) exec xdg-open "$RECORDING_DIR" ;;
        esac
    ) </dev/null >/dev/null 2>&1 &
    disown
    exit 0
fi

# ---------------------------------------------------------------- start
mkdir -p "$RECORDING_DIR"
monitors=$(hyprctl monitors -j)
args=()

if [[ $FULLSCREEN -eq 1 ]]; then
    read -r name rate < <(jq -r '.[] | select(.focused) | "\(.name) \(.refreshRate | round)"' <<<"$monitors")
    args+=(-w "$name" -f "${rate:-60}")
else
    if [[ -n "$REGION" ]]; then
        # end-4 / slurp "X,Y WxH" -> gpu-screen-recorder "WxH+X+Y"
        if [[ "$REGION" =~ ^(-?[0-9]+),(-?[0-9]+)\ ([0-9]+)x([0-9]+)$ ]]; then
            REGION="${BASH_REMATCH[3]}x${BASH_REMATCH[4]}+${BASH_REMATCH[1]}+${BASH_REMATCH[2]}"
        fi
    elif ! REGION=$(slurp -f '%wx%h+%x+%y'); then
        notify-send -a Recorder "Đã huỷ ghi màn hình" "Chưa chọn vùng"
        exit 1
    fi
    # Frame rate of the fastest monitor the region touches
    rate=$(jq -r --arg r "$REGION" '
        ($r | capture("(?<w>[0-9]+)x(?<h>[0-9]+)\\+(?<x>-?[0-9]+)\\+(?<y>-?[0-9]+)") | map_values(tonumber)) as $g
        | [.[] | select(.x < $g.x + $g.w and .x + .width / .scale > $g.x and .y < $g.y + $g.h and .y + .height / .scale > $g.y)
               | .refreshRate | round] | max // 60' <<<"$monitors")
    args+=(-w region -region "$REGION" -f "${rate:-60}")
fi

[[ $SOUND -eq 1 ]] && args+=(-a default_output)

file="$RECORDING_DIR/recording_$(date '+%Y-%m-%d_%H.%M.%S').mp4"
rm -f -- "$PAUSED_FILE"
# In the background: for a scope unit uwsm-app becomes the recorder itself and would only return when it ends
uwsm-app -- "$RECORDER" "${args[@]}" -o "$file" </dev/null >/dev/null 2>&1 &
disown

sleep 1
if running; then
    notify-send -a Recorder "Đang ghi màn hình" "$(basename "$file")"
else
    notify-send -a Recorder -u critical "Không ghi được màn hình" "$RECORDER ${args[*]} đã thoát ngay. Xem: journalctl --user -n 20"
fi
