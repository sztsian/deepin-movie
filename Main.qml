import QtQuick 2.1
import QtGraphicalEffects 1.0
import QtWebKit 3.0
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0

Item {
    id: window
    
    property int videoInitWidth: 950
    property int videoInitHeight: (videoInitWidth - padding * 2) * movie_info["video_height"] / movie_info["video_width"] + padding * 2
    property int videoMinWidth: 470
    property int videoMinHeight: (videoMinWidth - padding * 2) * movie_info["video_height"] / movie_info["video_width"] + padding * 2
    
    property int titlebarHeight: 45
    property int frameRadius: 3
    property int shadowRadius: 10
    property int padding: frameRadius + shadowRadius
    
    default property alias tabPages: pages.children
    property alias playPage: playPage
    property alias player: player
    property alias titlebar: titlebar
    property alias frame: frame
    property int currentTab: 0
    property int windowLastState: 0
    
    property bool showTitlebar: true
    property bool inInteractiveArea: false
    
    signal exitMouseArea
    
    Timer {
        id: outWindowTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (!inInteractiveArea) {
                player.hidingTimer.interval = 800
                player.hidingTimer.restart()
            }
        }
    }
    
    onExitMouseArea: {
        outWindowTimer.restart()
    }
    
    function monitorWindowClose() {
        database.record_video_position(player.source, player.position)
        config.save("Normal", "volume", player.volume)
    }
    
    function monitorWindowState(state) {
        if (windowLastState != state) {
            if (state == Qt.WindowMinimized) {
                player.tryPauseVideo()
            } else {
                player.tryPlayVideo()
            }
            windowLastState = state
        }
    }
    
    function toggleMaxWindow() {
        windowView.getState() == Qt.WindowMaximized ? maxButton.imageName = "image/window_max" : maxButton.imageName = "image/window_unmax"
        windowView.getState() == Qt.WindowMaximized ? shadow.visible = true : shadow.visible = false
        windowView.getState() == Qt.WindowMaximized ? frame.border.width = (shadowRadius + frameRadius) * 2 : frame.border.width = 0
        windowView.getState() == Qt.WindowMaximized ? frame.radius = frameRadius : frame.radius = 0
        windowView.getState() == Qt.WindowMaximized ? frameBackground.radius = frameRadius : frameBackground.radius = 0
        windowView.getState() == Qt.WindowMaximized ? frameBorder.visible = true : frameBorder.visible = false
        windowView.getState() == Qt.WindowMaximized ? windowView.showNormal() : windowView.showMaximized()
    }
    
    function toggleFullWindow() {
        windowView.getState() == Qt.WindowFullScreen ? shadow.visible = true : shadow.visible = false
        windowView.getState() == Qt.WindowFullScreen ? frame.border.width = (shadowRadius + frameRadius) * 2 : frame.border.width = 0
        windowView.getState() == Qt.WindowFullScreen ? frame.radius = frameRadius : frame.radius = 0
        windowView.getState() == Qt.WindowFullScreen ? frameBackground.radius = frameRadius : frameBackground.radius = 0
        windowView.getState() == Qt.WindowFullScreen ? frameBorder.visible = true : frameBorder.visible = false
        windowView.getState() == Qt.WindowFullScreen ? windowView.showNormal() : windowView.showFullScreen()
        
        if (windowView.getState() == Qt.WindowFullScreen) {
            hidingTitlebarAnimation.restart()
            player.hidingBottomPanelAnimation.restart()
        }
    }

    function selectPlayPage() {
        for (var i = 0; i < tabPages.length; ++i) {
            /* Don't set opacity, otherwise 'opacity 0' widget will eat othersise widget's event */
            tabPages[i].visible = false
        }
        
        playPage.visible = true
    }
    
    function selectTabPage() {
        for (var i = 0; i < tabPages.length; ++i) {
            /* Don't set opacity, otherwise 'opacity 0' widget will eat othersise widget's event */
            tabPages[i].visible = tabButtonArea.children[i].tabIndex == currentTab
        }
        
        playPage.visible = false
    }
    
    function initSize() {
        windowView.width = videoInitWidth
        windowView.height = videoInitHeight
        
        windowView.setMinSize(videoMinWidth, videoMinHeight)
        
        print(videoInitWidth, videoInitHeight, videoMinWidth, videoMinHeight)
    }
    
    Component.onCompleted: {
        initSize()
    }
    
    RectangularGlow {
        id: shadow
        anchors.fill: frame
        glowRadius: shadowRadius
        spread: 0.2
        color: Qt.rgba(0, 0, 0, 0.3)
        /* color: Qt.rgba(1, 0, 0, 0.5) */
        cornerRadius: frame.radius + shadowRadius
        visible: true
    }
    
    ResizeArea {
        id: resizeArea
        window: windowView
        frame: frame
        resizeOffset: 10
        framePadding: padding
        proportionalResize: true
    }
    
    Rectangle {
        id: frame
        opacity: 1                /* frame transparent */
        color: Qt.rgba(0, 0, 0, 0)
        anchors.centerIn: parent
        radius: frameRadius
        border.width: (shadowRadius + frameRadius) * 2
        border.color: Qt.rgba(0, 0, 0, 0)
        width: window.width - border.width
        height: window.height - border.width
        
        Rectangle {
            id: frameBackground
            color: "#1D1D1D"
            anchors.fill: parent
            radius: frameRadius
        }
        
        RoundItem {
            target: frameBackground
            radius: frame.radius
        }
    }
    
    Rectangle {
        id: pages
        objectName: "pages"
        anchors.top: titlebar.bottom
        anchors.bottom: frame.bottom
        anchors.left: titlebar.left
        anchors.right: titlebar.right
        color: Qt.rgba(0, 0, 0, 0)
        
        WebView {
            id: movieStorePage
            url: "http://pianku.xmp.kankan.com/moviestore_index.html"
            anchors.fill: parent
            property string name: "在线影院"
            visible: false
        }
        
        WebView {
            id: searchPage
            url: "http://search.xmp.kankan.com/lndex4xmp.shtml"
            anchors.fill: parent
            property string name: "视频搜索"
            visible: false
        }
    }
    
    Rectangle {
        id: playPage
        anchors.top: titlebar.top
        anchors.bottom: pages.bottom
        anchors.left: pages.left
        anchors.right: pages.right
        color: Qt.rgba(0, 0, 0, 0)
        
        Player {
            id: player
            width: parent.width
            height: parent.height
            source: movie_file
            videoPreview.video.source: movie_file
            
            Component.onCompleted: {
                videoPreview.video.pause()
            }
            
            onBottomPanelShow: {
                showingTitlebarAnimation.restart()
            }

            onBottomPanelHide: {
                if (playPage.visible) {
                    if (!titlebar.pressed) {
                        hidingTitlebarAnimation.restart()
                    }
                }
            }
            
            onShowCursor: {
                player.videoArea.cursorShape = Qt.ArrowCursor
            }

            onHideCursor: {
                if (!titlebar.pressed) {
                    player.videoArea.cursorShape = Qt.BlankCursor
                }
            }
            
            onToggleFullscreen: {
                toggleFullWindow()
            }
            
            onVisibleChanged: {
                if (!player.visible) {
                    player.tryPauseVideo()
                } else {
                    player.tryPlayVideo()
                }
            }
        }
        
        RoundItem {
            target: player
            radius: frame.radius
        }
    }
    
    DragArea {
        id: titlebar
        window: windowView
        anchors.top: frame.top
        anchors.left: frame.left
        anchors.right: frame.right
        width: frame.width
        height: titlebarHeight
        hoverEnabled: true
        
        onDoubleClicked: {
            toggleMaxWindow()
        }
        
        Rectangle {
            id: titlebarBackground
            anchors.fill: parent
            color: "#00000000"
        
            LinearGradient {
                id: topPanelBackround
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 60
                start: Qt.point(0, 0)
                end: Qt.point(0, height)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#FF000000"}
                    GradientStop { position: 1.0; color: "#00000000"}
                }
                visible: playPage.visible && showTitlebar
            }
            
            TopRoundItem {
                target: topPanelBackround
                radius: frame.radius
                visible: playPage.visible && showTitlebar
            }
    
            Image {
                id: appIcon
                source: "image/logo.png"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20
                visible: showTitlebar ? 1 : 0
            }

            Rectangle {
                id: tabEffect
                width: 239
                height: 43
                color: Qt.rgba(0, 0, 0, 0)
                visible: showTitlebar ? 1 : 0
                
                Image {
                    id: tabEffectImage
                    anchors.fill: parent
                    source: "image/tab_select_effect.png"
                    visible: showTitlebar ? 1 : 0
                }
                
                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuint
                    }
                }
            }
            
            TabButton {
                id: playPageTab
                text: "视频播放"
                anchors.left: appIcon.right
                width: 160
                visible: showTitlebar ? 1 : 0

                onPressed: {
                    tabEffect.x = x - 35
                    selectPlayPage()
                }
                
                Component.onCompleted: {
                    tabEffect.x = x - 35
                }
            }
            
            Row {
                id: tabButtonArea
                height: parent.height
                anchors.left: playPageTab.right
                spacing: 40
                
                Repeater {
                    model: tabPages.length
                    delegate: TabButton {
                        text: tabPages[index].name
                        tabIndex: index
                        visible: showTitlebar ? 1 : 0
                        
                        onPressed: {
                            tabEffect.x = x + width / 2 + 85
                            currentTab = index
                            selectTabPage()
                        }
                    }
                }
            }
            
            Row {
                anchors {right: parent.right}
                id: windowButtonArea
                
                ImageButton {
                    id: minButton
                    imageName: "image/window_min"
                    onClicked: {
                        windowView.doMinimized()
                    }
                    visible: showTitlebar ? 1 : 0
                }

                ImageButton {
                    id: maxButton
                    imageName: "image/window_max"
                    onClicked: {toggleMaxWindow()}
                    visible: showTitlebar ? 1 : 0
                }

                ImageButton {
                    id: closeButton
                    imageName: "image/window_close"
                    onClicked: {windowView.close()}
                    visible: showTitlebar ? 1 : 0
                }
            }
        }
        
        InteractiveItem {
            targetItem: parent
        }
    }
    
    Rectangle {
        id: frameBorder
        anchors.fill: frame
        color: Qt.rgba(0, 0, 0, 0)
        border.color: Qt.rgba(100, 100, 100, 0.3)
        border.width: 1
        smooth: true
        radius: frameRadius
    }
    
    ParallelAnimation{
        id: showingTitlebarAnimation
        alwaysRunToEnd: true
        
        PropertyAnimation {
            target: titlebar
            property: "height"
            to: titlebarHeight
            duration: 100
            easing.type: Easing.OutQuint
        }
        
        onRunningChanged: {
            if (!showingTitlebarAnimation.running) {
                showTitlebar = true
            }
        }
    }    

    ParallelAnimation{
        id: hidingTitlebarAnimation
        alwaysRunToEnd: true
        
        PropertyAnimation {
            target: titlebar
            property: "height"
            to: 0
            duration: 100
            easing.type: Easing.OutQuint
        }
        
        onRunningChanged: {
            if (!showingTitlebarAnimation.running) {
                showTitlebar = false
            }
        }
    }    
}

