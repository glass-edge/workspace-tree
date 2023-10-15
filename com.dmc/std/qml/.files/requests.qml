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
        res = res
            .filter((_, index) =>
                !_filterPin
                || _filterPin && store[index] != null && store[index].state?.pinned === true
            )
            .filter(v =>
                v.name.toLowerCase().includes(part)
                || v.url.toLowerCase().includes(part)
            )
    }
    return res
}

property bool _filterPin: false

function init() {
    if (typeof store == 'string') {
        store = JSON.parse(store)
    }
    for (let i = 0; i < itemRepeater.count; i++) {
        itemRepeater.itemAtIndex(i).init()
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

RowLayout {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: _rem * 0.5
    anchors.topMargin: _rem
    spacing: _rem * 0.5
    API.Text {
        Layout.minimumWidth: _rem
        horizontalAlignment: Qt.AlignHCenter
        font.family: API.Theme.fontFamilySymbol
        text: API.Theme.symbolPin
        color: _filterPin ? '#000' : '#ccc'

        MouseArea {
            anchors.fill: parent
            anchors.margins: -_rem * 0.25
            cursorShape: Qt.PointingHandCursor
            onClicked: _filterPin = !_filterPin
        }
    }
    API.TextInput {
        id: searchText
        Layout.fillWidth: true
        icon: API.Theme.symbolSearch
    }
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

    ListView {
        id: itemRepeater
        reuseItems: true
        width: scrollView.width - (height < scrollView.height ? 0 : _rem * 0.5)
        spacing: _rem * 0.5
        model: root._filteredItems
        delegate: Item {
            id: itemRoot
            width: itemRepeater.width
            implicitHeight: column.implicitHeight + _rem

            readonly property string name: modelData.name ?? ''
            readonly property string verb: modelData.verb ?? 'GET'
            readonly property string url: modelData.url ?? ''
            readonly property var body: modelData.body
            readonly property var headers: modelData.headers
            readonly property int itemIndex: modelData.index
            property var parameters: {}
            property var instances: []
            property bool pinned: false

            Component.onCompleted: init()
            ListView.onReused: init()

            function init() {
                const res = {}
                const storeItem = root.store ? root.store[itemIndex] : null
                if (modelData.parameters != null) {
                    for (let param of modelData.parameters) {
                        const val = storeItem != null && storeItem.parameters != null
                            ? storeItem.parameters[param.id] : null
                        res[param.id] = val ?? ''
                    }
                }
                parameters = res
                instances = storeItem?.instances ?? []
                pinned = storeItem?.state?.pinned === true
            }

            function setParam(paramId, text) {
                parameters[paramId] = text
                if (root.store == null)
                    root.store = []
                pushStore()
            }

            function addInstance() {
                instances.push(Object.assign({}, parameters))
                instances = instances
                pushStore()
            }

            function removeInstance(i) {
                instances.splice(i, 1)
                instances = instances
                pushStore()
            }

            function setInstanceComment(i, text) {
                instances[i]._comment = (text.length > 0 ? text : undefined)
                pushStore()
            }

            function togglePin() {
                pinned = !pinned
                pushStore()
            }

            function pushStore() {
                root.store[itemIndex] = {
                    parameters,
                    instances: instances.length > 0 ? instances : undefined,
                    state: { pinned }
                }
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
                    spacing: _rem * 0.5
                    API.Text {
                        Layout.minimumWidth: _rem
                        horizontalAlignment: Qt.AlignHCenter
                        font.family: API.Theme.fontFamilySymbol
                        text: API.Theme.symbolPin
                        color: itemRoot.pinned ? '#000' : '#ccc'
                        opacity: itemRoot.pinned || pinMouseArea.containsMouse ? 1 : 0

                        MouseArea {
                            id: pinMouseArea
                            anchors.fill: parent
                            anchors.margins: -_rem * 0.25
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: itemRoot.togglePin()
                        }
                    }
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
                        text: itemRoot.url
                        color: '#444'
                        elide: Text.ElideRight
                    }
                    API.Button {
                        implicitWidth: height
                        font.family: API.Theme.fontFamilySymbol
                        text: API.Theme.symbolAdd
                        onClicked: itemRoot.addInstance()
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: _rem * 0.5
                    visible: parametersRepeater.count > 0
                    Repeater {
                        id: parametersRepeater
                        model: modelData.parameters
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            API.Text {
                                text: modelData.id
                            }
                            API.TextInput {
                                visible: modelData.type == null
                                Layout.fillWidth: true
                                text: itemRoot.parameters ? itemRoot.parameters[modelData.id] : ''
                                onEditingFinished: {
                                    itemRoot.setParam(modelData.id, text)
                                }
                            }
                            API.TextArea {
                                id: textArea
                                visible: modelData.type === 'multiline'
                                Layout.fillWidth: true
                                implicitHeight: _rem * 10
                                value: itemRoot.parameters ? itemRoot.parameters[modelData.id] : ''
                                onTextEdited: function(text) {
                                    itemRoot.setParam(modelData.id, text)
                                }
                                backgroundComponent: Rectangle {
                                    border.width: 1
                                    border.color: textArea.paletteColors.border
                                    color: textArea.paletteColors.fill
                                    radius: API.Theme.radiusControl
                                }
                            }
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: _rem * 4
                    visible: instancesRepeater.count > 0
                    Repeater {
                        id: instancesRepeater
                        model: itemRoot.instances
                        delegate: RowLayout {
                            spacing: _rem
                            API.Button {
                                implicitWidth: height
                                font.family: API.Theme.fontFamilySymbol
                                text: API.Theme.symbolPlay
                                onClicked: {
                                    root.run(
                                        itemRoot.verb,
                                        itemRoot.url,
                                        itemRoot.body,
                                        itemRoot.headers,
                                        modelData
                                    )
                                }
                            }
                            API.TextInput {
                                Layout.fillWidth: true
                                backgroundComponent: null
                                paletteColors: ({
                                    fill: 'transparent',
                                    border: 'transparent',
                                    text: '#000',
                                    selection: '#333',
                                    selectionText: '#fff'
                                })
                                text: {
                                    if (modelData._comment != null && modelData._comment.length > 0) {
                                        return modelData._comment
                                    }
                                    let res = ''
                                    for (const k in modelData) {
                                        if (!k.startsWith('_')) {
                                            res += `${k}: ${modelData[k]}; `
                                        }
                                    }
                                    return res
                                }
                                font.pixelSize: API.Theme.fontSizeSmall
                                onEditingFinished: {
                                    itemRoot.setInstanceComment(index, text)
                                }
                            }
                            API.Button {
                                implicitWidth: height
                                font.family: API.Theme.fontFamilySymbol
                                text: API.Theme.symbolRemove
                                onClicked: itemRoot.removeInstance(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
