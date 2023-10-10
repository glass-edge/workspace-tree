property var input: null
signal command(var data)

readonly property real _rem: API.Theme.rem

function run(url, parameters) {
    for (const param in parameters) {
        url = url.replace(new RegExp(`{${param}}`, 'g'), parameters[param])
    }
    root.command({ run: { url: encodeURI(url) } })
}

API.ScrollView {
    id: scrollView
    anchors.fill: parent
    anchors.margins: _rem * 0.25
    barOffset: -_rem * 0.05
    barWidth: _rem * 0.25

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Flickable {
        flickableDirection: Flickable.VerticalFlick
        contentHeight: mainColumn.height

        ColumnLayout {
            id: mainColumn
            width: scrollView.width - (height < scrollView.height ? 0 : _rem * 0.5)
            Repeater {
                model: JSON.parse(input)
                delegate: Item {
                    id: itemRoot
                    Layout.fillWidth: true
                    implicitHeight: column.implicitHeight + _rem

                    property var parameters: {
                        const res = {}
                        if (modelData.parameters != null) {
                            for (let param of modelData.parameters) {
                                res[param.id] = ''
                            }
                        }
                        return res
                    }

                    Rectangle {
                        anchors.fill: parent
                        border.width: 1
                        border.color: "black"
                        radius: API.Theme.radiusControl
                    }

                    ColumnLayout {
                        id: column
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: _rem * 0.5
                        spacing: _rem
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: _rem
                            API.Button {
                                text: modelData.name
                                onClicked: root.run(modelData.url, itemRoot.parameters)
                            }
                            API.Text {
                                Layout.fillWidth: true
                                font.pixelSize: API.Theme.fontSizeSmall
                                text: modelData.url
                                color: "#444"
                                elide: Text.ElideRight
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Repeater {
                                model: modelData.parameters
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    API.Text {
                                        text: modelData.id
                                    }
                                    API.TextInput {
                                        Layout.fillWidth: true
                                        onEditingFinished: itemRoot.parameters[modelData.id] = text
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
