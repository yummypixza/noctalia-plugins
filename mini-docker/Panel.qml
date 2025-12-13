import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.System
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    // SmartPanel properties
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 800 * Style.uiScaleRatio
    property real contentPreferredHeight: 550 * Style.uiScaleRatio
    property bool sidebarExpanded: false
    property int currentTabIndex: 0

    function getStatusColor(state) {
        if (state === "running")
            return "#4caf50";

        if (state === "paused")
            return "#ff9800";

        if (state === "exited")
            return "#f44336";

        return Color.mOnSurfaceVariant;
    }

    function updateContainers() {
        containerProcess.running = true;
    }

    function updateVolumes() {
        volumeProcess.running = true;
    }

    function startContainer(id) {
        runCommand(["docker", "start", id], function() {
            updateContainers();
        });
    }

    function stopContainer(id) {
        runCommand(["docker", "stop", id], function() {
            updateContainers();
        });
    }

    function runCommand(args, callback) {
        var process = Qt.createQmlObject('import Quickshell.Io; Process { }', root);
        process.command = args;
        process.exited.connect(function() {
            if (callback)
                callback();

            process.destroy();
        });
        process.running = true;
    }

    anchors.fill: parent
    Component.onCompleted: {
        updateContainers();
        updateVolumes();
    }

    Rectangle {
        id: panelContainer

        anchors.fill: parent
        color: Color.transparent

        Rectangle {
            anchors.fill: parent
            anchors.margins: Style.marginL
            color: Color.mSurface
            radius: Style.radiusL
            border.color: Color.mOutline
            border.width: Style.borderS
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.sidebarExpanded ? 200 * Style.uiScaleRatio : 56 * Style.uiScaleRatio
                    color: Color.mSurfaceVariant
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Style.marginS
                        spacing: Style.marginS

                        NButton {
                            icon: "menu-2"
                            Layout.preferredWidth: 40 * Style.uiScaleRatio
                            Layout.preferredHeight: 40 * Style.uiScaleRatio
                            Layout.alignment: Qt.AlignLeft
                            onClicked: root.sidebarExpanded = !root.sidebarExpanded
                        }

                        Item {
                            height: Style.marginS
                            width: 1
                        }

                        SidebarItem {
                            iconName: "brand-docker"
                            text: "Containers"
                            isSelected: root.currentTabIndex === 0
                            onClicked: root.currentTabIndex = 0
                        }

                        SidebarItem {
                            iconName: "database"
                            text: "Volumes"
                            isSelected: root.currentTabIndex === 1
                            onClicked: root.currentTabIndex = 1
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Color.mOutline
                        opacity: 0.5
                    }

                    Behavior on Layout.preferredWidth {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }

                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60 * Style.uiScaleRatio
                        color: Color.transparent

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Style.marginL
                            spacing: Style.marginM

                            Text {
                                text: root.currentTabIndex === 0 ? "Containers" : "Volumes"
                                font.bold: true
                                font.pixelSize: 20
                                color: Color.mOnSurface
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.currentTabIndex === 0 ? containersModel.count + " Containers" : volumesModel.count + " Volumes"
                                color: Color.mOnSurfaceVariant
                                font.pixelSize: 12
                                visible: root.contentPreferredWidth > 600
                            }

                            NButton {
                                icon: "refresh"
                                text: "Refresh"
                                onClicked: {
                                    if (root.currentTabIndex === 0)
                                        updateContainers();
                                    else
                                        updateVolumes();
                                }
                            }

                        }

                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: root.currentTabIndex

                        Item {
                            ListView {
                                id: containersList

                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: containersModel
                                delegate: containerDelegate
                                spacing: Style.marginS
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Text {
                                    anchors.centerIn: parent
                                    visible: containersModel.count === 0
                                    text: "No containers running"
                                    color: Color.mOnSurfaceVariant
                                }

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    active: containersList.moving
                                }

                            }

                        }

                        Item {
                            ListView {
                                id: volumesList

                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: volumesModel
                                delegate: volumeDelegate
                                spacing: Style.marginS
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Text {
                                    anchors.centerIn: parent
                                    visible: volumesModel.count === 0
                                    text: "No volumes found"
                                    color: Color.mOnSurfaceVariant
                                }

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    active: volumesList.moving
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    Component {
        id: containerDelegate

        Rectangle {
            width: containersList.width - (containersList.ScrollBar.vertical ? 10 : 0)
            height: 70 * Style.uiScaleRatio
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: getStatusColor(model.state)
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: model.name
                        font.bold: true
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: model.image
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                }

                NButton {
                    icon: model.state === "running" ? "player-stop" : "player-play"
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    onClicked: model.state === "running" ? stopContainer(model.id) : startContainer(model.id)
                }

            }

        }

    }

    Component {
        id: volumeDelegate

        Rectangle {
            width: volumesList.width - (volumesList.ScrollBar.vertical ? 10 : 0)
            height: 50 * Style.uiScaleRatio
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            RowLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NIcon {
                    icon: "database"
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                }

                Text {
                    text: model.name
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    color: Color.mOnSurface
                }

            }

        }

    }

    ListModel {
        id: containersModel
    }

    ListModel {
        id: volumesModel
    }

    Process {
        id: containerProcess

        command: ["docker", "ps", "-a", "--format", "json"]

        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text;
                containersModel.clear();
                var lines = output.split('\n').filter((line) => {
                    return line.trim() !== '';
                });
                lines.forEach(function(line) {
                    try {
                        var container = JSON.parse(line);
                        containersModel.append({
                            "id": container.ID,
                            "name": container.Names,
                            "image": container.Image,
                            "status": container.Status,
                            "state": container.State
                        });
                    } catch (e) {
                    }
                });
            }
        }

    }

    Process {
        id: volumeProcess

        command: ["docker", "volume", "ls", "--format", "json"]

        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text;
                volumesModel.clear();
                var lines = output.split('\n').filter((line) => {
                    return line.trim() !== '';
                });
                lines.forEach(function(line) {
                    try {
                        var volume = JSON.parse(line);
                        volumesModel.append({
                            "name": volume.Name,
                            "driver": volume.Driver
                        });
                    } catch (e) {
                    }
                });
            }
        }

    }

    Timer {
        interval: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings.refreshInterval : 5000
        running: true
        repeat: true
        onTriggered: {
            if (root.currentTabIndex === 0)
                updateContainers();
            else
                updateVolumes();
        }
    }

    component SidebarItem: Rectangle {
        id: navItem // <--- FIXED: Added ID here to prevent shadowing issues

        property string iconName
        property string text
        property bool isSelected

        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 40 * Style.uiScaleRatio
        color: isSelected ? Color.mSurface : Color.transparent
        radius: Style.radiusS

        Rectangle {
            visible: isSelected
            width: 3
            height: 16
            color: Color.mPrimary
            radius: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            spacing: 12

            NIcon {
                icon: navItem.iconName // Reference via ID
                color: Color.mOnSurface
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
            }

            Text {
                text: navItem.text // <--- FIXED: Reference via ID
                color: Color.mOnSurface
                font.weight: isSelected ? Font.DemiBold : Font.Normal
                visible: root.sidebarExpanded
                opacity: root.sidebarExpanded ? 1 : 0
                Layout.fillWidth: true
                elide: Text.ElideRight

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
            onEntered: {
                if (!parent.isSelected)
                    parent.color = Qt.rgba(1, 1, 1, 0.05);

            }
            onExited: {
                if (!parent.isSelected)
                    parent.color = Color.transparent;

            }
        }

    }

}
