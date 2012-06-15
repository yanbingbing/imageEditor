/**
 * CmsTop Image Editor
 *
 * @copy    (c) CmsTop {@link http://www.cmstop.com}
 * @author  UE   lein
 * 			UI   kangkang
 * 			AS   kakalong {@link http://yanbingbing.com}
 *          PHP  micate   {@link http://micate.me}
 * @version $Id$
 */
package cmstop 
{
	import cmstop.events.ImageEvent;
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	public class Uploader extends EventDispatcher
	{
		private var _loader:URLLoader = null;
		private var _dataTimer:Timer = null;
		private var _fileFieldName:String;
		private var _url:String;
		
		public function Uploader(fileFieldName:String, url:String)
		{
			_fileFieldName = fileFieldName;
			_url = url;
		}
		
		
		private function onCompleteTimer(event:Event):void {
			_loader.removeEventListener(Event.COMPLETE, onComplete);
			_dataTimer = new Timer(100, 1);
			_dataTimer.addEventListener(TimerEvent.TIMER, function():void{
				_dataTimer = null;
				onComplete(String(_loader.data));
			});
			_dataTimer.start();
		}
		
		private function onComplete(data:String):void {
			removeListener();
			dispatchEvent(new ImageEvent(ImageEvent.UPLOAD_COMPLETE, data));
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
			dispatchEvent(new ImageEvent(ImageEvent.UPLOAD_ERROR, {type:e.type, text:text}));
		}
		private function removeListener(): void {
			if (_dataTimer) {
				_dataTimer.stop();
				_dataTimer = null;
			}
			_loader.removeEventListener(Event.COMPLETE, onComplete);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			_loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onError);
			_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			try {
				_loader.close();
			} catch (e:Error) {}
		}
		
		public function upload(fileName:String, fileContent:ByteArray, variables:URLVariables = null):void {
			var postData:ByteArray = new ByteArray();
			postData.endian = Endian.BIG_ENDIAN;
			var boundary:String = getBoundary();
			
			// addVariables
			for (var name:String in variables) {
				postData.writeUTFBytes("--" + boundary + "\r\n");
				postData.writeUTFBytes("Content-Disposition: form-data; name=\""+name+"\"\r\n\r\n");
				postData.writeUTFBytes(variables[name]+"\r\n");
			}

			// addFile
			postData.writeUTFBytes("--" + boundary + "\r\n");
			postData.writeUTFBytes("Content-Disposition: form-data; name=\""+_fileFieldName+"\"; filename=\"" + fileName + "\"\r\n");
			postData.writeUTFBytes("Content-Type: application/octet-stream\r\n\r\n");
			
			
			
			postData.writeBytes(fileContent);
			
			// addEnd
			postData.writeUTFBytes("\r\n--" + boundary + "--");
			
			var random:String = getTimer().toString();
			var request:URLRequest = new URLRequest(_url + (_url.indexOf('?') > 0 ? '&' : '?') + random);
			request.method = URLRequestMethod.POST;
			request.data = postData;
			request.requestHeaders.push(new URLRequestHeader("Content-type", "multipart/form-data; boundary=" + boundary));
			request.requestHeaders.push(new URLRequestHeader("Accept", "application/json,text/javascript"));
			_loader = new URLLoader();
			_loader.addEventListener(Event.COMPLETE, onCompleteTimer);
			_loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onError);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			try {
				_loader.load(request);
			} catch (e:Error) {
				onError(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
			}
		}
		
		private function getBoundary():String {
			var boundary:String = '';
			for (var i:uint = 0; i < 32; i++ ) {
				boundary += String.fromCharCode(int( 97 + Math.random() * 25 ));
			}
			return boundary;
		}
	}

}