/**
 * Flash Uploader
 *
 * @author    kakalong {@link http://yanbingbing.com}
 * @version   $Id: TriggerEvent.as 4812 2012-04-01 09:49:02Z kakalong $
 */
package org.events 
{
	import flash.events.Event;
	
	public class TriggerEvent extends Event 
	{
		public static const SELECT_START:String    = 'selectStart';/* select start */
		public static const SELECT_ONE:String      = 'selectOne'; /* a file was selected*/
		public static const SELECT_END:String      = 'selectEnd'; /* select complete */
		
		public static const UPLOAD_START:String    = 'uploadStart'; /* a connection was open*/
		public static const UPLOAD_PROGRESS:String = 'uploadProgress'; /* a connection progress */
		public static const UPLOAD_COMPLETE:String = 'uploadComplete';/* a connection complete */
		public static const UPLOAD_CANCEL:String   = 'uploadCancel'; /* a connection was abort or sthelse */
		
		public static const QUEUE_START:String     = 'queueStart';
		public static const QUEUE_COMPLETE:String  = 'queueComplete';/* queue was empty  */
		public static const QUEUE_SUCCESS:String   = 'queueSuccess'; /* all connection complete */
		public static const QUEUE_CLEAR:String     = 'queueClear'; /* queue was clear to empty */
		public static const QUEUE_FULL:String      = 'queueFull'; /* queue is full */
		public static const ERROR:String           = 'error';/* possiblily errors */
		
		public var args:* = null;
		
		public function TriggerEvent(type:String, ... args)
		{
			super(type);
			this.args = args;
		}
	}
}