import mx.events.FlexEvent;

import swn.Common;
import swn.ConfigWindow;
import swn.SW;

[Embed(source='swn/images/SWN16.png')]
private var IconImage16:Class;
[Embed(source='swn/images/SWN128.png')]
private var IconImage128:Class;

private var lifeTimer:Timer = new Timer(1000);

private function initApp(event:FlexEvent):void {
  // ここ以降呼ばれる必要がないため解除
  Application(event.target).removeEventListener(FlexEvent.APPLICATION_COMPLETE, initApp);

  // アップデート確認
  Common.checkUpdate();

  // 設定読み込み
  Common.loadConfig();

  if (NativeApplication.supportsSystemTrayIcon || NativeApplication.supportsDockIcon) {
    var menu:NativeMenu = Common.iconMenu;

    // システムトレイ・ドックアイコンを登録
    var icon:InteractiveIcon;
    if (NativeApplication.supportsSystemTrayIcon) {
      var stIcon:SystemTrayIcon = SystemTrayIcon(NativeApplication.nativeApplication.icon);
      icon = stIcon;
      stIcon.menu = menu;
      var appInfo:Object = Common.appInfo;
      stIcon.tooltip = appInfo.name + ' ' + appInfo.version;
    } else if (NativeApplication.supportsDockIcon) {
      var dIcon:DockIcon = DockIcon(NativeApplication.nativeApplication.icon);
      icon = dIcon;
      dIcon.menu = menu;
    } else {
      trace('Failed to register icon.');
      // 操作不能回避のため、アイコンが登録できなければ終了
      NativeApplication.nativeApplication.exit();
    }

    // アイコン画像
    var iconImage16:Bitmap  = Bitmap(new IconImage16());
    var iconImage128:Bitmap = Bitmap(new IconImage128());
    icon.bitmaps = [iconImage16, iconImage128];

    // メニュー - 設定
    var configItem:NativeMenuItem = new NativeMenuItem('設定');
    menu.addItem(configItem);
    configItem.addEventListener(Event.SELECT, function (event:Event):void {
      if (Common.configWindow == null || Common.configWindow.closed) {
        Common.configWindow = new ConfigWindow();
        Common.configWindow.open();
      } else {
        Common.configWindow.activate();
      }
    });

    // メニュー - 終了
    var exitItem:NativeMenuItem = new NativeMenuItem('SWNを終了');
    menu.addItem(exitItem);
    exitItem.addEventListener(Event.SELECT, function (event:Event):void {
      NativeApplication.nativeApplication.exit();
    });
  } else {
    trace('Failed to register icon.');
    // 操作不能回避のため、アイコンが登録できなければ終了
    NativeApplication.nativeApplication.exit();
  }

  if (ServerSocket.isSupported) {
    var server:ServerSocket = new ServerSocket();
    server.addEventListener(ServerSocketConnectEvent.CONNECT, function (event:ServerSocketConnectEvent):void {
      // 同時接続は3つまで
      if (Common.clientSockets.length >= 3) return;

      var socket:Socket = event.socket;
      Common.clientSockets.push(socket);
      // 接続を受けたらメッセージを受け取って切る
      socket.addEventListener(ProgressEvent.SOCKET_DATA, function (event:ProgressEvent):void {
        // メッセージ受け取りは3つまで
        if (Common.messages.length >= 3) {
          socket.writeUTFBytes('Message queue is full.');
        } else {
          var message:String = socket.readUTFBytes(socket.bytesAvailable);
          Common.messages.push(message);
          socket.writeUTFBytes('Received successfully.');
        }
        socket.flush();
        socket.close();
        Common.removeFromSockets(socket, Common.clientSockets);
      });
      socket.addEventListener(Event.CLOSE, function (event:Event):void {
        Common.removeFromSockets(socket, Common.clientSockets);
      });
      socket.addEventListener(IOErrorEvent.IO_ERROR, function (event:IOErrorEvent):void {
        Common.removeFromSockets(socket, Common.clientSockets);
      });
    });
    server.addEventListener(Event.CLOSE, function (event:Event):void {
      trace('ServerSocket closed.');
      // サーバソケットが閉じられたら終了
      NativeApplication.nativeApplication.exit();
    })
    server.bind(Common.config.listenPort);
    server.listen();
  } else {
    trace('ServerSocket is not available.');
    // サーバソケットが使えなければ終了
    NativeApplication.nativeApplication.exit();
  }

  lifeTimer.addEventListener(TimerEvent.TIMER, function (event:Event):void {
    if (Common.sw == null) Common.sw = new SW();
    if (!Common.sw.running) {
      var message:String = Common.messages.shift();
      if (message) Common.sw.start(message);
    }
  });
  lifeTimer.start();
}
