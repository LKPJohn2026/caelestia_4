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
  - `tools/lint-caelestia.sh`
  - `tools/compile-check.sh` (it compiles the shell's QML in a sandbox, without running it; it needs `rsync`,
    `dbus-run-session`, and `sway` or a running Wayland session)
  - restart the shell and check its log:
    `systemctl --user restart caelestia4-shell.service`, then
    `journalctl --user -u caelestia4-shell.service -b`. No new warnings.
- **Visible changes need a screenshot or a short recording.**
- **Translations**: new user-facing strings go through the existing translation functions. Missing Vietnamese text is
  fine: `tools/i18n-missing.py` lists it.
- **Commit messages** follow the history: `Area: what changed`, e.g. `Lock: hide the password box after 10 s`.
- Pull requests are **squash-merged** by the maintainer into one signed commit, so you don't need to sign or tidy your
  commits. The pull request title becomes that commit's message.

## AI-assisted contributions

They are welcome when you have read, run and understood the change, and you can answer questions about it. Say so in
the pull request. Pull requests or reports that are clearly generated and not checked (invented APIs, untested code,
long generic text) will be closed.

## Licence

By contributing you agree that your work is published under the repository's licence, GPL-3.0.
