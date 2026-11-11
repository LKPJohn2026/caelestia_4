# This script is meant to be sourced.
# It's not for directly running.
printf "${STY_CYAN}[$0]: 1. Install dependencies\n${STY_RST}"

# caelestia4: only Arch-based systems get here (setup refuses the rest), so there is no Nix route, no
# other-distro dist-* folder and no check for whether such a folder is behind dist-arch.
printf "./sdata/dist-arch/install-deps.sh will be used.\n"
source ./sdata/dist-arch/install-deps.sh
