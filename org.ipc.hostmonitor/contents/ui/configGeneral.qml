import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_hostsData
    property string cfg_hostsDataDefault
    property alias cfg_pollInterval: pollIntervalSpinBox.value
    property int cfg_pollIntervalDefault

    ListModel { id: hostsModel }

    property bool _saving: false

    Component.onCompleted: loadHosts()
    onCfg_hostsDataChanged: if (!_saving) loadHosts()

    function loadHosts() {
        hostsModel.clear()
        try {
            var arr = JSON.parse(cfg_hostsData)
            for (var i = 0; i < arr.length; i++)
                hostsModel.append(arr[i])
        } catch (e) {}
    }

    function saveHosts() {
        var arr = []
        for (var i = 0; i < hostsModel.count; i++) {
            var h = hostsModel.get(i)
            arr.push({ name: h.name, ip: h.ip, mac: h.mac })
        }
        _saving = true
        cfg_hostsData = JSON.stringify(arr)
        _saving = false
    }

    Kirigami.FormLayout {

        Controls.SpinBox {
            id: pollIntervalSpinBox
            Kirigami.FormData.label: "Intervalle de vérification (secondes) :"
            from: 3
            to: 3600
        }

        Controls.Label {
            Kirigami.FormData.isSection: true
            text: "Hôtes surveillés"
        }

        Repeater {
            model: hostsModel

            delegate: ColumnLayout {

                Controls.TextField {
                    Kirigami.FormData.label: "Nom :"
                    Layout.fillWidth: true
                    placeholderText: "Ex: NAS"
                    text: model.name
                    onTextEdited: {
                        hostsModel.setProperty(index, "name", text)
                        saveHosts()
                    }
                }

                Controls.TextField {
                    Kirigami.FormData.label: "IP :"
                    Layout.fillWidth: true
                    placeholderText: "Ex: 192.168.1.10"
                    text: model.ip
                    onTextEdited: {
                        hostsModel.setProperty(index, "ip", text)
                        saveHosts()
                    }
                }

                Controls.TextField {
                    Kirigami.FormData.label: "MAC :"
                    Layout.fillWidth: true
                    placeholderText: "Ex: AA:BB:CC:DD:EE:FF (vide = pas de WoL)"
                    text: model.mac
                    onTextEdited: {
                        hostsModel.setProperty(index, "mac", text)
                        saveHosts()
                    }
                }

                Controls.Button {
                    text: "Supprimer cet hôte"
                    icon.name: "edit-delete"
                    onClicked: {
                        hostsModel.remove(index)
                        saveHosts()
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: index < hostsModel.count - 1
                }
            }
        }

        Controls.Button {
            text: "Ajouter un hôte"
            icon.name: "list-add"
            onClicked: {
                hostsModel.append({ name: "", ip: "", mac: "" })
                saveHosts()
            }
        }
    }  // Kirigami.FormLayout
}
