# This script depends on `functions.sh' .
# This script is not for direct execution, instead it should be sourced by other script. It does not need execution permission or shebang.

# shellcheck shell=bash

# caelestia4: end-4's Rubik, Gabarito, Bibata, MicroTeX and uv installers for other distros are gone. On Arch
# the illogical-impulse-* packages in sdata/dist-arch install what is still used (Gabarito isn't).

install-python-packages(){
  UV_NO_MODIFY_PATH=1
  ILLOGICAL_IMPULSE_VIRTUAL_ENV=$XDG_STATE_HOME/quickshell/.venv
  x mkdir -p $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)
  # we need python 3.12 https://github.com/python-pillow/Pillow/issues/8089
  try uv venv --prompt .venv $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV) -p 3.12
  x source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
  x uv pip install -r ${REPO_ROOT}/sdata/uv/requirements.txt
  x deactivate
}
