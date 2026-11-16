import QtQuick
import qs.modules.caelestia.nexus.common

// caelestia4: a TextFieldRow that saves what was typed without spaces at its ends, as the page did before the
// registry ("JetBrains Mono " is saved as "JetBrains Mono"; fonts, the wallpaper folder). The entry's `validate`
// refuses those spaces, so the row's own save does nothing for such text and this saves the trimmed text instead
TextFieldRow {
    id: root

    function _trimmed(text: string): string {
        const t = text.trim();
        if (!root.link.active || t === text || !t)
            return "";
        const re = root.link.entry?.validate ? new RegExp(root.link.entry.validate) : null;
        return re && !re.test(t) ? "" : t;
    }

    // The row's own save refuses this text whichever handler runs first (the field still holds the untrimmed text),
    // so this writes now, also when the row is going away, and shows the saved value after the handlers ran
    onEditingFinished: text => {
        const t = root._trimmed(text);
        if (!t)
            return;
        if (t !== root.value)
            root.link.set(t);
        Qt.callLater(root._showSaved);
    }

    function _showSaved(): void {
        try {
            root.field.text = Qt.binding(() => root.value);
            root.field.isError = false;
        } catch (e) {}
    }
}
