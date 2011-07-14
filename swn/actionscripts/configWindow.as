import com.adobe.serialization.json.JSON;

import flash.filesystem.File;
import flash.net.FileFilter;

import mx.events.AIREvent;

import swn.Common;

private function initWin(event:AIREvent):void {
  loadConfig();
}

private function initConfig():void {
  Common.loadConfig(true);
  loadConfig();
}

private function loadConfig():void {
  var config:Object = Common.config;
  listenPort.selectedItem = config.listenPort;
  textColor.selectedItem = config.textColor;
  backColor.selectedItem = config.backColor;
  backAlpha.value = config.backAlpha;
  bgm.text = config.bgm;
}

private function saveConfig():void {
  var config:Object = Common.config;
  config.listenPort = listenPort.selectedItem;
  config.textColor = textColor.selectedItem;
  config.backColor = backColor.selectedItem;
  config.backAlpha = backAlpha.value;
  config.bgm = bgm.text;
  Common.saveConfig();
}

private function selectBgm():void {
  var bgmFile:File = new File();
  bgmFile.addEventListener(Event.SELECT, function (event:Event):void {
    bgm.text = bgmFile.nativePath;
  });
  bgmFile.browse([new FileFilter('MP3(*.mp3)', '*.mp3')]);
}
