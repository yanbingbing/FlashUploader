/**
 * Flash Uploader
 *
 * @author    kakalong {@link http://yanbingbing.com}
 * @version   $Id: FileQueue.as 5370 2012-04-25 07:06:11Z kakalong $
 */
package org 
{
	import org.events.*;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.net.URLVariables;
	
	public class FileQueue extends EventDispatcher
	{
		private const MAX_QUEUE_LENGTH:uint = 3;
		
		private var _queue:Array = new Array();
		private var _stack:Object = new Object();
		private var _uploadQueue:Object = new Object();
		
		private var _queueLength:uint = 0;
		private var _uploadQueueLength:uint = 0;
		private var _allBytesLoaded:Number = 0;
		private var _allBytesTotal:Number = 0;
		private var _running:Boolean = false;
		private var _successCount:uint = 0;
		private var _errorCount:uint = 0;
		
		private var _url:String = '';
		private var _variables:URLVariables = new URLVariables();
		private var _fieldName:String = null;
		private var _sizeLimit:Number = 0;
		private var _queueLengthLimit:uint = 0;
		
		
		public function FileQueue(url:String, fieldName:String = 'Filedata', sizeLimit:Number = 0, queueLengthLimit:uint = 0)
		{
			_url = url;
			_fieldName = fieldName;
			_sizeLimit = sizeLimit;
			_queueLengthLimit = queueLengthLimit;
		}
		public function get variables():URLVariables {
			return _variables;
		}
		
		public function get queueLength():uint {
			return _queueLength;
		}
		public function get allBytesTotal():Number {
			return _allBytesTotal;
		}
		public function get running():Boolean {
			return _running;
		}
		public function addFile(f:FileReference):Boolean {
			var file:File = new File(guid(), f);
			if (_queueLengthLimit && _queueLength >= _queueLengthLimit) {
				// queuefull
				dispatchEvent(new TriggerEvent(TriggerEvent.QUEUE_FULL, _queueLengthLimit));
				return false;
			}
			if (_sizeLimit && file.size > _sizeLimit) {
				// error
				dispatchEvent(new TriggerEvent(TriggerEvent.ERROR, {
					ID:   file.id,
					file: file,
					type: 'SizeLimit',
					info: 'File size:'+file.size+' is greater than limit:'+_sizeLimit
				}));
				return false;
			}
			file.addEventListener(UploadEvent.UPLOAD_CANCEL, onCancel);
			_stack[file.id] = file;
			_queue.push(file.id);
			_queueLength += 1;
			_allBytesTotal += file.size;
			dispatchEvent(new TriggerEvent(TriggerEvent.SELECT_ONE, {
				ID : file.id,
				file: file
			}));
			return true;
		}
		public function upload(id:String = null):void {
			if (id) {
				var i:int = _queue.indexOf(id);
				if (_uploadQueueLength < 5 && i > -1) {
					_queue.splice(i, 1);
					uploadItem(id);
				}
			} else {
				while (_uploadQueueLength < MAX_QUEUE_LENGTH && (id = _queue.shift())) {
					uploadItem(id);
				}
			}
		}
		
		private function uploadItem(id:String):void {
			if ((id in _uploadQueue) || !(id in _stack)) {
				return;
			}
			if (!_running) {
				_running = true;
				dispatchEvent(new TriggerEvent(TriggerEvent.QUEUE_START, {
					fileCount:_queueLength,
					allBytesTotal:_allBytesTotal
				}));
			}
			_uploadQueue[id] = 0;
			_uploadQueueLength += 1;
			var file:File = _stack[id];
			// addevents
			file.addEventListener(UploadEvent.UPLOAD_START, onStart);
			file.addEventListener(UploadEvent.UPLOAD_PROGRESS, onProgress);
			file.addEventListener(UploadEvent.UPLOAD_COMPLETE, onComplete);
			file.addEventListener(UploadEvent.UPLOAD_ERROR, onError);
			file.upload(_url + (_url.indexOf('?') > -1 ? '&' : '?') + (new Date()).getTime().toString(16), _variables, _fieldName);
		}
		
		private function onStart(event:UploadEvent):void {
			var file:File = event.target as File;
			dispatchEvent(new TriggerEvent(TriggerEvent.UPLOAD_START, {
				ID:file.id,
				file:file
			}));
		}
		private function onProgress(event:UploadEvent):void {
			var file:File = event.target as File;
			var data:Object = event.data as Object;
			_allBytesLoaded += data.bytesLoadedIncr;
			dispatchEvent(new TriggerEvent(TriggerEvent.UPLOAD_PROGRESS, {
				ID             : file.id,
				file           : file,
				speed          : data.speed,
				percentage     : data.percentage,
				bytesLoaded    : data.bytesLoaded,
				allBytesLoaded : _allBytesLoaded
			}));
		}
		private function onComplete(event:UploadEvent):void {
			var file:File = event.target as File;
			removeListener(file);
			dispatchEvent(new TriggerEvent(TriggerEvent.UPLOAD_COMPLETE, {
				ID        : file.id,
				file      : file,
				data      : encodeURIComponent(event.data as String),
				fileCount : _queueLength - 1
			}));
			_successCount += 1;
			complete(file.id);
		}
		private function onCancel(event:UploadEvent):void {
			var file:File = event.target as File;
			removeListener(file);
			dispatchEvent(new TriggerEvent(TriggerEvent.UPLOAD_CANCEL, {
				ID   : file.id,
				file : file
			}));
			if (event.data as Boolean) {
				return;
			}
			_allBytesTotal -= file.size;
			complete(file.id);
		}
		
		private function onError(event:UploadEvent):void {
			var file:File = event.target as File;
			var err:Object = event.data as Object;
			removeListener(file);
			dispatchEvent(new TriggerEvent(TriggerEvent.ERROR, {
				ID   : file.id,
				file : file,
				type : err.type,
				info : err.text
			}));
			_errorCount += 1;
			complete(file.id);
		}
		private function complete(id:String):void {
			if (id in _stack) {
				delete _stack[id];
				_queueLength -= 1;
			}
			if (id in _uploadQueue) {
				delete _uploadQueue[id];
				_uploadQueueLength -= 1;
			}
			if (!_running) {
				return;
			}
			if (_queueLength) {
				upload(null);
			} else if (!_uploadQueueLength) {
				// dispatch queue complete
				dispatchEvent(new TriggerEvent(TriggerEvent.QUEUE_COMPLETE, {
					successCount   : _successCount,
					errorCount     : _errorCount,
					allBytesLoaded : _allBytesLoaded
				}));
				
				_errorCount || dispatchEvent(new TriggerEvent(TriggerEvent.QUEUE_SUCCESS));
				// reset
				reset();
			}
		}
		
		private function removeListener(file:File):void {
			file.removeEventListener(UploadEvent.UPLOAD_START, onStart);
			file.removeEventListener(UploadEvent.UPLOAD_PROGRESS, onProgress);
			file.removeEventListener(UploadEvent.UPLOAD_COMPLETE, onComplete);
			file.removeEventListener(UploadEvent.UPLOAD_CANCEL, onCancel);
			file.removeEventListener(UploadEvent.UPLOAD_ERROR, onError);
		}
		
		public function cancel(id:String):void {
			if (id in _stack) {
				(_stack[id] as File).cancel();
			}
		}
		public function clear():void {
			for each(var file:File in _stack) {
				file.cancel(true);
			}
			dispatchEvent(new TriggerEvent(TriggerEvent.QUEUE_CLEAR));
			if (_running) {
				dispatchEvent(new TriggerEvent(TriggerEvent.QUEUE_COMPLETE, {
					successCount   : _successCount,
					errorCount     : _errorCount,
					allBytesLoaded : _allBytesLoaded
				}));
				
				_errorCount || dispatchEvent(new TriggerEvent(TriggerEvent.QUEUE_SUCCESS));
			}
			reset();
		}
		private function reset():void {
			_queue = new Array();
			_stack = new Object();
			_uploadQueue = new Object();
			_queueLength = 0;
			_uploadQueueLength = 0;
			_allBytesLoaded = 0;
			_allBytesTotal = 0;
			_errorCount = 0;
			_successCount = 0;
			_running = false;
		}
		private function guid():String {
			var ID:String = '';
			for (var i:uint = 0; i < 6; i++ ) {
				ID += String.fromCharCode(int( 65 + Math.random() * 25 ));
			}
			return (ID in _stack) ? guid() : ID;
		}
	}
}