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
package cmstop.ui
{
	import cmstop.events.ImageEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	
	public class Canvas extends Sprite 
	{
		private var _bmpData:BitmapData;
		private var _picture:Bitmap;
		private var _overlayContainer:Sprite;
		private var _scale:Number;
		
		public function Canvas(bitmapData:BitmapData = null)
		{
			_bmpData = bitmapData;
			_picture = new Bitmap(bitmapData);
			_overlayContainer = new Sprite();
			addChild(_picture);
			addChild(_overlayContainer);
		}
		
		public function hasCapture(e:MouseEvent):Boolean {
			return !_overlayContainer.contains(e.target as DisplayObject);
		}
		
		public function set scale(scale:Number):void {
			_scale = scale;
			_picture.width = _bmpData.width * scale;
			_picture.height = _bmpData.height * scale;
			dispatchEvent(new ImageEvent(ImageEvent.SCALE_CHANGE));
		}
		
		public function get scale():Number {
			return _scale;
		}
		
		public function get bmpWidth():Number {
			return _bmpData.width;
		}
		
		public function get bmpHeight():Number {
			return _bmpData.height;
		}
		
		public function get overlayContainer():Sprite {
			return _overlayContainer;
		}
		
		public function get bitmapData():BitmapData {
			return _bmpData;
		}
		
		public function set bitmapData(bitmapData:BitmapData):void {
			_bmpData = bitmapData;
			_picture.bitmapData = bitmapData;
		}
	}

}