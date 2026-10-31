// caelestia4: end4-pC's ToolbarPairedFab (laid out by its parent, unlike end-4's, which centres itself)
pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    signal clicked(event: var)
    property alias iconText: fabWidget.iconText
    property alias baseSize: fabWidget.baseSize
    default property alias fabData: fabWidget.data
    property bool enableShadow: true

    implicitWidth: fabWidget.implicitWidth
    implicitHeight: fabWidget.implicitHeight

    StyledRectangularShadow {
        visible: root.enableShadow
        target: fabWidget
        radius: fabWidget.buttonRadius
    }

    FloatingActionButton {
        id: fabWidget
        onClicked: e => root.clicked(e)
        baseSize: 48
        colBackground: Appearance.colors.colTertiaryContainer
        colBackgroundHover: Appearance.colors.colTertiaryContainerHover
        colRipple: Appearance.colors.colTertiaryContainerActive
        colOnBackground: Appearance.colors.colOnTertiaryContainer
    }
}