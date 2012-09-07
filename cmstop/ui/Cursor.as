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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.ui.MouseCursorData;
	
	
	public class Cursor extends Object
	{
		[Embed (source="/assets/mouse/move.png")]
		private static const MOVE:Class;
		[Embed (source="/assets/mouse/resize-n.png")]
		private static const RESIZE_N:Class;
		[Embed (source="/assets/mouse/resize-w.png")]
		private static const RESIZE_W:Class;
		[Embed (source="/assets/mouse/resize-se.png")]
		private static const RESIZE_SE:Class;
		[Embed (source="/assets/mouse/resize-sw.png")]
		private static const RESIZE_SW:Class;
		[Embed (source="/assets/mouse/rotate.png")]
		private static const ROTATE:Class;
		[Embed (source="/assets/mouse/text.png")]
		private static const TEXT:Class;
		
		private static var _inited:Object = new Object();
		
		public function Cursor()
		{
			return;
		}
		private static function initCursor(name:String):void {
			if (_inited[name]) {
				return;
			}
			_inited[name] = true;
			
			var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>(1, true);
			var bitmap:Bitmap = new Cursor[name]();
			bitmapDatas[0] = bitmap.bitmapData;
			var cursorData:MouseCursorData = new MouseCursorData();
			cursorData.hotSpot = new Point(bitmap.width/2, bitmap.height/2);
			cursorData.data = bitmapDatas;
			Mouse.registerCursor(name, cursorData);
		}
		public static function setCursor(name:String):void {
			switch(name){
			case 'RESIZE_S': name = 'RESIZE_N'; break;
			case 'RESIZE_E': name = 'RESIZE_W'; break;
			case 'RESIZE_NE': name = 'RESIZE_SW'; break;
			case 'RESIZE_NW': name = 'RESIZE_SE'; break;
			case 'ROTATE_NW':case 'ROTATE_NE':case 'ROTATE_SW':case 'ROTATE_SE':
				name = 'ROTATE'; break;
			}
			if (name == Mouse.cursor) {
				return;
			}
			initCursor(name);
			Mouse.cursor = name;
		}
		public static function getCursor():String {
			return Mouse.cursor;
		}
		public static function reset():void {
			Mouse.cursor = MouseCursor.AUTO;
		}
	}
}