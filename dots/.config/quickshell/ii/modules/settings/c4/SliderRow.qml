import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: continuous setting (scales, opacity, sensitivity) with the current value shown next to the slider.
// format(value) -> label text; default: up to 2 decimals.
SettingRow {
    id: root

    property real value
    property real from: 0
    property real to: 1
    property real stepSize: 0.05
    property var format: v => (Math.round(v * 100) / 100).toString()
    signal moved(real value)

    RowLayout {
        spacing: 10

        StyledSlider {
            id: slider

            implicitWidth: 220
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            onMoved: root.moved(value)
        }

        StyledText {
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignRight
            text: root.format(slider.value)
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.m3colors.m3onSurfaceVariant
        }
    }
}
