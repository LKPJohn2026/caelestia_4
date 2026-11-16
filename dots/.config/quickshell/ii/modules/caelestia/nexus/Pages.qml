import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.nexus

Item {
    id: root

    required property NexusState nState

    property int lastPageIdx
    property int animOff
    property Item currentItem
    property bool ready

    // caelestia4: the open ConfirmDialog or DialogRowButton dialog on the page, or null. A ConfirmDialog moves itself
    // onto the container while open; a DialogRowButton stays in the page tree (only its card moves). Found by their
    // API (opened/reject, open/cancel/acceptAllowed), as the dialogs don't report themselves
    function openDialog(): Item {
        const find = item => {
            if (!item)
                return null;
            if (item.opened === true && typeof item.reject === "function")
                return item;
            if (item.open === true && typeof item.cancel === "function" && "acceptAllowed" in item)
                return item;
            for (const child of item.children) {
                const found = find(child);
                if (found)
                    return found;
            }
            return null;
        };
        return find(container);
    }

    function closeDialog(dialog: Item): void {
        if (typeof dialog.reject === "function")
            dialog.reject();
        else
            dialog.cancel();
    }

    function loadPage(idx: int): void {
        if (currentItem)
            currentItem.destroy();

        const comp = PageCompRegistry.pageComps[idx] ?? PageCompRegistry.placeholderComp;
        const incubator = comp.incubateObject(container, {
            nState
        });

        const attach = () => {
            incubator.object.anchors.fill = container;
            currentItem = incubator.object;
        };

        if (incubator.status === Component.Ready)
            attach();
        else
            incubator.onStatusChanged = status => {
                if (status === Component.Ready)
                    attach();
            };
    }

    Item {
        id: container

        objectName: "PageContainer"
        anchors.fill: parent
        layer.enabled: opacity < 1
        Component.onCompleted: {
            // caelestia4: a window opened at a route starts there, without the page-switch animation
            if (root.nState.initialRoute)
                root.nState.navigate(root.nState.initialRoute);
            root.lastPageIdx = root.nState.currentPageIdx;
            root.ready = true;
            root.loadPage(root.nState.currentPageIdx);
        }
    }

    Connections {
        function onCurrentPageIdxChanged(): void {
            if (!root.ready)
                return;
            switchAnim.complete();
            root.animOff = root.Tokens.padding.extraLarge * (root.nState.currentPageIdx > root.lastPageIdx ? 1 : -1);
            switchAnim.start();
            root.lastPageIdx = root.nState.currentPageIdx;
        }

        target: root.nState
    }

    SequentialAnimation {
        id: switchAnim

        Anim {
            target: container
            property: "opacity"
            to: 0
            type: Anim.DefaultEffects
        }
        ScriptAction {
            script: root.loadPage(root.nState.currentPageIdx)
        }
        PropertyAction {
            target: container.anchors
            property: "topMargin"
            value: root.animOff
        }
        PropertyAction {
            target: container.anchors
            property: "bottomMargin"
            value: -root.animOff
        }
        ParallelAnimation {
            Anim {
                target: container
                property: "opacity"
                from: 0
                to: 1
                type: Anim.SlowEffects
            }
            Anim {
                target: container.anchors
                properties: "topMargin,bottomMargin"
                to: 0
                type: Anim.SlowEffects
            }
        }
    }
}
