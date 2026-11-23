# Contributing

Thanks for helping. This is a one-person fork, so small, tested changes get merged fastest. Read [SCOPE.md](../SCOPE.md)
first: it says what the fork covers and when to ask before writing code.

## Questions, bugs and ideas

- **Questions and help**: [Discussions](https://github.com/LKPJohn2026/caelestia_4/discussions).
- **Bugs**: an issue with the bug form, including the output of `./diagnose`. Reports without it usually can't be
  looked at.
- **Ideas**: the feature form. For anything big, wait for an answer before you start (see SCOPE.md).
- **Security problems**: privately, see [SECURITY.md](SECURITY.md).
- **Upstream bugs**: if it also happens on end-4's dots or in Caelestia, report it there.

## Pull requests

- **One change per pull request.** A fix and an unrelated clean-up are two pull requests.
- **Target `main`.**
- **Don't change defaults to your taste.** Keybinds, looks and behaviour you prefer go in your own overrides
  (`~/.config/hypr/custom/`, the shell's settings). A new feature that changes how things look or behave is off by
  default.
- **Anything outside `$HOME`** (sudo, `/etc`, PAM, system services) must be opt-in, print what it will do before
  doing it, and have a way back.
- **Test it on your machine**, and say in the pull request what you tested and what you couldn't. For shell changes:
  - `tools/ci-lint.sh`: what CI's Lint job runs (Lua, JSON and Python syntax, shellcheck, `tools/lint-caelestia.sh`,
    Nexus coverage, no monitor data, and the offline tests in `tools/tests/`)
  - `tools/ci-qml.sh`: what CI's QML job runs. It loads the Caelestia plugin offscreen (`tools/tests/plugin-smoke`)
    and compiles the shell's QML in a sandbox with a private headless `sway`, without running it
    (`tools/compile-check.sh`). It needs this fork's Quickshell, the plugin (`tools/build-caelestia-plugin.sh`),
    `sway`, `dbus-run-session` and `rsync`. Without `sway` it skips the compile step and exits 2, so it never uses
    your running session.
  - restart the shell and check its log:
    `systemctl --user restart caelestia4-shell.service`, then
    `journalctl --user -u caelestia4-shell.service -b`. No new warnings.
- **CI** runs both on every pull request, forks included, with read-only access and no secrets:
  - `.github/workflows/lint.yml` runs `tools/ci-lint.sh` on Ubuntu in under a minute.
  - `.github/workflows/qml.yml` runs `tools/ci-qml.sh` in an Arch container. It first builds this fork's Quickshell
    from `packaging/caelestia4-quickshell`, the Caelestia plugin, and libcava and M3Shapes from pinned upstream
    sources (`tools/ci/`). These builds are cached, but pull requests only read the cache, so a pull request that
    changes the Quickshell package or the plugin builds them again, which takes about 10 minutes.
  - A red run means the change isn't ready. If you think a failure isn't caused by your change, say so in the pull
    request.
- **Visible changes need a screenshot or a short recording.**
- **Translations**: new user-facing strings go through the existing translation functions. Missing Vietnamese text is
  fine: `tools/i18n-missing.py` lists it (with `--strict`, the strings themselves, and it fails when there are any).
- **Commit messages** follow the history: `Area: what changed`, e.g. `Lock: hide the password box after 10 s`.
- Pull requests are **squash-merged** by the maintainer into one signed commit, so you don't need to sign or tidy your
  commits. The pull request title becomes that commit's message.

## AI-assisted contributions

They are welcome when you have read, run and understood the change, and you can answer questions about it. Say so in
the pull request. Pull requests or reports that are clearly generated and not checked (invented APIs, untested code,
long generic text) will be closed.

## Licence

By contributing you agree that your work is published under the repository's licence, GPL-3.0.
