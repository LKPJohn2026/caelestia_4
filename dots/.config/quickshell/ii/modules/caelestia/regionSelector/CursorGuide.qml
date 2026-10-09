import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: chip at the cursor showing the current action (end-4's CursorGuide, Caelestia style). The
// description shows for a second after the action changes, then the chip shrinks to its icon.
Item {
    id: root

    property var action

    readonly property string description: {
        switch (root.action) {
        case RegionSelection.SnipAction.Copy:
        case RegionSelection.SnipAction.Edit:
            return Tr.tr("Copy (left click) or annotate (right click)");
        case RegionSelection.SnipAction.Search:
            return Tr.tr("Search with Google Lens");
        case RegionSelection.SnipAction.CharRecognition:
            return Tr.tr("Recognize text");
        case RegionSelection.SnipAction.Record:
            return Tr.tr("Record region");
        case RegionSelection.SnipAction.RecordWithSound:
            return Tr.tr("Record region with sound");
        }
        return "";
    }
    readonly property string icon: {
        switch (root.action) {
        case RegionSelection.SnipAction.Copy:
        case RegionSelection.SnipAction.Edit:
            return "screenshot_region";
        case RegionSelection.SnipAction.Search:
            return "image_search";
        case RegionSelection.SnipAction.CharRecognition:
            return "document_scanner";
        case RegionSelection.SnipAction.Record:
        case RegionSelection.SnipAction.RecordWithSound:
            return "videocam";
        }
        return "";
    }

    property bool showDescription: true

    onActionChanged: {
        showDescription = true;
        descTimeout.restart();
    }

    implicitWidth: chip.implicitWidth + Tokens.padding.medium
    implicitHeight: chip.implicitHeight + Tokens.padding.medium

    Timer {
        id: descTimeout

        interval: 1200
        running: true
        onTriggered: root.showDescription = false
    }

    StyledRect {
        id: chip

        x: Tokens.padding.medium
        y: Tokens.padding.medium
        implicitHeight: 36
        implicitWidth: root.showDescription ? row.implicitWidth + Tokens.padding.medium * 2 : implicitHeight
        clip: true
        topLeftRadius: Tokens.rounding.extraSmall
        topRightRadius: implicitHeight / 2
        bottomLeftRadius: implicitHeight / 2
        bottomRightRadius: implicitHeight / 2
        color: Colours.palette.m3primary

        Behavior on implicitWidth {
            Anim {
                type: Anim.DefaultSpatial
            }
        }

        RowLayout {
            id: row

            anchors.verticalCenter: parent.verticalCenter
            x: (chip.implicitHeight - icon.implicitWidth) / 2
            spacing: Tokens.spacing.medium

            MaterialIcon {
                id: icon

                text: root.icon
                fill: 1
                color: Colours.palette.m3onPrimary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                opacity: root.showDescription ? 1 : 0
                text: root.description
                color: Colours.palette.m3onPrimary
                font: Tokens.font.body.small

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
            }
        }
    }
}
