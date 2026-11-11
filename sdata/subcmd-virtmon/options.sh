# Handle args for subcmd: checkdeps
# shellcheck shell=bash

VMON_RESOLUTION=1920x1080
VMON_FPS=60
VMON_POSITION=auto
VMON_SCALE=1
VMON_EXTRA=""
WAYVNC_LOGLEVEL=${WAYVNC_LOGLEVEL:-quiet}
# caelestia4: wayvnc runs here without a password, so by default only this machine can connect
VNC_LISTEN_ADDRESS=127.0.0.1

showhelp(){
echo -e "Syntax: $0 virtmon [OPTIONS]

Create virtual monitor for testing multi-monitors.

Options:
  -h, --help       Show this help message and exit
  -c, --clean      Clean all tester monitors and wayvnc sessions and exit
  -d, --daemon     Run in background
      --no-guard   Disable hypr_mon_guard. Tip: this process can
                   also be terminated using ${STY_BOLD}pkill hypr_mon_guard${STY_RST}
      --listen <addr>
                   Address wayvnc listens on, by default ${STY_UNDERLINE}$VNC_LISTEN_ADDRESS${STY_RST} (this machine only).
                   ${STY_UNDERLINE}0.0.0.0${STY_RST} lets other devices connect. There is no password:
                   anyone who can reach the port sees and controls the monitor.

For the syntax of following options, see also Hyprland Wiki:
  https://wiki.hypr.land/Configuring/Monitors
      --res <res>  Resolution, by default ${STY_UNDERLINE}$VMON_RESOLUTION${STY_RST}
      --fps <fps>  Refresh rate and FPS, by default ${STY_UNDERLINE}$VMON_FPS${STY_RST}
      --pos <pos>  Position, by default ${STY_UNDERLINE}$VMON_POSITION${STY_RST}
                   Examples: ${STY_UNDERLINE}auto-left${STY_RST}, ${STY_UNDERLINE}0x-1080${STY_RST}
      --sca <sca>  Scale, by default ${STY_UNDERLINE}$VMON_SCALE${STY_RST}
      --ext <ext>  Extra properties, e.g. ${STY_UNDERLINE}transform, 1${STY_RST}

Note 1:
  The virtual monitor will be served via wayvnc.
  You need a VNC client to connect to it.
  Recommended VNC client:
  - Android: AVNC (https://github.com/gujjwal00/avnc)
  - Linux X11, Windows and MacOS: TigerVNC (https://github.com/TigerVNC/tigervnc)
  - Linux Wayland: Remmina-VNC (https://remmina.org/remmina-vnc)

Note 2:
  You can run this subcommand multiple times to create multiple virtual monitor. To do this, use ${STY_UNDERLINE}-d${STY_RST} to run wayvnc in background and repeat again, or just open extra terminal/shell and run the subcommand again.

Note 3:
  By default only a VNC client on this device can connect, with ${STY_UNDERLINE}127.0.0.1${STY_RST} as the <IP>. To use a spare device on the same network, add ${STY_UNDERLINE}--listen 0.0.0.0${STY_RST} (only on a network you trust).
"
}
# `man getopt` to see more
para=$(getopt \
  -o hcd \
  -l help,clean,daemon,no-guard,listen:,res:,fps:,pos:,sca:,ext: \
  -n "$0" -- "$@")
[ $? != 0 ] && echo "$0: Error when getopt, please recheck parameters." && exit 1
#####################################################################################
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    --) shift;break ;;
    *) shift ;;
  esac
done

eval set -- "$para"
while true ; do
  case "$1" in
    -c|--clean) CLEAN_TESTER_MONITORS=true;shift;;
    -d|--daemon) RUNNING_IN_BACKGROUND=true;shift;;
    --no-guard) DISABLE_HYPR_MON_GUARD=true;shift;;
    --listen) VNC_LISTEN_ADDRESS="$2";shift 2;;
    --res) VMON_RESOLUTION="$2";shift 2;;
    --fps) VMON_FPS="$2";shift 2;;
    --pos) VMON_POSITION="$2";shift 2;;
    --sca) VMON_SCALE="$2";shift 2;;
    --ext) VMON_EXTRA=", $2";shift 2;;
    --) shift;break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
