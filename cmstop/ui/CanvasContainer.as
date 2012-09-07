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
	import cmstop.XLoader;
	import cmstop.events.ImageEvent;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	public class CanvasContainer extends Sprite 
	{
		[Embed (source="/assets/background.png")]
		private const BACKGROUND:Class;
		private const MAX_SCALE:uint = 4;
		private var _bgbmpData:BitmapData;
		private var _bg:Sprite = new Sprite();
		private var _canvas:Canvas = null;
		private var _controlay:Sprite = new Sprite();
		private var _crop:Cropper = null;
		private var _container:Sprite = new Sprite();
		private var _stageWidth:Number = 0;
		private var _stageHeight:Number = 0;
		private var _picInited:Boolean = false;
		private var _focusPoint:Point;
		private var _minScale:Number = 1;
		private var _moveLock:Boolean = false;
		private var _clickPoint:Point;
		private var _clickPos:Point;
		private var _bytes:uint = 0;
		
		public function CanvasContainer(width:Number = 400, height:Number = 400) 
		{
			var bmp:Bitmap = new BACKGROUND() as Bitmap;
			_bgbmpData = bmp.bitmapData;
			addChild(_bg);
			setSize(width, height);
			addChild(_container);
			addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
		}
		
		public function inDrag():Boolean {
			return _moveLock;
		}
		
		public function canMove():Boolean {
			return _container.width > _stageWidth || _container.height > _stageHeight;
		}
		
		private function mouseDown(e:MouseEvent):void {
			if ((_container.width <= _stageWidth && _container.height <= _stageHeight)
				|| !_canvas.hasCapture(e))
			{
				return;
			}
			_clickPoint = new Point(e.stageX, e.stageY);
			_clickPos = new Point(_container.x, _container.y);
			root.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			root.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		private function mouseMove(e:MouseEvent):void {
			if (!_moveLock) {
				if (Math.pow(e.stageX - _clickPoint.x, 2) + Math.pow(e.stageY - _clickPoint.y, 2) < 25) {
					return;
				}
				_moveLock = true;
				Mouse.cursor = MouseCursor.HAND;
			}
			if (_container.width > _stageWidth) {
				setLeft(_clickPos.x + e.stageX - _clickPoint.x, _container.width);
			}
			if (_container.height > _stageHeight) {
				setTop(_clickPos.y + e.stageY - _clickPoint.y, _container.height);
			}
		}
		
		private function mouseUp(e:MouseEvent):void {
			root.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			root.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if (Mouse.cursor == MouseCursor.HAND) {
				Mouse.cursor = MouseCursor.AUTO;
			}
			_moveLock = false;
		}
		
		private function setTop(top:Number, height:Number):void {
			if (top > 0 ) {
				top = 0;
			} else if (top + height < _stageHeight) {
				top = _stageHeight - height;
			}
			_container.y = top;
		}
		
		private function setLeft(left:Number, width:Number):void {
			if (left > 0 ) {
				left = 0;
			} else if (left + width < _stageWidth) {
				left = _stageWidth - width;
			}
			_container.x = left;
		}
		
		public function setSize(width:Number, height:Number):void {
			_bg.graphics.clear();
			_bg.graphics.beginBitmapFill(_bgbmpData);
			_bg.graphics.drawRect(0, 0, width, height);
			_bg.graphics.endFill();
			_stageWidth = width;
			_stageHeight = height;
			this.scrollRect = new Rectangle(0, 0, width, height);
			_focusPoint = new Point(width/2, height/2);
			if (_picInited) {
				setMinScale();
			}
		}
		
		public function loadPicture(url:String):void {
			_picInited = false;
			MsgBox.getInstance(stage).loading("图片加载中");
			
			XLoader.load(XLoader.IMAGE, new URLRequest(url), function(bmp:BitmapData, bytes:uint):void {
				MsgBox.getInstance(stage).hide();
				if (_canvas != null) {
					_canvas.bitmapData = bmp;
				} else {
					_canvas = new Canvas(bmp);
					_container.addChild(_canvas);
					_container.addChild(_controlay);
					_canvas.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				}
				_bytes = bytes;
				_picInited = true;
				setMinScale();
				dispatchEvent(new ImageEvent(ImageEvent.CANVAS_INITED));
			}, function(type:String, text:String):void {
				MsgBox.getInstance(stage).tip("图片不可用["+type+":"+text+"]");
			});
		}
		
		private function setMinScale():void {
			_minScale = 1;
			if (_canvas.bmpHeight / _canvas.bmpWidth > _stageHeight / _stageWidth) {
				if (_canvas.bmpHeight > _stageHeight) {
					_minScale = _stageHeight / _canvas.bmpHeight;
				}
			} else {
				if (_canvas.bmpWidth > _stageWidth) {
					_minScale = _stageWidth / _canvas.bmpWidth;
				}
			}
			setScale(_minScale);
		}
		
		public function showCrop(w:Number = 0, h:Number = 0, r:Number = 0):Cropper {
			if (!_picInited) {
				return null;
			}
			if (!w || !h) {
				w = Math.min(_container.scrollRect.width, _stageWidth) / 2;
				h = Math.min(_container.scrollRect.height, _stageHeight) / 2;
				if (r) {
					if (r > w / h) {
						h = w / r;
					} else if (r < w / h) {
						w = h * r
					}
				}
			}
			var p:Point = this.center;
			p.y = p.y - h / 2;
			p.x = p.x - w / 2;
			p = _controlay.globalToLocal(p);
			var rect:Rectangle = new Rectangle(p.x, p.y, w, h);
			if (_crop != null) {
				_crop.rect = rect;
				_crop.visible = true;
			} else {
				initCrop(rect);
			}
			return _crop;
		}
		
		private function initCrop(rect:Rectangle):void {
			_crop = new Cropper(_canvas, rect);
			_controlay.addChild(_crop);
			addEventListener(ImageEvent.BITMAPDATA_CHANGE, function():void{
				if (_crop.visible) {
					hideCrop();
					var r:Number = _crop.fixRatio(false);
					showCrop();
					r && _crop.fixRatio(true);
				}
			});
			_canvas.addEventListener(ImageEvent.SCALE_CHANGE, function():void {
				_crop.visible && _crop.updateScale();
			});
			_crop.addEventListener(ImageEvent.CROP, applyCrop);
		}
		
		public function applyCrop(e:Event = null):void {
			var clip:Rectangle = _crop.clip;
			_crop.visible = false;
			setScale(1);
			var newbmpData:BitmapData = new BitmapData(Math.floor(clip.width), Math.floor(clip.height), true, 0xFFFFFF);
			var mx:Matrix = new Matrix(1, 0, 0, 1, -clip.x, -clip.y);
			newbmpData.draw(this.newBitmapData, mx);
			bitmapData = newbmpData;
		}
		
		public function hideCrop():void {
			if (_crop != null) {
				_crop.visible = false;
			}
		}
		
		public function get cropVisible():Boolean {
			return _crop.visible;
		}
		
		public function setScale(scale:Number, target:Object = null):void {
			if (scale < _minScale) {
				scale  = _minScale;
			} else if (scale > MAX_SCALE) {
				scale = MAX_SCALE;
			}
			var width:Number = _canvas.bmpWidth * scale;
			var height:Number = _canvas.bmpHeight * scale;
			var origWidth:Number = _container.width;
			var origHeight:Number = _container.height;
			_canvas.scale = scale;
			_container.scrollRect = new Rectangle(0, 0, width, height);
			if (width > _stageWidth) {
				setLeft(_focusPoint.x - (_focusPoint.x - _container.x) * width / origWidth, width);
			} else {
				_container.x = (_stageWidth - width) / 2;
			}
			if (height > _stageHeight) {
				setTop(_focusPoint.y - (_focusPoint.y - _container.y) * height / origHeight, height);
			} else {
				_container.y = (_stageHeight - height) / 2;
			}
			dispatchEvent(new ImageEvent(ImageEvent.SCALE_CHANGE, target));
		}
		
		public function get scale():Number {
			return _canvas.scale;
		}
		
		public function set scale(v:Number):void {
			setScale(v);
		}
		
		public function get minScale():Number {
			return _minScale;
		}
		public function get maxScale():Number {
			return MAX_SCALE;
		}
		public function get canvas():Canvas {
			return _canvas;
		}
		public function get controlay():Sprite {
			return _controlay;
		}
		
		public function get center():Point {
			return localToGlobal(new Point(_stageWidth / 2, _stageHeight / 2));
		}
		
		public function get bitmapData():BitmapData {
			return _canvas.bitmapData;
		}
		
		public function set bitmapData(bitmapData:BitmapData):void {
			var lays:Array = [], i:uint = _controlay.numChildren,
				d:DisplayObject, c:Controller, s:Sprite;
			while (i-- > 0) {
				d = _controlay.getChildAt(i);
				if (d is Controller) {
					c = d as Controller;
					s = c.layer;
					lays.push({ controller:c, layer:s, rect:c.rect });
					_controlay.removeChild(c);
					_canvas.overlayContainer.removeChild(s);
				}
			}
			log('Canvas', _canvas.bitmapData, bitmapData, lays, _canvas.scale);
			setBmpData(bitmapData);
		}
		
		private function setBmpData(bitmapData:BitmapData):void {
			_canvas.scale = 1;
			_canvas.bitmapData = bitmapData;
			setMinScale();
			dispatchEvent(new ImageEvent(ImageEvent.BITMAPDATA_CHANGE));
		}
		
		public function get newBitmapData():BitmapData {
			var o:Number = _canvas.scale;
			setScale(1);
			var bitmapData:BitmapData = new BitmapData(_canvas.bmpWidth, _canvas.bmpHeight, true, 0xFFFFFF);
			bitmapData.draw(_canvas);
			setScale(o);
			return bitmapData;
		}
		
		public function get bytes():uint {
			return _bytes;
		}
		
		private function mouseWheel(e:MouseEvent):void {
			if (!_picInited || _moveLock) {
				return;
			}
			_focusPoint = new Point(mouseX, mouseY);
			setScale(_canvas.scale + (e.delta / 30));
			e.updateAfterEvent();
		}
		
		/**
		 * history function
		 */
		private var _historyData:Object = new Object();
		private var _historyLength:uint = 0;
		private var _historySavePoint:uint = 0;
		private var _historyPoint:uint = 0;
		
		public function log(type:String, ...params):void {
			_historyData[_historyPoint++] = {
				type:type,
				params:params
			};
			_historyLength = _historyPoint;
			dispatchEvent(new ImageEvent(ImageEvent.HISTORY_CHANGE));
		}
		public function undo():void {
			if (!canUndo()) return;
			var point:Object = _historyData[--_historyPoint];
			(this["undo" + point.type] as Function).apply(this, point.params);
			dispatchEvent(new ImageEvent(ImageEvent.HISTORY_CHANGE));
		}
		public function canUndo():Boolean {
			return _historyPoint > 0;
		}
		public function redo():void {
			if (!canRedo()) return;
			var point:Object = _historyData[_historyPoint++];
			(this["redo" + point.type] as Function).apply(this, point.params);
			dispatchEvent(new ImageEvent(ImageEvent.HISTORY_CHANGE));
		}
		public function canRedo():Boolean {
			return _historyPoint < _historyLength;
		}
		public function savePoint():void {
			_historySavePoint = _historyPoint;
		}
		public function hasModified():Boolean {
			return _historySavePoint != _historyPoint;
		}
		private function undoCanvas(origBitmapData:BitmapData, newBitmapData:BitmapData, lays:Array, scale:Number):void {
			var ds:Number = _canvas.scale / scale, rect:Rectangle;
			for (var i:uint = lays.length, o:Object; i-- > 0 && (o = lays[i]);) {
				_controlay.addChild(o.controller);
				_canvas.overlayContainer.addChild(o.layer);
				rect = (o.rect as Rectangle).clone();
				rect.x *= ds;
				rect.y *= ds;
				rect.width *= ds;
				rect.height *= ds;
				o.controller.rect = rect;
			}
			setBmpData(origBitmapData);
		}
		private function redoCanvas(origBitmapData:BitmapData, newBitmapData:BitmapData, lays:Array, scale:Number):void {
			for (var i:uint = lays.length, o:Object; i-- > 0 && (o = lays[i]);) {
				_controlay.removeChild(o.controller);
				_canvas.overlayContainer.removeChild(o.layer);
			}
			setBmpData(newBitmapData);
		}
		private function undoOverlayDrag(controller:Controller, origParams:Array, newParams:Array, scale:Number):void {
			var ds:Number = _canvas.scale / scale;
			var rect:Rectangle = (origParams[0] as Rectangle).clone();
			rect.x *= ds;
			rect.y *= ds;
			rect.width *= ds;
			rect.height *= ds;
			controller.setRotation(origParams[1]);
			controller.rect = rect;
		}
		private function redoOverlayDrag(controller:Controller, origParams:Array, newParams:Array, scale:Number):void {
			var ds:Number = _canvas.scale / scale;
			var rect:Rectangle = (newParams[0] as Rectangle).clone();
			rect.x *= ds;
			rect.y *= ds;
			rect.width *= ds;
			rect.height *= ds;
			controller.setRotation(newParams[1]);
			controller.rect = rect;
		}
		private function undoOverlayDelete(controller:Controller, layer:Sprite, orect:Rectangle, scale:Number):void {
			_controlay.addChild(controller);
			_canvas.overlayContainer.addChild(layer);
			var ds:Number = _canvas.scale / scale;
			var rect:Rectangle = orect.clone();
			rect.x *= ds;
			rect.y *= ds;
			rect.width *= ds;
			rect.height *= ds;
			controller.rect = rect;
		}
		private function redoOverlayDelete(controller:Controller, layer:Sprite, ...rest):void {
			_controlay.removeChild(controller);
			_canvas.overlayContainer.removeChild(layer);
		}
		private function undoOverlayAdd(controller:Controller, layer:Sprite, ...rest):void {
			_controlay.removeChild(controller);
			_canvas.overlayContainer.removeChild(layer);
		}
		private function redoOverlayAdd(controller:Controller, layer:Sprite, orect:Rectangle, scale:Number):void {
			_controlay.addChild(controller);
			_canvas.overlayContainer.addChild(layer);
			var ds:Number = _canvas.scale / scale;
			var rect:Rectangle = orect.clone();
			rect.x *= ds;
			rect.y *= ds;
			rect.width *= ds;
			rect.height *= ds;
			controller.rect = rect;
		}
		private function undoOverlayChange(overlay:Overlay, key:String, oldValue:*, newValue:*):void {
			overlay.setParamWithAync(key, oldValue);
		}
		private function redoOverlayChange(overlay:Overlay, key:String, oldValue:*, newValue:*):void {
			overlay.setParamWithAync(key, newValue);
		}
		private function undoTextChange(controller:Controller, overlay:Text, oldTxt:*, newTxt:*, oldRect:Rectangle, newRect:Rectangle, scale:Number):void {
			overlay.setLogText(oldTxt);
			if (oldTxt.text) {
				var ds:Number = _canvas.scale / scale;
				var rect:Rectangle = oldRect.clone();
				rect.x *= ds;
				rect.y *= ds;
				rect.width *= ds;
				rect.height *= ds;
				controller.rect = rect;
			}
		}
		private function redoTextChange(controller:Controller, overlay:Text, oldTxt:*, newTxt:*, oldRect:Rectangle, newRect:Rectangle, scale:Number):void {
			overlay.setLogText(newTxt);
			if (newTxt.text) {
				var ds:Number = _canvas.scale / scale;
				var rect:Rectangle = newRect.clone();
				rect.x *= ds;
				rect.y *= ds;
				rect.width *= ds;
				rect.height *= ds;
				controller.rect = rect;
			}
		}
		private function undoWaterPosition(controller:Controller, oldRect:Rectangle, newRect:Rectangle, scale:Number):void {
			var ds:Number = _canvas.scale / scale;
			var rect:Rectangle = oldRect.clone();
			rect.x *= ds;
			rect.y *= ds;
			rect.width *= ds;
			rect.height *= ds;
			controller.rect = rect;
		}
		private function redoWaterPosition(controller:Controller, oldRect:Rectangle, newRect:Rectangle, scale:Number):void {
			var ds:Number = _canvas.scale / scale;
			var rect:Rectangle = newRect.clone();
			rect.x *= ds;
			rect.y *= ds;
			rect.width *= ds;
			rect.height *= ds;
			controller.rect = rect;
		}
	}
}