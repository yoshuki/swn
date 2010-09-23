package swn {
  import air.update.ApplicationUpdaterUI

  import com.adobe.serialization.json.JSON
  
  import flash.desktop.NativeApplication
  import flash.display.NativeMenu
  import flash.events.ErrorEvent
  import flash.filesystem.File
  import flash.filesystem.FileMode
  import flash.filesystem.FileStream
  import flash.net.Socket

  public class Common {
    public static const CONFIG_FILE:String = 'config.json'
    public static const DEFAULT_LISTEN_PORT:uint = 12345
    public static const DEFAULT_TEXT_COLOR:uint = 0xFFCC00
    public static const DEFAULT_BACK_COLOR:uint = 0x000000
    public static const DEFAULT_BACK_ALPHA:uint = 70
    public static const DEFAULT_BGM:String = ''

    // アプリケーション情報
    public static function get appInfo():Object {
      var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor
      var ns:Namespace = appXML.namespace()
      return {"name": appXML.ns::name, "version": appXML.ns::version}
    }

    // アプリケーション設定
    private static var _config:Object = {}
    public static function get config():Object {
      return _config
    }
    public static function set config(conf:Object):void {
      _config = conf
    }

    // 設定ウィンドウ
    private static var _configWindow:ConfigWindow = null
    public static function get configWindow():ConfigWindow {
      return _configWindow
    }
    public static function set configWindow(window:ConfigWindow):void {
      _configWindow = window
    }

    // タスクトレイ・ドックアイコンのメニュー
    private static var _iconMenu:NativeMenu = new NativeMenu()
    public static function get iconMenu():NativeMenu {
      return _iconMenu
    }

    // クライアントのソケット
    private static var _clientSockets:Vector.<Socket> = new Vector.<Socket>()
    public static function get clientSockets():Vector.<Socket> {
      return _clientSockets
    }

    // 表示待ちメッセージ
    private static var _messages:Vector.<String> = new Vector.<String>()
    public static function get messages():Vector.<String> {
      return _messages
    }

    // SW
    private static var _sw:SW = null
    public static function get sw():SW {
      return _sw
    }
    public static function set sw(sw:SW):void {
      _sw = sw
    }

    // アップデート確認
    public static function checkUpdate():void {
      var appUpdater:ApplicationUpdaterUI = new ApplicationUpdaterUI()
      appUpdater.configurationFile = new File('app:/update-config.xml')
      appUpdater.addEventListener(ErrorEvent.ERROR, function (event:ErrorEvent):void {
        // 動作に直接の支障はないため無視
      })
      appUpdater.initialize()
    }

    // ファイルを開く(同期処理)
    public static function openFile(fileName:String, mode:String, handler:Function):void {
      var file:File = File.applicationStorageDirectory.resolvePath(fileName)
      var fs:FileStream = new FileStream()
      fs.open(file, mode)
      handler(fs)
      fs.close()
    }

    // 設定を読み込む
    public static function loadConfig(initialize:Boolean=false):void {
      if (initialize) {
        config = {}
      } else {
        try {
          openFile(CONFIG_FILE, FileMode.READ, function (fs:FileStream):void {
            config = JSON.decode(fs.readUTF())
          })
        } catch (error:Error) {
          trace(error)
        }
      }
      if (config.listenPort == null) config.listenPort = DEFAULT_LISTEN_PORT
      if (config.textColor  == null) config.textColor  = DEFAULT_TEXT_COLOR
      if (config.backColor  == null) config.backColor  = DEFAULT_BACK_COLOR
      if (config.backAlpha  == null) config.backAlpha  = DEFAULT_BACK_ALPHA
      if (config.bgm        == null) config.bgm        = DEFAULT_BGM
    }

    // 設定を保存する
    public static function saveConfig():void {
      try {
        openFile(CONFIG_FILE, FileMode.WRITE, function (fs:FileStream):void {
          fs.writeUTF(JSON.encode(config))
        })
      } catch (error:Error) {
        trace(error)
      }
    }

    // Vector.<Socket>から指定した要素を削除する
    public static function removeFromSockets(target:Object, vector:Vector.<Socket>):void {
      var index:int = vector.indexOf(target)
      if (index != -1) vector.splice(index, 1)
    }
  }
}
