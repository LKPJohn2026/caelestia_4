<!--
One change per pull request. Please read .github/CONTRIBUTING.md and SCOPE.md first.
The title becomes the commit message: "Area: what changed".
-->

## What changes

<!-- What and why. Link the issue: "Fixes #123". -->

## How you tested it

<!-- What you ran and what you checked. "It works" is not enough; say also what you couldn't test
(another GPU, several monitors, a laptop...). -->

- [ ] `tools/ci-lint.sh` passes
- [ ] `tools/compile-check.sh` passes (shell changes)
- [ ] I restarted the shell and its journal has no new warnings (shell changes)

## Screenshots

<!-- Before and after, or a short recording for animations. Or: "No visible change: <why>". -->

## Checklist

- [ ] One change only
- [ ] Defaults are unchanged, or the change of default is explained above
- [ ] Anything outside `$HOME` (sudo, `/etc`, PAM, services) is opt-in and reversible
- [ ] If AI helped, I have read and tested every line
