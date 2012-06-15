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
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	public class Water extends Overlay 
	{
		public function Water(bitmapData:BitmapData, container:CanvasContainer, panel:ControlPanel, alpha:Number = -1) 
		{
			super(container, panel);
			addChild(new Bitmap(bitmapData));
			if (alpha >= 0 && alpha <=1) {
				panel.setParam('waterAlpha', alpha);
			}
			_params = {
				waterAlpha:1,
				waterAngle:0
			};
		}
		
		override public function assoc(controller:Controller, layer:Sprite):void {
			super.assoc(controller, layer);
			_controller.fixRatio();
			_controller.addEventListener(ImageEvent.ROTATE_CHANGE, rotateChange);
			_container.log('OverlayAdd', controller, layer, _controller.rect, _canvas.scale);
		}
		
		private function rotateChange(e:ImageEvent):void {
			_params.waterAngle = _layer.rotation;
			_panel.overlay == this && _panel.setParam("waterAngle", _layer.rotation);
		}
		
		override protected function update():void {
			this.alpha = _params.waterAlpha;
			_layer.rotation = _params.waterAngle;
			dispatchEvent(new ImageEvent(ImageEvent.PROP_CHANGE));
		}
		public function setPosition(pos:uint):void {
			if (pos > 8) return;
			var h:Number = (_controller.height - 8) / _canvas.scale;
			var w:Number = (_controller.width - 8) / _canvas.scale;
			var l:Number, t:Number;
			switch (pos % 3) {
			case 0:
				l = w / 2;
				break;
			case 2:
				l = _canvas.bmpWidth - w / 2;
				break;
			case 1:default:
				l = _canvas.bmpWidth / 2;
				break;
			}
			switch(Math.floor(pos / 3)) {
			case 0:
				t = h / 2;
				break;
			case 2:
				t = _canvas.bmpHeight - h / 2;
				break;
			case 1:default:
				t = _canvas.bmpHeight / 2;
				break;
			}
			_controller.setPosition(l, t);
		}
		public function set waterAlpha(value:*):void {
			_params.waterAlpha = value == null ? 1 : Number(value);
		}
		public function set waterAngle(value:*):void {
			_params.waterAngle = value == null ? 0 : Number(value);
		}
	}
}