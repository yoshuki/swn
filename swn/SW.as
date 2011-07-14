package swn {
  import flash.display.NativeWindow;
  import flash.display.NativeWindowInitOptions;
  import flash.display.NativeWindowSystemChrome;
  import flash.display.NativeWindowType;
  import flash.display.Screen;
  import flash.display.Sprite;
  import flash.display.StageAlign;
  import flash.display.StageScaleMode;
  import flash.events.IOErrorEvent;
  import flash.events.MouseEvent;
  import flash.events.TimerEvent;
  import flash.filesystem.FileMode;
  import flash.filesystem.FileStream;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import flash.media.Sound;
  import flash.media.SoundChannel;
  import flash.media.SoundTransform;
  import flash.net.URLRequest;
  import flash.system.System;
  import flash.text.engine.EastAsianJustifier;
  import flash.text.engine.ElementFormat;
  import flash.text.engine.FontDescription;
  import flash.text.engine.FontWeight;
  import flash.text.engine.TextBlock;
  import flash.text.engine.TextElement;
  import flash.text.engine.TextLine;
  import flash.utils.Timer;

  import org.libspark.betweenas3.BetweenAS3;
  import org.libspark.betweenas3.tweens.ITween;

  public class SW extends NativeWindow {
    private static const SCREEN_BOUNDS_L:Number = Screen.mainScreen.bounds.left;
    private static const SCREEN_BOUNDS_T:Number = Screen.mainScreen.bounds.top;
    private static const SCREEN_BOUNDS_W:Number = Screen.mainScreen.bounds.width;
    private static const SCREEN_BOUNDS_W_2:Number = SCREEN_BOUNDS_W / 2;
    private static const SCREEN_BOUNDS_H:Number = Screen.mainScreen.bounds.height;
    private static const SCREEN_BOUNDS_H_2:Number = SCREEN_BOUNDS_H / 2;
    private static const SCREEN_BOUNDS_H_3:Number = SCREEN_BOUNDS_H / 3;

    private var lifeTimer:Timer = new Timer(1500);
    private var base:Sprite;
    private var finished:Boolean;
    private var block:TextBlock;
    private var prevLine:TextLine;
    private var currLine:TextLine;
    private var bgmChannel:SoundChannel;

    public function SW():void {
      initParams();

      lifeTimer.addEventListener(TimerEvent.TIMER, timerHandler);

      var options:NativeWindowInitOptions = new NativeWindowInitOptions();
      options.systemChrome = NativeWindowSystemChrome.NONE;
      options.transparent = true;
      options.type = NativeWindowType.LIGHTWEIGHT;
      super(options);

      // ウィンドウサイズを画面いっぱいに広げて常に前面にする
      width = SCREEN_BOUNDS_W;
      height = SCREEN_BOUNDS_H;
      x = SCREEN_BOUNDS_L;
      y = SCREEN_BOUNDS_T;
      alwaysInFront = true;
      visible = true;

      // 座標の基準と消失点を調整する
      stage.align = StageAlign.TOP_LEFT;
      stage.scaleMode = StageScaleMode.NO_SCALE;
      stage.transform.perspectiveProjection.projectionCenter = new Point(SCREEN_BOUNDS_W / 2, SCREEN_BOUNDS_H_3);

      base = new Sprite();
      stage.addChild(base);
      base.alpha = 0;
      base.addEventListener(MouseEvent.CLICK, function (event:MouseEvent):void {
        stop();
      });
    }

    private var _running:Boolean = false;
    public function get running():Boolean {
      return _running;
    }

    private function initParams():void {
      finished = false;
      block = null;
      prevLine = null;
      currLine = null;
      bgmChannel = null;
    }

    public function start(message:String=''):void {
      if (_running) {
        return;
      } else {
        _running = true;
      }

      // 背景を塗りつぶす
      with (base.graphics) {
        clear();
        beginFill(Common.config.backColor);
        drawRect(x, y, width, height);
        endFill();
      }

      // 色指定があれば強制変更
      var textColor:uint = Common.config.textColor;
      var matches:Array = message.match(/^([RYG])(:)(.*)$/ms);
      if (matches) {
        switch (matches[1]) {
          case 'R': textColor = 0xFF3333; break;
          case 'Y': textColor = 0xFFFF00; break;
          case 'G': textColor = 0x00FF00; break;
        }
        message = matches[3];
      }

      var format:ElementFormat = new ElementFormat(new FontDescription('_ゴシック', FontWeight.NORMAL), 64, textColor);
      format.locale = 'ja';

      block = new TextBlock();
//      block.textJustifier = new EastAsianJustifier();
      block.content = new TextElement(message, format);

      BetweenAS3.tween(base, {alpha: Common.config.backAlpha / 100}, null, 0.3).play();
      lifeTimer.start();

      if (Common.config.bgm != '') {
        var bgm:Sound = new Sound(new URLRequest('file://' + Common.config.bgm));
        bgm.addEventListener(IOErrorEvent.IO_ERROR, function (event:IOErrorEvent):void {
          trace(event);
        });
        bgmChannel = bgm.play(0, 999);
      }
    }

    public function stop():void {
      BetweenAS3.tween(base, {alpha: 0}, null, 0.3).play();
      lifeTimer.stop();
      while (base.numChildren > 0) base.removeChildAt(0);

      if (bgmChannel) bgmChannel.stop();

      initParams();

      _running = false;
    }

    private function timerHandler(event:TimerEvent):void {
      if (!finished) {
        currLine = block.createTextLine(prevLine = currLine, SCREEN_BOUNDS_W);
        if (currLine) {
          currLine.rotationX = -45;
          currLine.x = 0;
          currLine.y = SCREEN_BOUNDS_H + currLine.textHeight;
          currLine.z = 0;
          base.addChild(currLine);
          BetweenAS3.serial(
            BetweenAS3.tween(currLine, {y: SCREEN_BOUNDS_H_2, z: SCREEN_BOUNDS_W_2}, null, 10),
            BetweenAS3.tween(currLine, {y: 0, z: SCREEN_BOUNDS_W, alpha: 0}, null, 10),
            BetweenAS3.removeFromParent(currLine)
          ).play();
        }
      }
      if (base.numChildren <= 0) stop();
      if (currLine == null && prevLine) finished = true;
    }
  }
}
