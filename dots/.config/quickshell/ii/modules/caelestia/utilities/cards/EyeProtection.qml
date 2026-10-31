pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep

// caelestia4: Caelestia-styled port of end-4's "Eye protection" dialog (sidebarRight/nightLight/NightLightDialog):
// night light (now / automatic schedule / warmth), gamma and anti-flashbang. Opened by right-clicking the
// night light or anti-flashbang quick toggle.
StyledRect {
    id: root

    signal closeRequested

    readonly property var night: E4C.Config.options.light.night
    readonly property int warmest: 1200
    readonly property int coolest: 6500

    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.medium
    color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Eye protection")
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            IconButton {
                type: IconButton.Text
                icon: "close"
                onClicked: root.closeRequested()
            }
        }

        Toggle {
            label: Tr.tr("Night light")
            value: E4.Hyprsunset.temperatureActive
            onToggled: E4.Hyprsunset.toggleTemperature(checked)
        }

        Toggle {
            label: Tr.tr("Automatic schedule")
            value: root.night.automatic
            onToggled: root.night.automatic = checked
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.night.automatic
            spacing: Tokens.spacing.small

            StyledText {
                text: Tr.tr("From")
                color: Colours.palette.m3onSurfaceVariant
            }
            TimeField {
                text: root.night.from
                onTimeSet: value => root.night.from = value
            }
            StyledText {
                text: Tr.tr("to")
                color: Colours.palette.m3onSurfaceVariant
            }
            TimeField {
                text: root.night.to
                onTimeSet: value => root.night.to = value
            }
            Item {
                Layout.fillWidth: true
            }
        }

        LabeledSlider {
            label: Tr.tr("Warmth (%1K)").arg(root.night.colorTemperature)
            // 0 = coolest (6500K) … 1 = warmest (1200K)
            value: (root.coolest - root.night.colorTemperature) / (root.coolest - root.warmest)
            onMoved: v => root.night.colorTemperature = Math.round(root.coolest - v * (root.coolest - root.warmest))
        }

        LabeledSlider {
            label: Tr.tr("Gamma (%1%)").arg(E4.Hyprsunset.gamma)
            from: E4.Hyprsunset.gammaLowerLimit / 100
            value: E4.Hyprsunset.gamma / 100
            onMoved: v => E4.Hyprsunset.setGamma(Math.round(v * 100))
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.small
            text: Tr.tr("Anti-flashbang")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        Toggle {
            label: Tr.tr("Dim bright content (screen shader)")
            value: E4.HyprlandAntiFlashbangShader.enabled
            onToggled: checked ? E4.HyprlandAntiFlashbangShader.enable() : E4.HyprlandAntiFlashbangShader.disable()
        }

        Toggle {
            label: Tr.tr("Adapt display brightness")
            value: E4C.Config.options.light.antiFlashbang.enable
            onToggled: E4C.Config.options.light.antiFlashbang.enable = checked
        }
    }

    component Toggle: RowLayout {
        id: toggleRow

        required property string label
        property alias checked: sw.checked
        property alias value: sw.value // bind this (StyledSwitch)

        signal toggled

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: toggleRow.label
        }

        StyledSwitch {
            id: sw

            onToggled: toggleRow.toggled()
        }
    }

    component LabeledSlider: ColumnLayout {
        id: sliderRow

        required property string label
        property real from: 0
        property real value

        signal moved(v: real)

        Layout.fillWidth: true
        spacing: 0

        StyledText {
            text: sliderRow.label
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        StyledSlider {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 3
            from: sliderRow.from
            to: 1
            value: sliderRow.value
            onInteraction: v => sliderRow.moved(v)
        }
    }

    component TimeField: StyledTextField {
        id: field

        signal timeSet(value: string)

        Layout.preferredWidth: 90
        verticalPadding: Tokens.padding.small
        horizontalAlignment: TextInput.AlignHCenter
        validator: RegularExpressionValidator {
            regularExpression: /^([01]\d|2[0-3]):[0-5]\d$/
        }
        onEditingFinished: {
            if (acceptableInput)
                field.timeSet(text);
        }
    }
}
