property var input: null
property var store: []
signal command(var data)

readonly property real _rem: API.Theme.rem
readonly property var _palette: {
    'GET': { text: 'darkGreen', background: '#efe' },
    'POST': { text: 'darkBlue', background: '#eef' },
    'PUT': { text: 'darkBlue', background: '#eef' },
    'DELETE': { text: 'darkRed', background: '#fee' },
}
readonly property var _items: input == null ? [] :
    JSON.parse(input).map((v, index) => {
        const res = Object.assign({}, v)
        res.index = index
        return res
    })
readonly property var _filteredItems: {
    const filter = searchText.text.toLowerCase()
    let res = _items
    for (const part of filter.split(' ')) {
        res = res.filter(v => v.name.toLowerCase().includes(part)
            || v.url.toLowerCase().includes(part))
    }
    return res
}

function init() {
    for (let i = 0; i < itemRepeater.count; i++) {
        itemRepeater.itemAt(i).init()
    }
}

function run(verb, url, body, headers, parameters) {
    let bodyText = undefined
    if (typeof body === 'string') {
        bodyText = body
    } else if (body != null) {
        bodyText = JSON.stringify(body)
    }
    const resolvedHeaders = headers ? Object.assign({}, headers) : undefined

    for (const param in parameters) {
        const re = new RegExp(`{${param}}`, 'g')
        const val = parameters[param]

        url = url.replace(re, val)
        if (bodyText != null) {
            bodyText = bodyText.replace(re, val)
        }
        if (resolvedHeaders != null) {
            for (const k in resolvedHeaders) {
                resolvedHeaders[k] = resolvedHeaders[k].replace(re, val)
            }
        }
    }
    root.command({
        run: {
            verb,
            url: encodeURI(url),
            body: bodyText,
            headers: resolvedHeaders
        }
    })
}

Rectangle {
    anchors.fill: parent
    color: 'white'
}

API.TextInput {
    id: searchText
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: _rem * 0.5
    anchors.topMargin: _rem
    icon: API.Theme.symbolSearch
}

API.ScrollView {
    id: scrollView
    clip: true
    anchors.fill: parent
    anchors.topMargin: _rem * 4
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
            spacing: _rem * 0.5
            Repeater {
                id: itemRepeater
                model: root._filteredItems
                delegate: Item {
                    id: itemRoot
                    Layout.fillWidth: true
                    implicitHeight: column.implicitHeight + (modelData.parameters ? _rem : 0)

                    readonly property string verb: modelData.verb ?? 'GET'
                    readonly property string url: modelData.url
                    readonly property var body: modelData.body
                    readonly property var headers: modelData.headers
                    readonly property int itemIndex: modelData.index
                    property var parameters: {}

                    Component.onCompleted: init()

                    function init() {
                        const res = {}
                        if (modelData.parameters != null) {
                            for (let param of modelData.parameters) {
                                const val = root.store != null && root.store[itemIndex] != null
                                    ? root.store[itemIndex][param.id] : null
                                res[param.id] = val ?? ''
                            }
                        }
                        parameters = res
                    }

                    function setParam(paramId, text) {
                        parameters[paramId] = text
                        if (root.store == null)
                            root.store = []
                        root.store[itemIndex] = parameters
                        root.store = root.store
                    }

                    Rectangle {
                        anchors.fill: parent
                        border.width: 1
                        border.color: '#20000000'
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
                                        itemRoot.headers,
                                        itemRoot.parameters
                                    )
                                }
                            }
                            API.TextTag {
                                text: itemRoot.verb
                                font.pixelSize: API.Theme.fontSizeSmall
                                borderWidth: 0.5
                                borderColor: API.Theme.alpha(color, 2)
                                borderRadius: _rem * 0.25
                                color: root._palette[text].text
                                backgroundColor: root._palette[text].background
                            }
                            API.Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Qt.AlignRight
                                font.pixelSize: API.Theme.fontSizeSmall
                                text: modelData.url
                                color: '#444'
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
