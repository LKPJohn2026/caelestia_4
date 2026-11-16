pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

// caelestia4: the text field the P5 rows use (PathRow, ColourRow, TimeRangeRow, the list editor), saving as
// TextFieldRow does: shows `savedText`; Enter or focus loss emits commit(text) when the text changed and passes
// `validate` (else it turns red and nothing is emitted); Esc puts the saved text back. The owner writes the value and
// calls settle() (shows the saved value again, with a ✓ for 1.5 s), or fail() to keep the text and show the error.
// No saving on every keystroke. Also draws the outline over the empty floating-label notch, as TextFieldRow does
StyledTextField {
    id: root

    property string savedText
    // Shown inside the empty field only (as TextFieldRow's placeholderText)
    property string hint
    // Emit commit() for a pending edit when the field goes away (a page closed while typing)
    property bool commitOnDestruction: true

    signal commit(text: string)

    function settle(): void {
        root.text = Qt.binding(() => root.savedText);
        root.isError = false;
        savedTimer.restart();
    }

    function fail(): void {
        root.isError = true;
    }

    function revert(): void {
        root.text = Qt.binding(() => root.savedText);
        root.isError = false;
    }

    function _finish(): void {
        if (root.text === root.savedText) {
            root.isError = false;
            return;
        }
        if (!root.valid) {
            root.isError = true;
            return;
        }
        root.commit(root.text);
    }

    text: savedText
    placeholderText: text || activeFocus ? "" : hint
    verticalPadding: Tokens.padding.small
    trailingIcon: savedTimer.running ? "check" : ""
    opacity: enabled ? 1 : 0.5

    onEditingFinished: _finish()
    // A long value (a path) shows from its start while the field isn't being edited
    onActiveFocusChanged: if (!activeFocus) cursorPosition = 0
    onTextChanged: if (!activeFocus) cursorPosition = 0

    Keys.onEscapePressed: event => {
        if (root.text !== root.savedText)
            root.revert();
        else
            event.accepted = false;
    }

    Component.onDestruction: {
        if (!root.commitOnDestruction || root.text === root.savedText || !root.valid)
            return;
        try {
            root.commit(root.text);
        } catch (e) {}
    }

    Timer {
        id: savedTimer

        interval: 1500
    }

    // The outline leaves a gap at its top left for a floating label; the rows have their own label, so the gap is an
    // empty notch: draw the border's line over it while it is open (TextFieldRow does the same)
    Shape {
        anchors.fill: parent
        z: 1
        visible: root.activeFocus || root.text.length > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: notchLine

            readonly property real inset: strokeWidth / 2
            readonly property real gapStart: inset + root.horizontalPadding - root.clampedRadius

            strokeWidth: root.activeFocus ? 2 : 1
            strokeColor: root.isError ? Colours.palette.m3error : (root.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline)
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            startX: notchLine.gapStart - 0.5
            startY: notchLine.inset - 0.5

            PathLine {
                x: notchLine.gapStart + root.Tokens.spacing.extraSmall * 2 + 0.5
                y: notchLine.inset - 0.5
            }
        }
    }
}
