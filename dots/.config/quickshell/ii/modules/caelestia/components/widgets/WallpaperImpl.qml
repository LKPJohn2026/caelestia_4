// caelestia4: Caelestia's wallpaper renderer (upstream 1c406e4e): Caelestia.Multimedia's Visual (stills cached as
// compressed KTX textures sized to the screen) and a transition shader from Caelestia.Shaders, played by
// TransitionPlayer with the shader WallTransition picks (shell.json background.wallpaperTransition, Nexus → Wallpaper &
// style), asked once per change when the old frame is captured: a pick made then can't be redrawn with another shader.
// Hybrid: only stills play here. A video wallpaper stays on mpvpaper (end-4's switchwall.sh; ~2% of a core instead of
// ~18% for QtMultimedia on a high-resolution screen), so `source` is its first-frame thumbnail and the background goes
// see-through while mpvpaper runs (Background.qml videoShowing). A video previewed from the launcher shows its first
// frame.
import QtQuick
import Caelestia
import Caelestia.Config
import Caelestia.Multimedia
import Caelestia.Shaders
import qs.modules.caelestia.adapters

Item {
    id: root

    property string source: Wallpapers.current
    property ShaderEffectSource currentCapture: capture1
    readonly property real transitionProgress: transition.progress
    // caelestia4: the same picture at another resolution (Wallpapers.displayPath: its copy fitted to the screen) is
    // swapped in without the transition: the old frame stays until the new one is ready, then it's simply there
    property var sameWallpaper: (a, b) => Wallpapers.sameWallpaper(a, b)
    property string shownSource
    property bool quietSwap

    onSourceChanged: {
        quietSwap = sameWallpaper(shownSource, source);
        shownSource = source;
        transition.stop();

        if (transition.progress < 1) {
            currentCapture = currentCapture === capture1 ? capture2 : capture1;
            currentCapture.sourceItem = transition;
        } else {
            currentCapture.sourceItem = live;
        }

        currentCapture.visible = true;
        currentCapture.scheduleUpdate();
    }

    Component.onCompleted: {
        shownSource = source;
        live.source = source;
    }

    // the old frame is frozen in `capture`: it becomes the transition's first frame, and the shader for this change is
    // picked now (the animation-speed scale is this screen's, so the time is worked out here)
    function captured(capture: ShaderEffectSource): void {
        capture.visible = false;
        transition.from = capture;
        // a quiet swap (the same picture, fitted) shows no transition: no pick, so a random one isn't used up on it
        const s = root.quietSwap ? WallTransition.chosenFor(Config.background) : WallTransition.pick(Config.background, root);
        transition.prepare(s, s.duration * Tokens.anim.durations.scale);
        live.source = root.source;
        if (live.ready)
            root.finishTransition();
    }

    function finishTransition(): void {
        if (quietSwap)
            transition.jumpToEnd();
        else
            transition.start();
    }

    ShaderEffectSource {
        id: capture1

        anchors.fill: parent
        live: false
        visible: false

        onScheduledUpdateCompleted: root.captured(this)
    }

    ShaderEffectSource {
        id: capture2

        anchors.fill: parent
        live: false
        visible: false

        onScheduledUpdateCompleted: root.captured(this)
    }

    Visual {
        id: live

        anchors.fill: parent
        playing: false // caelestia4: videos are mpvpaper's (see top)
        animate: false
        layer.enabled: true

        onReadyChanged: {
            if (ready && source === root.source)
                root.finishTransition();
        }
    }

    TransitionPlayer {
        id: transition

        anchors.fill: parent
        to: live
    }
}
