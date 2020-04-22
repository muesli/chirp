import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.11

import "componentCreator.js" as ComponentCreator

ApplicationWindow {
    id: mainWindow
    visible: true

    // flags: Qt.FramelessWindowHint
    Material.theme: settings.style == "Dark" ? Material.Dark : Material.Light
    Material.accent: Material.Purple
    background: Rectangle {
        color: Material.color(Material.Grey, Material.Shade900)
    }

    font.family: settings.fontfamily

    minimumWidth: 364
    minimumHeight: 590
    width: settings.width > 0 ? settings.width : minimumWidth * 2
    height: settings.height > 0 ? settings.height : minimumWidth * 1.75
    Binding on x {
        when: settings.positionX > 0
        value: settings.positionX
    }
    Binding on y {
        when: settings.positionY > 0
        value: settings.positionY
    }

    Component.onCompleted: {
        if (settings.firstRun) {
            connectDialog.open()
        }
    }
    onClosing: function() {
        settings.positionX = mainWindow.x
        settings.positionY = mainWindow.y
        settings.width = mainWindow.width
        settings.height = mainWindow.height
    }

    Item {
        AboutDialog {
            id: aboutDialog
            x: mainWindow.width / 2 - width / 2
            y: mainWindow.height / 2 - height / 2 - mainWindow.header.height
            width: 340
            height: 340
        }

        ConnectDialog {
            id: connectDialog
            x: mainWindow.width / 2 - width / 2
            y: mainWindow.height / 2 - height / 2 - mainWindow.header.height
            width: Math.min(460, mainWindow.width - 16)
            height: 500
        }

        SettingsDialog {
            id: settingsDialog
            x: (mainWindow.width - width) / 2
            y: mainWindow.height / 6
            width: Math.min(mainWindow.width, mainWindow.height) / 3 * 2
        }

        Popup {
            id: errorDialog
            modal: true
            focus: true
            contentHeight: errorLayout.height
            visible: accountBridge.error.length > 0
            x: mainWindow.width / 2 - width / 2
            y: mainWindow.height / 2 - height / 2 - mainWindow.header.height
            width: Math.min(mainWindow.width * 0.66, errorLayout.implicitWidth + 32)

            ColumnLayout {
                id: errorLayout
                spacing: 20
                width: parent.width

                Label {
                    text: qsTr("Error")
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Label.Wrap
                    font.pointSize: 14
                    text: accountBridge.error
                }

                Button {
                    id: okButton
                    Layout.alignment: Qt.AlignCenter
                    highlighted: true

                    text: qsTr("Close")
                    onClicked: {
                        accountBridge.error = ""
                        errorDialog.close()
                    }
                }
            }
        }
    }

    header: ToolBar {
        ToolButton {
            id: drawerButton
            contentItem: Image {
                fillMode: Image.Pad
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                source: "images/drawer.png"
            }
            onClicked: {
                drawer.open()
            }
        }

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            ImageButton {
                opacity: 1.0
                roundness: 250
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                source: accountBridge.avatar
                sourceSize.height: 32
                onClicked: function() {
                    Qt.openUrlExternally(accountBridge.profileURL)
                }
            }

            Label {
                id: titleLabel
                text: accountBridge.username
                font.pointSize: 13
                elide: Label.ElideRight
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
            }
        }

        ToolButton {
            id: postButton
            anchors.right: menuButton.left
            contentItem: Image {
                fillMode: Image.Pad
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                source: "images/post.png"
            }
            onClicked: {
                ComponentCreator.createMessagePopup(this, null).open();
            }
        }
        ToolButton {
            anchors.right: parent.right
            id: menuButton
            Layout.alignment: Qt.AlignRight
            contentItem: Image {
                fillMode: Image.Pad
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                source: "images/menu.png"
            }
            onClicked: optionsMenu.open()

            Menu {
                id: optionsMenu
                x: parent.width - width
                transformOrigin: Menu.TopRight

                MenuItem {
                    text: qsTr("Connect")
                    onTriggered: function() {
                        connectDialog.reset()
                        connectDialog.open()
                    }
                }
                /*
                MenuItem {
                    text: qsTr("Settings")
                    onTriggered: settingsDialog.open()
                }
                */
                MenuItem {
                    text: qsTr("About")
                    onTriggered: aboutDialog.open()
                }
            }
        }
    }

    Drawer {
        id: drawer
        width: drawerLayout.implicitWidth + 64
        height: mainWindow.height
        dragMargin: 0

        ColumnLayout {
            id: drawerLayout
            anchors.fill: parent

            AccountSummary {
                profile: accountBridge
            }

            TextField {
                id: search
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 8
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                leftInset: -8
                rightInset: -8
                selectByMouse: true
                placeholderText: "Search..."
                font.pointSize: 10

                color: "#cccccc"
                background: Rectangle {
                    color: "#212121"
                    border.color: "#111111"
                    border.width: 1
                    radius: 4
                }

                Keys.onReturnPressed: {
                    drawer.close()
                    uiBridge.search(search.text)
                    event.accepted = true
                }
            }

            ToolSeparator {
                Layout.fillWidth: true
                orientation: Qt.Horizontal
            }

            ListView {
                id: listView
                currentIndex: -1
                Layout.fillWidth: true
                Layout.fillHeight: true
                delegate: ItemDelegate {
                    width: parent.width
                    text: model.title
                    highlighted: ListView.isCurrentItem
                    onClicked: {
                        listView.currentIndex = -1
                        drawer.close()
                        switch (model.sid) {
                        case 0:
                            ComponentCreator.createMessagePopup(this, null).open();
                            break
                        case 1:
                            mainWindow.close()
                            break
                        }
                    }
                }
                model: ListModel {
                    ListElement {
                        title: qsTr("New Post")
                        property int sid: 0
                    }
                    ListElement {
                        title: qsTr("Exit")
                        property int sid: 1
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator {
                }
            }
        }
    }

    ScrollView {
        id: mainscroll
        anchors.fill: parent
        ScrollBar.horizontal.policy: contentWidth > width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        contentWidth: Math.max(maingrid.implicitWidth, parent.width)

        GridLayout {
            id: maingrid
            // columns: accountBridge.panes.length
            rows: 1
            anchors.fill: parent
            anchors.margins: 0
            columnSpacing: 0
            rowSpacing: 0

            Repeater {
                model: accountBridge.panes
                MessagePane {
                    Layout.row: 0
                    Layout.column: index

                    idx: index
                    name: model.panename
                    sticky: model.panesticky
                    messageModel: model.msgmodel
                }
            }
        }
    }
}
