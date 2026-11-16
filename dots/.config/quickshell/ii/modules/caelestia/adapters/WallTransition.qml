pragma Singleton

// caelestia4 ADAPTER: WallTransition
// Which of Caelestia's transition shaders the next wallpaper change plays: shell.json background.wallpaperTransition
// (Nexus → Wallpaper & style). One place for every player (the desktop wallpaper on each screen, the Nexus preview,
// later the lock), so they all play the same effect. pick() is asked once per transition, when it starts, and its
// result kept for that transition (TransitionPlayer.shader is a copy). The setting can differ per screen (a monitor's
// own shell.json), so the caller passes its screen's Config.background.
// Random (caelestia4 config background.transitionRandom): each change draws one from the pool, never the last one
// with noRepeat. One draw serves every player of the same change: screens and the Nexus preview each ask within a few
// frames of each other, so a pick made in the last `shareMs` is given again. The launcher's preview while scrolling
// wallpapers keeps the set transition, so scrolling through them isn't a different effect at every step.
// The time is the caller's (TransitionPlayer): shader.duration is the unscaled token, and the animation-speed scale is
// per screen (Tokens), which a singleton has none of.

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Shaders
import qs.modules.common as E4C

Singleton {
    id: root

    // the transition set for a screen: its own Config.background (shell.json, or ~/.config/caelestia/monitors/<screen>/
    // shell.json over it), which the caller passes, since a singleton has no screen; GlobalConfig's without one
    function chosenFor(background: var): transitionShader {
        const bg = background ?? GlobalConfig.background;
        let name = CUtils.enumToString(bg, "wallpaperTransition");
        if (!name)
            return Shaders.crossfade;
        name = name[0].toLowerCase() + name.slice(1);
        return Shaders[name] ?? Shaders.crossfade;
    }

    readonly property var random: E4C.Config.options.background.transitionRandom
    readonly property int shareMs: 250
    property string lastName // the last random draw (a WallTransition name, e.g. "Crossfade")
    property real lastAt
    property list<QtObject> sharedWith // the players that took the last draw: a second change of theirs draws again

    // a WallTransition name ("ChromaticBloom") as Caelestia.Shaders' property ("chromaticBloom"), or null
    function shaderNamed(name: string): var {
        if (!name)
            return null;
        return Shaders[name[0].toLowerCase() + name.slice(1)] ?? null;
    }

    // the names in the pool that are shaders, each once (the config can be edited by hand)
    function pool(): list<string> {
        return [...new Set((root.random?.pool ?? []).filter(n => root.shaderNamed(n) !== null))];
    }

    // one draw per change: another player asking within shareMs gets the same one (the same change on another screen,
    // or the Nexus preview); the same player asking again is a new change and draws anew
    function draw(player: QtObject): string {
        const now = Date.now();
        if (root.lastName && now - root.lastAt < root.shareMs && !root.sharedWith.includes(player)) {
            root.sharedWith = [...root.sharedWith, player];
            return root.lastName;
        }
        const all = root.pool();
        if (all.length === 0)
            return "";
        const others = all.filter(n => n !== root.lastName);
        const choices = root.random.noRepeat && others.length > 0 ? others : all;
        root.lastName = choices[Math.floor(Math.random() * choices.length)];
        root.lastAt = now;
        root.sharedWith = [player];
        return root.lastName;
    }

    // the shader for the transition starting now, for `player` (a WallpaperImpl), on the screen whose Config.background
    // this is
    function pick(background: var, player: QtObject): transitionShader {
        let s = null;
        if (root.random?.enable && !Wallpapers.showPreview)
            s = root.shaderNamed(root.draw(player));
        s = s ?? root.chosenFor(background);
        console.info(`[WallTransition] pick ${s.url.toString().split("/").pop()}`);
        return s;
    }
}
