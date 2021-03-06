import QtQuick 2.0
import QtMultimedia 5.0
import com.dfranca.tools 1.0

Rectangle {
    objectName: "taskRow"
    anchors.right: parent.right
    anchors.rightMargin: 200
    property var model: null
    property var listModel: null
    property var listView: null
    property var index: null
    property var lastUpdate: null
    property var remaining: null
    property var rowTimer: null
    property var rowPlayPause: null

    Component.onCompleted: state = "paused"

    function toSeconds(time) {
        var min = parseInt(time.substr(0,2));
        var sec = parseInt(time.substr(3,5));

        return sec + (min * 60);

    }

    function findQmlElement(root, id) {
        console.log("ROOT FOR ID: " + id + ": " + root)
        if (root.objectName === id)
            return root;
        for (var x=0; x < root.children.length; x++) {
            var elem = findQmlElement(root.children[x], id);
            if (elem)
            {
                //console.log("Element found: " + elem)
                return elem;
            }
        }

        return;
    }

    function stopAll() {

        for (var x=0; x < listView.contentItem.children.length; x++) {
            console.log("INDEX: " + x)
            var taskRow = listView.contentItem.children[x];
            var extTaskRow = findQmlElement(taskRow, "taskRow")
            console.log("FOUND: " + extTaskRow)
            if (extTaskRow) {
                extTaskRow.rowPlayPause.source = "qrc:/img/play-16.png"
                extTaskRow.rowTimer.stop()
            }

            timer.stop()
        }
    }

    function playOrPause(mouseX, mouseY) {
        if (playpause.playState === "paused") {
            playpause.source = "qrc:/img/pause-16.png"
            lastUpdate = new Date()
            stopAll();
            //model.remaining = "00:05"

            var min = parseInt(model.remaining.substr(0,2))
            var sec = parseInt(model.remaining.substr(3,5))

            remaining = new Date(null, null, null, 0, min, sec, 0);
            timer.time = (min * 60 + sec);
            timer.start();
            playpause.playState = "running";
            playpause.source = "qrc:/img/pause-16.png"

            if (mouseX && mouseY) {
                //console.log("PARENT: " + parent);
                var tasksList = findQmlElement(tabHome, "tasksList");
                tasksList.currentIndex = index;
            }
        }
        else {
            console.log("Stopping...")
            playpause.source = "qrc:/img/play-16.png"
            playpause.playState = "paused"
            timer.stop()
            var timerDisplay = findQmlElement(tabHome, "timerDisplay");
            model.remaining = timerDisplay.text;
        }
    }

    Keys.onReturnPressed: {
        console.log("On Enter pressed")
        playOrPause(null, null);
    }

    SoundEffect {
        id: soundAlarm
        source: "qrc:/media/alarm.wav"
        loops: 1
    }

    Alarm {
        id: timer
        objectName: "timer"
        //time: 1500
        //repeat: true

        Component.onCompleted: rowTimer = timer;

        function addZero(val) {
            if (val < 10) {
                val = "0" + val;
            }

            return val;
        }

        onTimeout: {
            var timerDisplay = findQmlElement(tabHome, "timerDisplay")
            console.log("QML: onTimeout: " + timerDisplay);
            if (!lastUpdate || !remaining)
                return;

            timer.stop()
            soundAlarm.play()
            timerDisplay.text = "00:00";
            model.status = "finished";
            model.remaining = model.time;
            playpause.source = "qrc:/img/play-16.png"
            playpause.playState = "paused"
        }

        onTriggered: {
            var timerDisplay = findQmlElement(tabHome, "timerDisplay")
            if (!lastUpdate || !remaining)
                return;

            var subtract = new Date() - lastUpdate;
            lastUpdate = new Date()
            //console.log("REMAINING: " + remaining)
            var updatedRemaining = remaining - subtract;
            remaining = new Date(updatedRemaining);
            var secondsRemaining = toSeconds(addZero(remaining.getMinutes()) + ":" + addZero(remaining.getSeconds()));

            timerDisplay.text = addZero(remaining.getMinutes()) + "." + addZero(remaining.getSeconds());
            model.remaining = timerDisplay.text;
            timerCirc.requestPaint();
        }
    }

    Rectangle {
        width: 40
        height: 40
        id: timerCircRect
        anchors.left: parent.right
        color: "transparent"

        Canvas {
            id: timerCirc
            anchors.fill: parent

            onPaint: {
                //console.log("Painting...")
                var ctx = getContext("2d")
                ctx.reset()
                var centreX = width/2
                var centreY = height/2

                ctx.beginPath()
                ctx.fillStyle = "steelblue"
                ctx.moveTo(centreX, centreY)

                ctx.fillStyle = "steelblue"
                ctx.moveTo(centreX, centreY)

                var secRemaining = toSeconds(model.remaining);
                var secTotal = toSeconds(model.time)
                var ratio = (secRemaining/secTotal) * 2;
                //console.log("TOTAL " + secTotal + " - REMAINING: " + secRemaining + " - RATIO: " + ratio);
                ctx.arc(centreX, centreY, width / 4, Math.PI * (2-ratio), 2*Math.PI, false)

                ctx.lineTo(centreX, centreY)
                ctx.closePath()
                ctx.fill()
            }
        }
    }

    Text {
        id: totalTime
        font.pointSize: 10
        anchors.topMargin: 5
        smooth: true
        anchors.left: timerCircRect.right
        anchors.margins: 40
        color: "steelblue"
        font.bold: true
        text: model.time
    }

    Image {
        id: playpause
        source: "qrc:/img/play-16.png"
        anchors.left: totalTime.right
        anchors.margins: 40
        y: 6

        property string playState: "paused"

        Component.onCompleted: rowPlayPause = playpause

        MouseArea {
            anchors.fill: parent

            onClicked: {

                playOrPause(mouseX, mouseY);
                /*if (playpause.playState === "paused") {
                    playpause.source = "qrc:/img/pause-16.png"
                    lastUpdate = new Date()
                    //console.log(model.remaining)
                    //model.remaining = "00:05"

                    var min = parseInt(model.remaining.substr(0,2))
                    var sec = parseInt(model.remaining.substr(3,5))

                    remaining = new Date(null, null, null, 0, min, sec, 0)
                    timer.start()
                    playpause.playState = "running"
                }
                else {
                    console.log("Stopping...")
                    playpause.source = "qrc:/img/play-16.png"
                    playpause.playState = "paused"
                    timer.stop()
                    var timerDisplay = findQmlElement(tabHome, "timerDisplay");
                    model.remaining = timerDisplay.text;
                }*/
            }
        }
    }
}

