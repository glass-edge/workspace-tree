property var input: null
property var store: []
signal command(var data)

readonly property real _rem: API.Theme.rem

function init() {
    for (let i = 0; i < itemRepeater.count; i++) {
        itemRepeater.itemAt(i).init()
    }
}

function run(verb, url, body, parameters) {
    let bodyText = body != null ? JSON.stringify(body) : undefined
    for (const param in parameters) {
        const re = new RegExp(`{${param}}`, 'g')
        url = url.replace(re, parameters[param])
        if (bodyText != null) {
            bodyText = bodyText.replace(re, parameters[param])
        }
    }
    root.command({ run: { verb, url: encodeURI(url), body: bodyText } })
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
                id: itemRepeater
                model: JSON.parse(input)
                delegate: Item {
                    id: itemRoot
                    Layout.fillWidth: true
                    implicitHeight: column.implicitHeight + (modelData.parameters ? _rem : 0)

                    property string verb: modelData.verb ?? 'GET'
                    property string url: modelData.url
                    property var body: modelData.body
                    property var parameters: {}

                    function init() {
                        const res = {}
                        if (modelData.parameters != null) {
                            for (let param of modelData.parameters) {
                                const val = root.store != null && root.store[index] != null
                                    ? root.store[index][param.id] : null
                                res[param.id] = val ?? ''
                            }
                        }
                        parameters = res
                    }

                    function setParam(paramId, text) {
                        parameters[paramId] = text
                        if (root.store == null)
                            root.store = []
                        root.store[index] = parameters
                        root.store = root.store
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
                                onClicked: {
                                    root.run(
                                        itemRoot.verb,
                                        itemRoot.url,
                                        itemRoot.body,
                                        itemRoot.parameters
                                    )
                                }
                            }
                            API.Text {
                                text: itemRoot.verb
                                font.bold: true
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
                            Layout.leftMargin: _rem * 0.5
                            Repeater {
                                model: modelData.parameters
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    API.Text {
                                        text: modelData.id
                                    }
                                    API.TextInput {
                                        Layout.fillWidth: true
                                        text: itemRoot.parameters ? itemRoot.parameters[modelData.id] : ''
                                        onEditingFinished: {
                                            itemRoot.setParam(modelData.id, text)
                                        }
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
