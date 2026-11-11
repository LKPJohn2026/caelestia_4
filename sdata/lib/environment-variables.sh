# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
# caelestia4: only XDG_STATE_HOME is still read (install-python-packages). The other XDG_* defaults and
# the backup, listfile and firstrun paths were for end-4's install-files, uninstall and exp-merge.
XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

STY_RED='\e[31m'
STY_GREEN='\e[32m'
STY_YELLOW='\e[33m'
STY_BLUE='\e[34m'
STY_PURPLE='\e[35m'
STY_CYAN='\e[36m'

STY_BOLD='\e[1m'
STY_FAINT='\e[2m'
STY_SLANT='\e[3m'
STY_UNDERLINE='\e[4m'
STY_BLINK='\e[5m'
STY_INVERT='\e[7m'
STY_RST='\e[00m'
