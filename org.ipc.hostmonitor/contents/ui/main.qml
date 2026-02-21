import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.kirigami as Kirigami
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation

    property bool initialCheckDone: false

    ListModel { id: hostsModel }

    function notify(summary, body, icon) {
        executable.connectSource("notify-send -u normal -t 3000 -a 'Host Monitor' -i '" + icon + "' '" + summary + "' '" + body + "'")
        executable.connectSource("paplay /usr/share/sounds/freedesktop/stereo/bell.oga")
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            for (var i = 0; i < hostsModel.count; i++) {
                if (source === "ping -c 1 -W 2 " + hostsModel.get(i).ip) {
                    var wasAlive = hostsModel.get(i).alive
                    var wasChecking = hostsModel.get(i).checking
                    var isAlive = data["exit code"] === 0
                    hostsModel.setProperty(i, "alive", isAlive)
                    hostsModel.setProperty(i, "checking", false)

                    if (root.initialCheckDone && !wasChecking && wasAlive !== isAlive) {
                        var host = hostsModel.get(i)
                        var status = isAlive ? "en ligne ✅" : "hors ligne ❌"
                        var icon = isAlive ? "network-connect" : "network-disconnect"
                        root.notify(host.name, host.ip + " est " + status, icon)
                    }
                    break
                }
            }
            disconnectSource(source)
        }
    }

    function reloadHosts() {
        hostsModel.clear()
        try {
            var arr = JSON.parse(Plasmoid.configuration.hostsData)
            for (var i = 0; i < arr.length; i++) {
                hostsModel.append({
                    name: arr[i].name,
                    ip: arr[i].ip,
                    mac: arr[i].mac,
                    alive: false,
                    checking: true
                })
            }
        } catch (e) {}
        checkAllHosts()
    }

    function checkAllHosts() {
        for (var i = 0; i < hostsModel.count; i++) {
            hostsModel.setProperty(i, "checking", true)
            executable.connectSource("ping -c 1 -W 2 " + hostsModel.get(i).ip)
        }
        if (!initialCheckDone) {
            markInitialDoneTimer.restart()
        }
    }

    Timer {
        id: markInitialDoneTimer
        interval: 3000
        onTriggered: root.initialCheckDone = true
    }

    function sendWol(mac) {
        var scriptPath = Qt.resolvedUrl("../code/wol.py").toString().replace("file://", "")
        executable.connectSource("python3 '" + scriptPath + "' '" + mac + "'")
    }

    Component.onCompleted: reloadHosts()

    Connections {
        target: Plasmoid.configuration
        function onHostsDataChanged() { root.reloadHosts() }
    }

    Timer {
        interval: Plasmoid.configuration.pollInterval * 1000
        running: true
        repeat: true
        onTriggered: root.checkAllHosts()
    }

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * Math.max(hostsModel.count * 3, 4)

        Repeater {
            model: hostsModel

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Rectangle {
                    width: 14; height: 14; radius: 7
                    color: model.checking ? Kirigami.Theme.disabledTextColor
                         : model.alive ? Kirigami.Theme.positiveTextColor
                         : Kirigami.Theme.negativeTextColor
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: model.name + "  (" + model.ip + ")"
                    elide: Text.ElideRight
                }

                Controls.Button {
                    text: "WoL"
                    icon.name: "network-wired"
                    visible: model.mac !== ""
                    enabled: !model.alive
                    onClicked: root.sendWol(model.mac)
                }
            }
        }

        Controls.Label {
            visible: hostsModel.count === 0
            text: "Aucun hôte configuré.\nClic droit → Configurer…"
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            opacity: 0.6
        }

        Item { Layout.fillHeight: true }
    }
}
