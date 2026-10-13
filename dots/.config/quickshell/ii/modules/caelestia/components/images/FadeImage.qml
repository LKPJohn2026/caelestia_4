import QtQuick
import Quickshell
import qs.modules.caelestia.components

Image {
    id: root

    property bool hadPrevious
    property bool fadingOut
    property bool preventInit
    property int fadeOutAnim: Anim.FastEffects
    property int fadeInAnim: Anim.DefaultEffects
    property int fadeInLargeAnim: Anim.StandardLarge

    function maybeStartInAnim(): void {
        if (!preventInit && !opacityInAnim.running && status === Image.Ready) {
            opacityInAnim.type = hadPrevious ? fadeInAnim : fadeInLargeAnim;
            opacityInAnim.start();
        }
    }

    asynchronous: true
    fillMode: Image.PreserveAspectCrop

    sourceSize: Qt.size(width, height) // caelestia4: Qt applies the devicePixelRatio itself

    retainWhileLoading: true
    opacity: 0

    onStatusChanged: maybeStartInAnim()
    onPreventInitChanged: maybeStartInAnim()

    Anim on opacity {
        id: opacityInAnim

        running: false
        to: 1
    }

    Behavior on source {
        SequentialAnimation {
            ScriptAction {
                script: opacityInAnim.stop()
            }
            PropertyAction {
                target: root
                property: "fadingOut"
                value: true
            }
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: root.fadeOutAnim
            }
            PropertyAction {
                target: root
                property: "fadingOut"
                value: false
            }
            PropertyAction {
                target: root
                property: "hadPrevious"
                value: root.source
            }
            PropertyAction {}
            ScriptAction {
                script: root.maybeStartInAnim()
            }
        }
    }
}
