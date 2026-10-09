pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep

// caelestia4: end-4's region tools (modules/ii/regionSelector/RegionSelector.qml) with the Caelestia-styled
// RegionSelection. Same IPC target ("region") and global shortcuts (regionScreenshot/Search/Ocr/Record/RecordWithSound).
Scope {
    id: root

    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners

    function dismiss(): void {
        GlobalStates.regionSelectorOpen = false;
    }

    function open(action: var, mode: var): void {
        root.action = action;
        root.selectionMode = mode;
        GlobalStates.regionSelectorOpen = true;
    }

    function screenshot(): void {
        open(RegionSelection.SnipAction.Copy, RegionSelection.SelectionMode.RectCorners);
    }

    function search(): void {
        open(RegionSelection.SnipAction.Search, E4C.Config.options.search.imageSearch.useCircleSelection ? RegionSelection.SelectionMode.Circle : RegionSelection.SelectionMode.RectCorners);
    }

    function ocr(): void {
        open(RegionSelection.SnipAction.CharRecognition, RegionSelection.SelectionMode.RectCorners);
    }

    function record(sound: bool): void {
        // Already open: re-trigger, so the selection's recording check runs again (stops a running recording)
        if (GlobalStates.regionSelectorOpen)
            GlobalStates.regionSelectorOpen = false;
        open(sound ? RegionSelection.SnipAction.RecordWithSound : RegionSelection.SnipAction.Record, RegionSelection.SelectionMode.RectCorners);
    }

    Variants {
        model: Quickshell.screens

        delegate: Loader {
            id: loader

            required property var modelData

            active: GlobalStates.regionSelectorOpen

            sourceComponent: RegionSelection {
                screen: loader.modelData
                action: root.action
                selectionMode: root.selectionMode
                onDismiss: root.dismiss()
                onActionPicked: a => root.action = a
                onSelectionModePicked: m => root.selectionMode = m
            }
        }
    }

    IpcHandler {
        target: "region"

        function screenshot(): void {
            root.screenshot();
        }
        function search(): void {
            root.search();
        }
        function ocr(): void {
            root.ocr();
        }
        function record(): void {
            root.record(false);
        }
        function recordWithSound(): void {
            root.record(true);
        }
    }

    GlobalShortcut {
        name: "regionScreenshot"
        description: "Takes a screenshot of the selected region"
        onPressed: root.screenshot()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: root.search()
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: root.ocr()
    }
    GlobalShortcut {
        name: "regionRecord"
        description: "Records the selected region"
        onPressed: root.record(false)
    }
    GlobalShortcut {
        name: "regionRecordWithSound"
        description: "Records the selected region with sound"
        onPressed: root.record(true)
    }
}
