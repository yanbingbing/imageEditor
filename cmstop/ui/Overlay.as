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
	import cmstop.Global;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	
	public class Overlay extends Sprite 
	{
		protected var _container:CanvasContainer;
		protected var _canvas:Canvas;
		protected var _controlay:Sprite;
		protected var _controller:Controller = null;
		protected var _layer:Sprite = null;
		protected var _panel:ControlPanel;
		protected var _params:Object = new Object();
		
		public static function add(overlay:Overlay, container:CanvasContainer, panel:ControlPanel, pos:Point = null):void {
			var canvas:Canvas = container.canvas;
			var overlayContainer:Sprite = canvas.overlayContainer;
			var controlay:Sprite = container.controlay;
			if (pos == null) {
				pos = container.center;
			}
			pos = overlayContainer.globalToLocal(pos);
			var s:Sprite = new Sprite();
			s.addChild(overlay);
			overlay.x = -overlay.width / 2;
			overlay.y = -overlay.height / 2;
			s.height = overlay.height * canvas.scale;
			s.width = overlay.width * canvas.scale;
			var layer:Sprite = new Sprite();
			layer.addChild(s);
			overlayContainer.addChild(layer);
			layer.x = pos.x;
			layer.y = pos.y;
			layer.addEventListener(MouseEvent.MOUSE_DOWN, function():void {
				Global.editor.focusTab(panel.panelName);
				panel.assoc(overlay);
			});
			
			var controller:Controller = new Controller(canvas, layer);
			controlay.addChild(controller);
			canvas.addEventListener(ImageEvent.SCALE_CHANGE, function():void {
				controller.updateScale();
			});
			overlay.addEventListener(ImageEvent.PROP_CHANGE, function(e:ImageEvent):void {
				if (e.data == "deleted") {
					controlay.removeChild(controller);
					overlayContainer.removeChild(layer);
				} else {
					if (e.data == "added") {
						controlay.addChild(controller);
						overlayContainer.addChild(layer);
					}
					overlay.x = -overlay.width / 2;
					overlay.y = -overlay.height / 2;
					controller.updateLayer();
				}
			});
			controller.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) {
				if (e.keyCode == 46) { // delete
					controlay.removeChild(controller);
					overlayContainer.removeChild(layer);
					container.log('OverlayDelete', controller, layer, controller.rect, canvas.scale);
				}
			});
			var start:Array = null;
			controller.addEventListener(ImageEvent.DRAG_START, function() {
				start = [controller.rect, controller.rotation];
			});
			controller.addEventListener(ImageEvent.DRAG_END, function() {
				if (start != null) {
					container.log('OverlayDrag', controller, start, [controller.rect, controller.rotation], canvas.scale);
					start = null;
				}
			});
			overlay.assoc(controller, layer);
			panel.assoc(overlay, true);
		}
		
		public function Overlay(container:CanvasContainer, panel:ControlPanel) 
		{
			_container = container;
			_canvas = _container.canvas;
			_controlay = _container.controlay;
			_panel = panel;
		}
		public function assoc(controller:Controller, layer:Sprite):void {
			_controller = controller;
			_layer = layer;
		}
		public function get controller():Controller {
			return _controller;
		}
		/**
		 * internal for log use
		 */
		public function setParamWithAync(key:String, value:*):void {
			setParam(key, value);
			_panel.overlay == this && _panel.setParam(key, value);
		}
		public function setParam(key:String, value:*):void {
			this[key] = value;
			this.update();
		}
		public function set params(params:Object):void {
			for (var key:String in _params) {
				this[key] = params[key];
			}
			this.update();
		}
		public function get params():Object {
			return _params;
		}
		protected function update():void {
			
		}
	}
}