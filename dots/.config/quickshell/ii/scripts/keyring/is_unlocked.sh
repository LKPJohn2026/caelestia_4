#!/usr/bin/env bash
# caelestia4: ask the Secret Service for its default collection instead of assuming gnome-keyring's "login"
# (KWallet's is /org/freedesktop/secrets/collection/kdewallet), falling back to "login".
collection=$(busctl --user call org.freedesktop.secrets /org/freedesktop/secrets \
    org.freedesktop.Secret.Service ReadAlias s default 2>/dev/null | sed -n 's/^o "\(.*\)"$/\1/p')
[[ -z "$collection" || "$collection" == "/" ]] && collection=/org/freedesktop/secrets/collection/login
locked_state=$(busctl --user get-property org.freedesktop.secrets \
    "$collection" \
    org.freedesktop.Secret.Collection Locked)
if [[ "${locked_state}" == "b false" ]]; then
    echo 'Keyring is unlocked' >&2
    exit 0
else
    echo 'Keyring is locked' >&2
    exit 1
fi
