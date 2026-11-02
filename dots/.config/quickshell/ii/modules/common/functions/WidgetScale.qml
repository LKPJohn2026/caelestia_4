pragma Singleton
import Quickshell

/**
 * caelestia4: the desktop widgets (pcwidgets) are drawn larger by a Scale transform (AbstractBackgroundWidget's
 * widgetScale: a preset's 1920x1080 canvas on this screen). A transform stretches what an item draws as a texture
 * (native-rendered text, layers, images decoded at their size, a Canvas) instead of drawing it again, so on a 1.5x
 * screen those come out soft. These tell such an item how large it really ends up, to draw at that size.
 * Called from bindings: the ancestors' parent and widgetScale are read, so it follows a reparent or a new scale.
 */
Singleton {
    // Inside a widget drawn larger or smaller than its size (vector text instead of native glyphs then)
    function transformed(item): bool {
        for (let p = item; p; p = p.parent)
            if (p.widgetScale !== undefined)
                return p.widgetScale !== 1;
        return false;
    }

    // Device pixels per logical pixel of `item`: the widget's scale times the screen's devicePixelRatio. A layer's
    // textureSize or an image's sourceSize is its size times this. 0 outside a widget (the caller keeps its own)
    function renderScale(item): real {
        for (let p = item; p; p = p.parent)
            if (p.renderScale !== undefined)
                return p.renderScale;
        return 0;
    }
}
