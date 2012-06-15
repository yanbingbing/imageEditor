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
	import cmstop.Global;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.*;
	import flash.geom.Matrix;
	
	public class RotateControlPanel extends ControlPanel 
	{
		private var _container:CanvasContainer;
		public function RotateControlPanel(width:Number = 210) 
		{
			super(width);
			_container = Global.container;
		}
		override protected function init(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			var forward:Button = createButton("顺旋90");
			var backward:Button = createButton("逆旋90");
			var vertical:Button = createButton("上下翻转");
			var horizontal:Button = createButton("左右翻转");
			
			addChild(forward);
			addChild(backward);
			addChild(horizontal);
			addChild(vertical);
			var dx:Number = (_width - forward.width) / 2;
			forward.x = dx;
			backward.x = dx;
			horizontal.x = dx;
			vertical.x = dx;
			forward.y = 20;
			backward.y = 55;
			horizontal.y = 90;
			vertical.y = 125;
			forward.addEventListener(MouseEvent.CLICK, function():void {
				var bmpData:BitmapData = _container.newBitmapData;
				var newbmpData:BitmapData = new BitmapData(bmpData.height, bmpData.width, true, 0xFFFFFF);
				var mx:Matrix = new Matrix();
				mx.rotate(Math.PI / 2);
				mx.tx = bmpData.height;
				newbmpData.draw(bmpData, mx);
				_container.bitmapData = newbmpData;
			});
			backward.addEventListener(MouseEvent.CLICK, function():void {
				var bmpData:BitmapData = _container.newBitmapData;
				var newbmpData:BitmapData = new BitmapData(bmpData.height, bmpData.width, true, 0xFFFFFF);
				var mx:Matrix = new Matrix();
				mx.rotate(-Math.PI / 2);
				mx.ty = bmpData.width;
				newbmpData.draw(bmpData, mx);
				_container.bitmapData = newbmpData;
			});
			horizontal.addEventListener(MouseEvent.CLICK, function():void {
				var bmpData:BitmapData = _container.newBitmapData;
				var newbmpData:BitmapData = new BitmapData(bmpData.width, bmpData.height);
				newbmpData.draw(bmpData, new Matrix( -1, 0, 0, 1, bmpData.width, 0));
				_container.bitmapData = newbmpData;
			});
			vertical.addEventListener(MouseEvent.CLICK, function():void {
				var bmpData:BitmapData = _container.newBitmapData;
				var newbmpData:BitmapData = new BitmapData(bmpData.width, bmpData.height);
				newbmpData.draw(bmpData, new Matrix( 1, 0, 0, -1, 0, bmpData.height));
				_container.bitmapData = newbmpData;
			});
		}
	}

}