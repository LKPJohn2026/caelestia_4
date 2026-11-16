pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: the lines under a Nexus row's description: why it is disabled ("Turn on “X” first", a link to X), and
// when a change applies (a small tonal chip: "Applies at next lock"). Rows put it below their subtext; it stays at full
// opacity while the row's own content is dimmed
Column {
    id: root

    property RowSetting link

    visible: !!link && (link.blocked || link.appliesText.length > 0)
    spacing: Tokens.spacing.extraSmall
    topPadding: Tokens.spacing.extraSmall

    StyledText {
        id: reason

        width: parent.width
        visible: root.link?.blocked ?? false
        text: (root.link?.disabledReason ?? "") + "  ›"
        color: Colours.palette.m3primary
        font.family: Tokens.font.label.small.family
        font.pointSize: Tokens.font.label.small.pointSize
        font.weight: Tokens.font.label.small.weight
        font.underline: reasonHover.hovered
        wrapMode: Text.WordWrap

        Accessible.role: Accessible.Link
        Accessible.name: root.link?.disabledReason ?? ""
        Accessible.onPressAction: root.link.followReason()

        HoverHandler {
            id: reasonHover

            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: root.link.followReason()
        }
    }

    StyledRect {
        visible: (root.link?.appliesText ?? "").length > 0
        implicitWidth: chipText.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: chipText.implicitHeight + Tokens.padding.extraSmall * 2
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondaryContainer

        StyledText {
            id: chipText

            anchors.centerIn: parent
            text: root.link?.appliesText ?? ""
            color: Colours.palette.m3onSecondaryContainer
            font: Tokens.font.label.small
        }
    }
}
