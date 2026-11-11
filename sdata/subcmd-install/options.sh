# Handle args for subcmd: install
# shellcheck shell=bash
showhelp(){
printf "Syntax: $0 ${SUBCMD_NAME} [OPTIONS]...

A step of end-4's installer. caelestia_4 is installed by ./install.sh: see docs/install.md.

Options:
  -h, --help                Print this help message and exit
  -f, --force               (Dangerous) Force mode without any confirm
  -c, --clean               Clean the build cache first
      --skip-alldeps        Skip the whole process installing dependency
      --skip-allsetups      Skip the whole process setting up permissions/services etc
  -s, --skip-sysupdate      Skip system package upgrade e.g. \"sudo pacman -Syu\"
      --skip-plasmaintg     Skip installing plasma-browser-integration
"
}
# caelestia4: the help lists only what install-deps and install-setups use. The other options belong to
# end-4's greeting and install-files steps, which this fork doesn't run, or to its check of other-distro
# dist-* folders (--ignore-outdate): they are still accepted so old command lines work, with a warning.
ignored_option(){
  printf "${STY_YELLOW}[$0]: Ignoring \"$1\": it does nothing for \"${SUBCMD_NAME}\" in caelestia_4.${STY_RST}\n"
}

cleancache(){
  rm -rf "${REPO_ROOT}/cache"
}

# `man getopt` to see more
para=$(getopt \
  -o hfFk:cs \
  -l help,force,firstrun,fontset:,clean,skip-allgreeting,skip-alldeps,skip-allsetups,skip-allfiles,ignore-outdate,skip-sysupdate,skip-plasmaintg,skip-backup,skip-quickshell,skip-fish,skip-hyprland,skip-hyprland-entry,skip-fontconfig,skip-miscconf,core,exp-files,via-nix \
  -n "$0" -- "$@")
[ $? != 0 ] && echo "$0: Error when getopt, please recheck parameters." && exit 1
#####################################################################################
## getopt Phase 1
# ignore parameter's order, execute options below first
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    -c|--clean) cleancache;shift;;
    --) shift;break ;;
    *) shift ;;
  esac
done
#####################################################################################
## getopt Phase 2

eval set -- "$para"
while true ; do
  case "$1" in
    ## Already processed in phase 1, but not exited
    -c|--clean) shift;;
    ## Ones without parameter
    -f|--force) ask=false;shift;;
    --skip-alldeps) SKIP_ALLDEPS=true;shift;;
    --skip-allsetups) SKIP_ALLSETUPS=true;shift;;
    -s|--skip-sysupdate) SKIP_SYSUPDATE=true;shift;;
    --skip-plasmaintg) SKIP_PLASMAINTG=true;shift;;
    # caelestia4: --core also skipped end-4's fish, fontconfig and misc config files, which install-files copied
    --core) SKIP_PLASMAINTG=true;shift;;
    -F|--firstrun|--skip-allgreeting|--skip-allfiles|--ignore-outdate|--skip-backup|--skip-hyprland|--skip-hyprland-entry|--skip-fish|--skip-quickshell|--skip-fontconfig|--skip-miscconf|--exp-files)
      ignored_option "$1";shift;;
    # caelestia4: dependencies come from pacman and the AUR here (./setup only runs on Arch), so Nix would
    # install a second, unmatched set next to them
    --via-nix)
      printf "${STY_RED}[$0]: \"--via-nix\" isn't supported: caelestia_4 installs its dependencies with pacman and yay on Arch.${STY_RST}\n"
      exit 1;;

    ## Ones with parameter
    --fontset) ignored_option "$1";shift 2;;

    ## Ending
    --) shift;break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
