pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of ServicesPage (route services/capture): end-4's screenshot and recording options, from end-4's
// Settings app (Apps & services). Rows name registry ids (registry/RegServices.qml)
PageBase {
    id: root

    title: Tr.tr("Screenshots & recording")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: "Saving", not the page title again
        SectionHeader {
            text: Tr.tr("Saving")
        }

        PathRow {
            setting: "e4:screenSnip.savePath"
            // caelestia4: what an empty field means
            hint: Tr.tr("Clipboard only")
            // caelestia4: the screenshot action makes the folder (mkdir -p), so a new one is fine
            mustExist: false
        }

        PathRow {
            setting: "e4:screenRecord.savePath"
            // caelestia4: scripts/videos/record.sh makes the folder (mkdir -p), so a new one is fine
            mustExist: false
        }

        ToggleRow {
            setting: "e4:regionSelector.annotation.useSatty"
        }

        // caelestia4: what the region selector offers to click (modules/caelestia/regionSelector)
        SectionHeader {
            text: Tr.tr("Region selector")
        }

        ToggleRow {
            setting: "e4:regionSelector.targetRegions.windows"
        }

        ToggleRow {
            setting: "e4:regionSelector.targetRegions.layers"
        }

        ToggleRow {
            setting: "e4:regionSelector.targetRegions.content"
        }

        ToggleRow {
            setting: "e4:regionSelector.rect.showAimLines"
        }

        ToggleRow {
            setting: "e4:search.imageSearch.useCircleSelection"
        }

        AdvancedSection {
            ToggleRow {
                setting: "e4:regionSelector.targetRegions.showLabel"
            }

            SliderRow {
                setting: "e4:regionSelector.targetRegions.opacity"
            }

            SliderRow {
                setting: "e4:regionSelector.targetRegions.contentRegionOpacity"
            }

            StepperRow {
                setting: "e4:regionSelector.targetRegions.selectionPadding"
            }

            StepperRow {
                setting: "e4:regionSelector.circle.strokeWidth"
            }

            StepperRow {
                setting: "e4:regionSelector.circle.padding"
            }

            TextFieldRow {
                setting: "e4:search.imageSearch.imageSearchEngineBaseUrl"
                // caelestia4: an empty address would break the Search action
                field.emptyIsValid: false
            }
        }
    }
}
