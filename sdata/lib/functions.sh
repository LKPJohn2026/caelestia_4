# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
# NOTE that you NOT need to `cd ..' because the `$0' is NOT this file, but the script file which will source this file.

# shellcheck shell=bash

function try { "$@" || true; }
# caelestia4: v(), x() and pause() ask on stdin. When it is not a terminal or has hit EOF, read
# fails at once with an empty answer, so their "ask again" loops never ended (x() repeated the
# failing command forever). Stop instead: nobody is there to answer. A last answer without a
# newline still counts.
function read_answer_failed(){
  echo
  echo -e "${STY_RED}[$0]: Could not read an answer (stdin is not a terminal or has ended). Run it from a terminal. Exiting...${STY_RST}"
  exit 1
}
function v(){
  echo -e "####################################################"
  echo -e "${STY_BLUE}[$0]: Next command:${STY_RST}"
  echo -e "${STY_GREEN}$*${STY_RST}"
  local execute=true
  if $ask;then
    while true;do
      echo -e "${STY_BLUE}Execute? ${STY_RST}"
      echo "  y = Yes"
      echo "  e = Exit now"
      echo "  s = Skip this command (NOT recommended - your setup might not work correctly)"
      echo "  yesforall = Yes and don't ask again; NOT recommended unless you really sure"
      local p; read -p "====> " p || [[ -n "$p" ]] || read_answer_failed
      case $p in
        [yY]) echo -e "${STY_BLUE}OK, executing...${STY_RST}" ;break ;;
        [eE]) echo -e "${STY_BLUE}Exiting...${STY_RST}" ;exit ;break ;;
        [sS]) echo -e "${STY_BLUE}Alright, skipping this one...${STY_RST}" ;execute=false ;break ;;
        "yesforall") echo -e "${STY_BLUE}Alright, won't ask again. Executing...${STY_RST}"; ask=false ;break ;;
        *) echo -e "${STY_RED}Please enter [y/e/s/yesforall].${STY_RST}";;
      esac
    done
  fi
  if $execute;then x "$@";else
    echo -e "${STY_YELLOW}[$0]: Skipped \"$*\"${STY_RST}"
  fi
}
# When use v() for a defined function, use x() INSIDE its definition to catch errors.
function x(){
  if "$@";then local cmdstatus=0;else local cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command."
    echo -e "[Tip] If a certain package is failing to install, try installing it separately in another terminal.${STY_RST}"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    echo "  i = Ignore this error and continue (your setup might not work correctly)"
    local p; read -p " [R/e/i]: " p || [[ -n "$p" ]] || read_answer_failed
    case $p in
      [iI]) echo -e "${STY_BLUE}Alright, ignore and continue...${STY_RST}";cmdstatus=2;;
      [eE]) echo -e "${STY_BLUE}Alright, will exit.${STY_RST}";break;;
      *) echo -e "${STY_BLUE}OK, repeating...${STY_RST}"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "${STY_BLUE}[$0]: Command \"${STY_GREEN}$*${STY_BLUE}\" finished.${STY_RST}";;
    1) echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed. Exiting...${STY_RST}";exit 1;;
    2) echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed but ignored by user.${STY_RST}";;
  esac
}
function showfun(){
  echo -e "${STY_BLUE}[$0]: The definition of function \"$1\" is as follows:${STY_RST}"
  printf "${STY_GREEN}"
  type -a "$1" 2>/dev/null || return 1
  printf "${STY_RST}"
}
function pause(){
  if [ ! "$ask" == "false" ];then
    printf "${STY_FAINT}${STY_SLANT}"
    local p; read -p "(Ctrl-C to abort, Enter to proceed)" p || [[ -n "$p" ]] || read_answer_failed
    printf "${STY_RST}"
  fi
}
function remove_bashcomments_emptylines(){
  echo "pwd=$(pwd)"
  echo "input=$1"
  echo "output=$2"
  mkdir -p "$(dirname "$2")"
  cat "$1" | sed -e 's/#.*//' -e '/^[[:space:]]*$/d' > "$2"
}
function prevent_sudo_or_root(){
  case $(whoami) in
    root) echo -e "${STY_RED}[$0]: This script is NOT to be executed with sudo or as root. Aborting...${STY_RST}";exit 1;;
  esac
}

# Initialize sudo session and keep it alive in background
# Store PID in a global variable that can be accessed by trap
declare -g SUDO_KEEPALIVE_PID=""

function sudo_init_keepalive(){
  # Check if sudo is available
  if ! command -v sudo >/dev/null 2>&1; then
    return 0
  fi

  # Skip if already initialized
  if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
    return 0
  fi

  # Prompt for sudo password once at the beginning
  echo -e "${STY_CYAN}[$0]: Requesting sudo privileges for installation...${STY_RST}"
  if ! sudo true; then
    echo -e "${STY_RED}[$0]: Failed to obtain sudo privileges. Aborting...${STY_RST}"
    exit 1
  fi

  # Start background process to keep sudo session alive
  # This updates the sudo timestamp every 60 seconds
  (
    while true; do
      sleep 60
      sudo true 2>/dev/null || exit 0
    done
  ) &
  SUDO_KEEPALIVE_PID=$!

  echo -e "${STY_GREEN}[$0]: Sudo session initialized and will be kept alive (PID: $SUDO_KEEPALIVE_PID)${STY_RST}"
}

# Stop the sudo keepalive background process
function sudo_stop_keepalive(){
  if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    SUDO_KEEPALIVE_PID=""
  fi
}
# caelestia4: the helpers that only end-4's install-files, exp-update, exp-merge, uninstall and the
# other-distro outdate check used are gone with those steps.
function install_cmds(){
  case $OS_GROUP_ID in
    "arch")
      local pkgs=()
      for cmd in "$@";do
        # For package name which is not cmd name, use "case" syntax to replace
        case $cmd in
          ip) pkgs+=(iproute2);;
          *) pkgs+=($cmd) ;;
        esac
      done
      v sudo pacman -Syu
      v sudo pacman -S --noconfirm --needed "${pkgs[@]}"
      ;;
    *)
      printf "WARNING\n"
      printf "No method found to install package providing the commands:\n"
      printf "  $@\n"
      printf "Please install by yourself.\n"
      ;;
  esac
}

function ensure_cmds(){
  local not_found_cmds=()
  for cmd in "$@"; do
    if ! command -v $cmd >/dev/null 2>&1;then
      not_found_cmds+=($cmd)
    fi
  done
  if [[ ${#not_found_cmds[@]} -gt 0 ]]; then
    echo -e "${STY_YELLOW}[$0]: Not found: ${not_found_cmds[*]}.${STY_RST}"
    install_cmds "${not_found_cmds[@]}"
  fi
}
