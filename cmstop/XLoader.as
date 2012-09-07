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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class XLoader 
	{
		public static const IMAGE:String = "image";
		public static const TEXT:String = "text";
		private static const MAX_THREADS:Number = 3;
		private static var _stack:Array = new Array();
		private static var _numRuns:Number = 0;
		public function XLoader() 
		{}
		
		public static function load(type:String, request:URLRequest, complete:Function = null, error:Function = null, progress:Function = null, json:Boolean = true):void
		{
			var url:String = request.url;
			var date:Date = new Date();
			var random:String = date.getTime().toString(16);
			request.url = url + (url.indexOf('?') > 0 ? '&' : '?') + random;
			_stack.push([type, request, complete, error, progress, json]);
			if (_numRuns < MAX_THREADS) {
				step();
			}
		}
		
		private static function step():void {
			if (_numRuns >= MAX_THREADS) {
				return;
			}
			var args:Array = _stack.shift();
			if (args == null) {
				return;
			}
			_numRuns += 1;
			if (args[0] == 'image') {
				loadImage(args[1], args[2], args[3], args[4]);
			} else {
				loadText(args[1], args[2], args[3], args[4], args[5]);
			}
			if (_numRuns < MAX_THREADS) {
				step();
			}
		}
		
		private static function loadText(request:URLRequest, complete:Function = null, error:Function = null, progress:Function = null, json:Boolean = true):void
		{
			var loader:URLLoader = new URLLoader();
			var onError:Function = function(e:Event):void {
				var text:String = "";
				switch (true) {
				case e.type == HTTPStatusEvent.HTTP_STATUS:
					text = String((e as HTTPStatusEvent).status);
					if (text == "200" || (request.url.indexOf('file:///') == 0 && text == "0")) {
						return;
					}
					break;
				case (e is ErrorEvent):
					text = (e as ErrorEvent).text;
					break;
				}
				onOver();
				if (error != null) {
					error(e.type, text);
				}
			};
			var onComplete:Function = function(e:Event):void {
				onOver();
				var data:* = loader.data;
				if (json) {
					try {
						data = JSON.parse(loader.data as String);
					} catch (err:Error) {
						if (error != null) {
							error("JSONParseError", err.message);
						}
						return;
					}
				}
				complete(data);
			};
			var onOver:Function = function():void {
				if (progress != null) {
					loader.removeEventListener(ProgressEvent.PROGRESS, progress);
				}
				loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
				loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onError);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
				loader.removeEventListener(Event.COMPLETE, onComplete);
				try {
					loader.close();
				} catch (e:Error) {}
				_numRuns--;
				step();
			};
			if (progress != null) {
				loader.addEventListener(ProgressEvent.PROGRESS, progress);
			}
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onError);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			try {
				loader.load(request);
			} catch (e:Error) {
				onError(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
			}
		}
		
		private static function loadImage(request:URLRequest, complete:Function, error:Function = null, progress:Function = null):void
		{
			var loader:Loader = new Loader();
			var onError:Function = function(e:Event):void {
				var text:String = "";
				switch (true) {
				case e.type == HTTPStatusEvent.HTTP_STATUS:
					text = String((e as HTTPStatusEvent).status);
					if (text == "200" || (request.url.indexOf('file:///') == 0 && text == "0")) {
						return;
					}
					break;
				case (e is ErrorEvent):
					text = (e as ErrorEvent).text;
					break;
				}
				onOver();
				if (error != null) {
					error(e.type, text);
				}
			};
			var onComplete:Function = function(e:Event):void {
				var bmp:BitmapData = new BitmapData(1,1);
				try {
					bmp.draw(loader);
				} catch (e:Error) {
					loader.loadBytes(loader.contentLoaderInfo.bytes);
					return;
				}
				onOver();
				bmp = new BitmapData(loader.width, loader.height, true, 0xFFFFFF);
				bmp.draw(loader);
				complete(bmp, loader.contentLoaderInfo.bytes.length);
			};
			var onOver:Function = function():void {
				if (progress != null) {
					loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, progress);
				}
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError);
				loader.contentLoaderInfo.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onError);
				loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onComplete);
				try {
					loader.close();
				} catch (e:Error) {}
				_numRuns--;
				step();
			};
			if (progress != null) {
				loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progress);
			}
			loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, onError);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
			try {
				loader.load(request);
			} catch (e:Error) {
				onError(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message));
			}
		}
	}
}