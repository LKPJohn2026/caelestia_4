import QtQuick
import Caelestia.Shaders

// caelestia4: one of Caelestia's wallpaper transitions (Caelestia.Shaders) between two items, for the desktop wallpaper
// (WallpaperImpl), and later the lock's entry, unlock and boot, so every one of them can play the same effect.
// Every shader takes only `progress` (0 = `from`, 1 = `to`) and the two samplers, so `from` and `to` can be any
// texture-providing items: an Image or Visual with layer.enabled, a ShaderEffectSource, a plain Rectangle with a layer.
// Most shaders write alpha 1 and ignore qt_Opacity: put this under any UI, and fade with the items, not with opacity.
// Timing is the caller's: `duration` is the final time in ms (the animation-speed scale already applied, or a fixed
// time such as the unlock's), nothing is scaled here.
ShaderEffect {
    id: root

    property Item from
    property Item to
    property real progress: 1
    // a value type: this keeps its own copy, so a change of setting during a transition doesn't swap the shader
    property transitionShader shader: Shaders.crossfade
    property int duration: 0
    readonly property bool running: anim.running

    signal finished

    visible: progress < 1
    fragmentShader: shader.url

    // the shader and its time for the next transition, at its first frame (progress 0) until start()
    function prepare(s: transitionShader, ms: int): void {
        anim.stop();
        shader = s;
        duration = Math.max(0, ms);
        progress = 0;
    }

    function start(): void {
        if (duration <= 0) {
            jumpToEnd();
            return;
        }
        anim.start();
    }

    // holds the frame it is at (a new change captures it as its `from`)
    function stop(): void {
        anim.stop();
    }

    function jumpToEnd(): void {
        anim.stop();
        progress = 1;
        finished();
    }

    NumberAnimation on progress {
        id: anim

        running: false
        to: 1
        duration: root.duration
        easing: root.shader.easing
        onFinished: root.finished()
    }
}
