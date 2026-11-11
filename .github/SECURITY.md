# Security policy

## Reporting a vulnerability

Please **don't open a public issue**. Report it privately through
[GitHub's private vulnerability reporting](https://github.com/LKPJohn2026/caelestia_4/security/advisories/new).

Include what an attacker can do, how to reproduce it, and which commit you tested. This is a one-person project:
expect an answer within about a week. Please give a fix time before you publish anything.

## What counts

Anything in this repository that could let someone get past the lock screen, run commands, or read things they
shouldn't. For example:

- the lock screen and its PAM use: unlocking without the password, the desktop showing before the unlock, a crash
  that leaves the session unlocked;
- command injection through data the shell reads: wallpaper and file names, media metadata and cover-art URLs,
  notifications, clipboard contents, network names, AI chat replies;
- the scripts that run `sudo`: `tools/update-sudo-rule.sh` (and the sudoers rule it installs),
  `tools/greetd-setup.sh`, `tools/fonts-install.sh` and the update script (`scripts/caelestia4/system-update.sh`);
  and the installers that change your session (`tools/install-main.sh`, `tools/uwsm-setup.sh`,
  `tools/keyring-switch.sh`);
- secrets: API keys and the keyring, files written with wrong permissions, secrets in logs.

Problems in Hyprland, Quickshell, Qt, greetd or another package belong to that project. If one of them comes from
code this fork took from [end-4](https://github.com/end-4/dots-hyprland) or
[Caelestia](https://github.com/caelestia-dots/shell), please report it to them as well.

## Supported versions

Only the latest `main`.
