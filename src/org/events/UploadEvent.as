/**
 * Flash Uploader
 *
 * @author bingbing {@link http://yanbingbing.com}
 */
package org.events 
{
	import flash.events.Event;
	
	public class UploadEvent extends Event 
	{
		public static const UPLOAD_CANCEL:String   = 'uploadCancel';
		public static const UPLOAD_START:String    = 'uploadStart';
		public static const UPLOAD_PROGRESS:String = 'uploadProgress';
		public static const UPLOAD_ERROR:String    = 'uploadError';
		public static const UPLOAD_COMPLETE:String = 'uploadComplete';
		public var data:* = null;
		
		public function UploadEvent(type:String, data:* = null) 
		{ 
			super(type);
			this.data = data;
		}
	}
}