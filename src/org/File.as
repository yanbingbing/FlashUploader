/**
 * Flash Uploader
 *
 * @author    kakalong {@link http://yanbingbing.com}
 * @version   $Id: File.as 5367 2012-04-25 06:54:02Z kakalong $
 */
package org 
{
	import org.events.*;
	import flash.events.*;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	public class File extends EventDispatcher
	{
		private var _file:FileReference = null;
		private var _id:String = '';
		
		private var _dataTimer:Timer = new Timer(100, 1);
		private var _lastTimer:Number = 0;
		private var _lastBytesLoaded:Number = 0;
		
		public function File(id:String, file:FileReference) {
			_file = file;
			_id = id;
			_dataTimer.addEventListener(TimerEvent.TIMER, function():void{
				_dataTimer.reset();
				onComplete(new DataEvent(DataEvent.UPLOAD_COMPLETE_DATA, false, false, ""));
			});
		}
		public function get name():String {
			return _file.name;
		}
		public function get size():Number {
			return _file.size;
		}
		public function get id():String {
			return _id;
		}
		
		public function cancel(inClear:Boolean = false):void {
			_file.cancel();
			removeListener();
			dispatchEvent(new UploadEvent(UploadEvent.UPLOAD_CANCEL, inClear));
		}
		
		private function onOpen(event:Event):void {
			_lastTimer = getTimer();
			_file.removeEventListener(Event.OPEN, onOpen);
		}
		
		private function onProgress(event:ProgressEvent):void {
			var timer:Number = getTimer();
			var diffTimer:Number = timer - _lastTimer;
			var bytesLoaded:Number = event.bytesLoaded;
			var percentage:Number = Math.round((bytesLoaded / event.bytesTotal) * 100);
			var bytesLoadedIncr:Number = bytesLoaded - _lastBytesLoaded;
			var speed:Number = int((bytesLoadedIncr / 1024) / (diffTimer / 10000)) / 10;
			if (bytesLoadedIncr && (diffTimer > 20 || percentage == 100)) {
				_lastTimer = timer;
				_lastBytesLoaded = bytesLoaded;
				dispatchEvent(new UploadEvent(UploadEvent.UPLOAD_PROGRESS, {
					percentage:percentage,
					bytesLoaded:bytesLoaded,
					bytesLoadedIncr:bytesLoadedIncr,
					speed:speed
				}));
			}
		}
		
		private function onCompleteTimer(event:Event):void {
			_file.removeEventListener(Event.COMPLETE, onCompleteTimer);
			_dataTimer.start();
		}
		
		private function onComplete(event:DataEvent):void {
			removeListener();
			onProgress(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _file.size, _file.size));
			dispatchEvent(new UploadEvent(UploadEvent.UPLOAD_COMPLETE, event.data));
		}
		
		private function onError(e:Event):void {
			var text:String = "";
			switch (true) {
			case e.type == HTTPStatusEvent.HTTP_STATUS:
				text = String((e as HTTPStatusEvent).status);
				if (text == "200") {
					return;
				}
				break;
			case (e is ErrorEvent):
				text = (e as ErrorEvent).text;
				break;
			}
			removeListener();
			dispatchEvent(new UploadEvent(UploadEvent.UPLOAD_ERROR, {
				type:e.type,
				text:text
			}));
		}
		
		private function onCancel(event:Event):void {
			removeListener();
		}
		
		private function removeListener(): void {
			if (_dataTimer.running) {
				_dataTimer.reset();
			}
			_file.removeEventListener(Event.OPEN, onOpen);
			_file.removeEventListener(Event.CANCEL, onCancel);
			_file.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			_file.removeEventListener(Event.COMPLETE, onCompleteTimer);
			_file.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onComplete);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			_file.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onError);
			_file.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
		}
		
		public function upload(url:String, variables:URLVariables = null, fieldName:String = 'Filedata'):void 
		{
			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.POST;
			request.data = variables;
			_file.addEventListener(Event.OPEN, onOpen);
			_file.addEventListener(ProgressEvent.PROGRESS, onProgress);
			_file.addEventListener(Event.COMPLETE, onCompleteTimer);
			_file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onComplete);
			_file.addEventListener(Event.CANCEL, onCancel);
			_file.addEventListener(HTTPStatusEvent.HTTP_STATUS, onError);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onError);
			_file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			dispatchEvent(new UploadEvent(UploadEvent.UPLOAD_START));
			try {
				_file.upload(request, fieldName);
			} catch (e:Error) {
				onError(new ErrorEvent(e.name, e.message));
			}
		}
	}
}