import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.11
import QtQuick.Dialogs 1.3

Popup {
    id: popup

    property var message
    property var visibility

    modal: true
    focus: true
    height: Math.min(mainWindow.height * 0.8, layout.implicitHeight + 32)
    width: Math.min(mainWindow.width * 0.66, 500)
    anchors.centerIn: mainWindow.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    Component.onCompleted: {
        if (message != null) {
            visibility = message.visibility
        } else {
            visibility = "public"
        }
    }

    FileDialog {
        id: imageFileDialog
        title: "Please choose an image"
        folder: shortcuts.home
        nameFilters: [ "Image files (*.jpg *.jpeg *.png *.gif)", "All files (*)" ]
        selectExisting: true
        selectMultiple: true

        onAccepted: {
            console.log("chose", imageFileDialog.fileUrls.length)

            for (var i = 0; i < imageFileDialog.fileUrls.length; i++) {
                console.log(imageFileDialog.fileUrls[i])

                busy.running = true
                var media = uiBridge.uploadAttachment(imageFileDialog.fileUrls[i])
            }
        }
        onRejected: {
            console.log("Canceled")
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentHeight: layout.height

        BusyIndicator {
            z: 1
            id: busy
            running: false
            anchors.centerIn: parent
        }

        DropArea {
            id: drop
            anchors.fill: parent
            enabled: true

            onEntered:
                console.log("entered")

            onExited:
                console.log("exited")

            onDropped: {
                console.log("dropped", drop.urls.length, "urls")

                for (var i = 0; i < drop.urls.length; i++) {
                    console.log(drop.urls[i])

                    busy.running = true
                    var media = uiBridge.uploadAttachment(drop.urls[i])
                    /*
                    if (media != '') {
                        attachments.append({"id": media, "url": drop.urls[i]})
                    }
                    */
                }
                drop.acceptProposedAction()
            }
        }

        ColumnLayout {
            id: layout
            width: parent.width

            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: item !== null ? item.implicitHeight : 0

                sourceComponent: message !== null ? messageViewComponent : null
                Component {
                    id: messageViewComponent
                    MessageView {
                        showActionButtons: false
                        message: popup.message
                    }
                }
            }

            Label {
                visible: message !== null
                text: message !== null ? qsTr("Replying to %1").arg(message.name) : ""
                opacity: 0.3
            }

            TextArea {
                id: messageArea
                Layout.fillWidth: true
                Layout.minimumHeight: 128
                focus: true
                selectByMouse: true
                placeholderText: message !== null ? qsTr("Post your reply") : qsTr("What's happening?")
                text: message !== null ? message.mentions : ""
                wrapMode: TextArea.Wrap
            }

            Connections {
                target: accountBridge.attachments
                onRowsInserted: {
                    busy.running = false
                }
                onRowsRemoved: {
                }
            }

            Flow {
                id: attachmentLayout
                Layout.fillWidth: true
                Repeater {
                    model: accountBridge.attachments
                    Image {
                        smooth: true
                        source: model.attachmentPreview
                        sourceSize.height: 64

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: function() {
                                accountBridge.attachments.removeAttachment(index)
                            }
                        }
                    }
                }
            }

            TextButton {
                text: "Attach files by dragging & dropping them."
                font.pointSize: 9
                onClicked: function() {
                    imageFileDialog.open()
                }
            }

            RowLayout {
                RoundButton {
                    id: scopePrivateButton
                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    highlighted: visibility === "direct"
                    
                    icon.name: "scope-private"
                    icon.source: "images/scope-private.svg"

                    onClicked: {
                        visibility = "direct"
                    }
                }

                RoundButton {
                    id: scopeFollowersButton
                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    highlighted: visibility === "private"
                    
                    icon.name: "scope-followers"
                    icon.source: "images/scope-followers.svg"

                    onClicked: {
                        visibility = "private"
                    }
                }

                RoundButton {
                    id: scopeUnlistedButton
                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    highlighted: visibility === "unlisted"
                    
                    icon.name: "scope-unlisted"
                    icon.source: "images/scope-unlisted.svg"

                    onClicked: {
                        visibility = "unlisted"
                    }
                }

                RoundButton {
                    id: scopePublicButton
                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    highlighted: visibility === "public"
                    
                    icon.name: "scope-public"
                    icon.source: "images/scope-public.svg"

                    onClicked: {
                        visibility = "public"
                    }
                }

                Item {
                    // fills all the empty space so the following items align right
                    Layout.fillWidth: true
                }

                Label {
                    id: remCharsLabel

                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    font.pointSize: 12
                    text: accountBridge.postSizeLimit - uiBridge.postLimitCount(messageArea.text)
                }

                Button {
                    id: sendButton
                    enabled: remCharsLabel.text >= 0 && messageArea.text.length > 0
                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    highlighted: true
                    text: message != null ? qsTr("Reply") : qsTr("Post")

                    onClicked: {
                        popup.close()
                        var msg = messageArea.text
                        var msgid = ""

                        if (message != null) {
                            msgid = message.messageid
                            msg = "@" + message.author + " " + msg
                        }

                        uiBridge.postButton(msgid, msg, visibility)
                        messageArea.clear()
                    }
                }                
            }
        }
    }
}
