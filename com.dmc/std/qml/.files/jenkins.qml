property var input: null
signal command(var data)

property var selectedJob: null
property var selectedBuild: null
property var selectedBuildUrl: null
property var selectedBuildActions: null

readonly property real baseWidth: 260
readonly property real baseHeight: 200

function resultToColor (result) {
    switch (result) {
        case "SUCCESS": return "#8e8"
        case "FAILURE": return "#e88"
        case "ABORTED": return "#ddd"
    }
    return "white"
}

function msToDuration (ms) {
    const s = Math.floor(ms / 1000)
    if (s < 120)
        return `${s} sec`
    const m = Math.floor(s / 60)
    if (m < 60)
        return `${m} min`
    const h = Math.floor(m /60)
    return `${h}h ${m % 60}min`
}

function timestampToDate (timestamp) {
    return new Date(timestamp).toLocaleString()
}

function getStages (actions) {
    const nodes = actions.find(v => v.nodes != null)?.nodes
    if (nodes == null) {
        return null
    }
    const stages = []
    for (let i = 0; i < nodes.length; i++) {
        if (nodes[i].displayName !== "Stage : Start")
            continue
        i++
        const stage = {
            displayName: nodes[i].displayName,
            url: null,
            result: "SUCCESS",
            level: 0
        }
        stages.push(stage)
        for (; i < nodes.length; i++) {
            if (nodes[i].iconColor === "red") {
                stage.result = "FAILURE"
                if (!nodes[i].displayName.startsWith("Stage : ") && !nodes[i].displayName.endsWith(" : End")) {
                    stages.push({
                        displayName: nodes[i].displayName,
                        url: `execution${nodes[i].url.split("execution")[1]}log/`,
                        result: "FAILURE",
                        level: 1
                    })
                }
            }
            if (nodes[i].displayName === "Stage : End")
                break
        }
    }
    return stages
}

function openLink (url) {
    console.log('opening', url)
    command({ openLink: url })
}

Rectangle {
    anchors.fill: parent
    color: "white"
}

API.ScrollView {
    anchors.fill: parent
    anchors.margins: 4
    anchors.topMargin: 20
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    ScrollBar.horizontal.policy: contentWidth > width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff

    GridLayout {
        columns: Math.max(Math.floor(root.width / root.baseWidth) - 1,
            Math.ceil((input?.jobs?.length ?? 0) / Math.floor(root.height / (root.baseHeight + 20))))

        Repeater {
            model: input?.jobs
            delegate: Item {
                id: jobItemRoot
                Layout.maximumHeight: baseHeight
                implicitHeight: baseHeight
                implicitWidth: baseWidth + 12 + (selected ? baseWidth : 0)
                opacity: selected || selectedJob == null ? 1 : 0.5

                Behavior on implicitWidth {
                    NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }

                property bool selected: (jobName === selectedJob)
                readonly property string jobName: modelData.displayName

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 1
                    border.color: "#bbb"
                    border.width: 1
                    color: "#14000000"
                    radius: 4
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    clip: true

                    Flickable {
                        Layout.fillHeight: true
                        Layout.preferredWidth: baseWidth
                        Layout.maximumWidth: baseWidth
                        contentHeight: jobColumn.height

                        ColumnLayout {
                            id: jobColumn
                            width: parent.width
                            spacing: 2
                            RowLayout {
                                Layout.fillWidth: true
                                API.Text {
                                    Layout.leftMargin: 2
                                    font.family: API.Theme.fontFamilySymbol
                                    text: API.Theme.symbolExternalLink

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: openLink(modelData.url)
                                    }
                                }
                                API.Text {
                                    Layout.fillWidth: true
                                    text: modelData.displayName
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: true
                                    color: "#444"
                                    elide: Text.ElideRight
                                }
                            }
                            Repeater {
                                model: modelData.builds
                                delegate: Item {
                                    id: buildItemRoot
                                    Layout.fillWidth: true
                                    implicitHeight: 26
                                    opacity: selected || selectedBuild == null ? 1 : 0.33

                                    property bool selected: jobItemRoot.selected && modelData.displayName === selectedBuild

                                    Rectangle {
                                        anchors.fill: parent
                                        border.width: 1
                                        border.color: "#80888888"
                                        color: resultToColor(modelData.result)
                                    }
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        API.Text {
                                            Layout.fillHeight: true
                                            verticalAlignment: Qt.AlignVCenter
                                            text: modelData.displayName
                                            font.pixelSize: 10
                                            color: "#444"
                                        }
                                        API.Text {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            verticalAlignment: Qt.AlignVCenter
                                            font.pixelSize: 10
                                            text: timestampToDate(modelData.timestamp)
                                            color: "#666"
                                        }
                                        API.Text {
                                            Layout.fillHeight: true
                                            verticalAlignment: Qt.AlignVCenter
                                            font.pixelSize: 10
                                            text: msToDuration(modelData.duration)
                                            color: "#666"
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (selectedJob === jobItemRoot.jobName && selectedBuild === modelData.displayName) {
                                                selectedJob = null
                                                selectedBuild = null
                                                selectedBuildUrl = null
                                                selectedBuildActions = null
                                            } else {
                                                selectedJob = jobItemRoot.jobName
                                                selectedBuild = modelData.displayName
                                                selectedBuildUrl = modelData.url
                                                selectedBuildActions = getStages(modelData.actions)
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
                    Flickable {
                        visible: jobItemRoot.selected
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: stagesColumn.height

                        ColumnLayout {
                            id: stagesColumn
                            width: parent.width
                            spacing: 2
                            RowLayout {
                                Layout.fillWidth: true
                                API.Text {
                                    Layout.leftMargin: 2
                                    font.family: API.Theme.fontFamilySymbol
                                    text: API.Theme.symbolExternalLink

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: openLink(selectedBuildUrl)
                                    }
                                }
                                API.Text {
                                    Layout.fillWidth: true
                                    text: selectedBuild
                                    horizontalAlignment: Qt.AlignHCenter
                                    font.bold: true
                                    color: "#444"
                                    elide: Text.ElideRight
                                }
                            }
                            Repeater {
                                model: selectedBuildActions
                                delegate: Item {
                                    id: actionItemRoot
                                    Layout.fillWidth: true
                                    Layout.leftMargin: modelData.level * 16
                                    implicitHeight: 26

                                    Rectangle {
                                        anchors.fill: parent
                                        border.width: 1
                                        border.color: "#80888888"
                                        // radius: 2
                                        color: resultToColor(modelData.result)
                                    }
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8
                                        API.Text {
                                            visible: modelData.url != null
                                            font.family: API.Theme.fontFamilySymbol
                                            text: API.Theme.symbolExternalLink

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: openLink(selectedBuildUrl + modelData.url)
                                            }
                                        }
                                        API.Text {
                                            Layout.fillWidth: true
                                            text: modelData.displayName
                                            font.pixelSize: 10
                                            color: "#444"
                                            elide: Text.ElideRight
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
            }
        }
    }
}
