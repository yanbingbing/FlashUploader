/**
 * Flash Uploader
 *
 * @author bingbing {@link http://yanbingbing.com}
 */
package 
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.system.Security;
	import flash.utils.Timer;
	import flash.utils.describeType;
	
	import org.FileQueue;
	import org.events.TriggerEvent;
	
	[SWF(frameRate="24", widthPercent="100", heightPercent="100")]
	public class FlashUploader extends Sprite 
	{
		private var _params:Object;
		private var _returnJSON:Boolean;
		private var _fileQueue:FileQueue;
		private var _setupTimer:Timer = new Timer(500, 0);
		private var _uploaderInterface:String = 'Uploader';
		
		public function FlashUploader():void {
			Security.allowDomain("*");
            Security.allowInsecureDomain("*");
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.EXACT_FIT;
			
			_params = root.loaderInfo.parameters;
			_params.script = decodeURIComponent(_params.script);
			
			if (_params.uploaderInterface) {
				_uploaderInterface = _params.uploaderInterface
			}
			
			_returnJSON = _params.jsonType == '1';
			
			_setupTimer.addEventListener(TimerEvent.TIMER, setupExternalInterface);
			_setupTimer.start();
			stage.stageWidth > 0 && setupExternalInterface();
		}
		
		private function init():void {
			var button:Sprite = new Sprite();
			button.buttonMode = true;
			button.graphics.beginFill(0, 0);
			button.graphics.drawRect(0, 0, Math.max(stage.stageWidth, 20), Math.max(stage.stageHeight, 20));
			button.graphics.endFill();
			addChild(button);
			
			var typeFilter:Array = [];
			if (_params.fileExt) {
				var fileExts:Array = decodeURIComponent(_params.fileExt).split('|'),
					fileDesc:Array = _params.fileDesc
						? decodeURIComponent(_params.fileDesc).split('|')
						: [];
				for (var n:Number = 0; n < fileExts.length; n++) {
					typeFilter.push(new FileFilter(fileDesc[n] ? (fileDesc[n]+'('+fileExts[n]+')') : fileExts[n], fileExts[n]));
				}
			}
			
			if (_params.multi) {
				var selectList:FileReferenceList = new FileReferenceList();
				selectList.addEventListener(Event.SELECT, function():void{
					selectFiles(selectList.fileList);
				});
				addEventListener(MouseEvent.CLICK, function():void{
					if (!_fileQueue.running) {
						selectList.browse(typeFilter);
					}
				});
			} else {
				var selectOne:FileReference = new FileReference();
				selectOne.addEventListener(Event.SELECT, function():void{
					clearQueue();
					selectFiles([selectOne]);
				});
				addEventListener(MouseEvent.CLICK, function():void{
					if (!_fileQueue.running) {
						selectOne.browse(typeFilter);
					}
				});
			}
			
			_fileQueue = new FileQueue(_params.script, _params.fieldName || 'Filedata',
				Number(_params.sizeLimit), uint(_params.queueLengthLimit));
			
			_fileQueue.addEventListener(TriggerEvent.SELECT_START, trigger);
			_fileQueue.addEventListener(TriggerEvent.SELECT_ONE, trigger);
			_fileQueue.addEventListener(TriggerEvent.SELECT_END, trigger);
			_fileQueue.addEventListener(TriggerEvent.UPLOAD_START, trigger);
			_fileQueue.addEventListener(TriggerEvent.UPLOAD_PROGRESS, trigger);
			_fileQueue.addEventListener(TriggerEvent.UPLOAD_COMPLETE, trigger);
			_fileQueue.addEventListener(TriggerEvent.UPLOAD_CANCEL, trigger);
			_fileQueue.addEventListener(TriggerEvent.QUEUE_START, trigger);
			_fileQueue.addEventListener(TriggerEvent.QUEUE_COMPLETE, trigger);
			_fileQueue.addEventListener(TriggerEvent.QUEUE_SUCCESS, trigger);
			_fileQueue.addEventListener(TriggerEvent.QUEUE_FULL, trigger);
			_fileQueue.addEventListener(TriggerEvent.QUEUE_CLEAR, trigger);
			_fileQueue.addEventListener(TriggerEvent.ERROR, trigger);
		}
		
		private function testExternalInterface():void {
			_setupTimer.stop();
			_setupTimer.removeEventListener(TimerEvent.TIMER, setupExternalInterface);
			_setupTimer = null;
			init();
		}
		
		private function setupExternalInterface(e:TimerEvent = null):void {
			try {
				ExternalInterface.addCallback('startUpload', startUpload);
				ExternalInterface.addCallback('cancelUpload', cancelUpload);
				ExternalInterface.addCallback('clearQueue', clearQueue);
				ExternalInterface.addCallback('testExternalInterface', testExternalInterface);
			} catch (e:Error) {return;}
			ExternalInterface.call(_uploaderInterface + '.testExternalInterface("' + _params.guid + '")');
		}
		
		private function selectFiles(list:Array):void {
			trigger(new TriggerEvent(TriggerEvent.SELECT_START));
			for (var n:uint = 0, l:uint = list.length; n < l; n++) {
				if (!_fileQueue.addFile(list[n])) {
					break;
				}
			}
			trigger(new TriggerEvent(TriggerEvent.SELECT_END, {
				fileCount:_fileQueue.queueLength,
				allBytesTotal:_fileQueue.allBytesTotal
			}));
		}
		
		private function startUpload(id:String = null):void {
			var scriptData:String = decodeURIComponent(ExternalInterface.call('eval', _uploaderInterface + '.readParams("' + _params.guid + '")') as String);
			scriptData && _fileQueue.variables.decode(scriptData);
			_fileQueue.variables['HTTP_COOKIE'] = ExternalInterface.call('eval', '(function(){return document.cookie;})()');
			if (_returnJSON) {
				_fileQueue.variables['HTTP_ACCEPT'] = "application/json,application/javascript";
			}
			_fileQueue.upload(id);
		}
		
		private function cancelUpload(id:String):void {
			_fileQueue.cancel(id);
		}
		
		private function clearQueue():void {
			_fileQueue.clear();
		}
		
		private function trigger(event:TriggerEvent):void {
			ExternalInterface.call(_uploaderInterface + '.trigger("'+ _params.guid + '", "' + event.type + '", ' + JSON.stringify(event.args) + ')');
		}
	}
}