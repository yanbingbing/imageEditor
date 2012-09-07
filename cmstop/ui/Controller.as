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
package cmstop.ui {
	
	import cmstop.FocusManager;
	import cmstop.events.ImageEvent;
	
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	
	public class Controller extends Sprite {
		
		private const PI_1_8:Number = Math.tan(Math.PI / 8);
		private const PI_3_8:Number = Math.tan(Math.PI * 3 / 8);
		private const MIN_SIZE:Number = 15;
		private const ANGLES:Object = {
			RESIZE_E  : 0,
			RESIZE_NE : 45,
			RESIZE_N  : 90,
			RESIZE_NW : 135,
			RESIZE_W  : 180,
			RESIZE_SW : -135,
			RESIZE_S  : -90,
			RESIZE_SE : -45
		};
		private var _area:Sprite;
		private var _areaMove:Sprite;
		private var _areaResizeNW:Sprite;
		private var _areaResizeSW:Sprite;
		private var _areaResizeNE:Sprite;
		private var _areaResizeSE:Sprite;
		private var _areaResizeN:Sprite;
		private var _areaResizeW:Sprite;
		private var _areaResizeS:Sprite;
		private var _areaResizeE:Sprite;
		private var _areaRotateNW:Sprite;
		private var _areaRotateSW:Sprite;
		private var _areaRotateNE:Sprite;
		private var _areaRotateSE:Sprite;
		
		private var _canvas:Canvas;
		private var _scale:Number;
		private var _layer:Sprite;
		private var _decorate:Sprite;
		private var _state:String = null;
		private var _draging:Boolean = false;
		private var _startPoint:Point;
		private var _startRotation:Number;
		private var _origin:Point;
		private var _origRectangle:Rectangle;
		private var _origRotation:Number;
		private var _ratio:Number = 0;
		private var _actionLocked:Boolean = false;
		private var _backCursor:String = '';
		private var _dragFunc:Function;
		
		private var _timer:Timer = new Timer(400, 1);
		
		
		public function Controller(canvas:Canvas, layer:Sprite) {
			_canvas = canvas;
			_scale = _canvas.scale;
			_decorate = layer.getChildAt(0) as Sprite;
			_layer = layer;
			FocusManager.addItem(this, _layer);
			initArea();
			
			_area.x = _layer.x;
			_area.y = _layer.y;
			_area.rotation = _layer.rotation;
			
			setWidth();
			setHeight();
			
			_layer.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, function():void{
				_timer.reset();
			});
		}
		
		public function fixRatio(flag:Boolean = true):void {
			if (flag) {
				_ratio = _areaMove.width / _areaMove.height;
			} else {
				_ratio = 0;
			}
		}
		
		private function createResizer(x:Number, y:Number, name:String):Sprite {
			var handle:Sprite = new Sprite();
			handle.graphics.beginFill(0xFFFFFF);
			handle.graphics.lineStyle(0, 0x0099FF);
			handle.graphics.moveTo(-4, -4);
			handle.graphics.lineTo(4, -4);
			handle.graphics.lineTo(4, 4);
			handle.graphics.lineTo(-4, 4);
			handle.graphics.lineTo(-4, -4);
			handle.graphics.endFill();
			_area.addChild(handle);
			handle.x = x;
			handle.y = y;
			handle.name = name;
			return handle;
		}
		
		private function createRotater(x:Number, y:Number, name:String):Sprite {
			var handle:Sprite = new Sprite();
			handle.graphics.beginFill(0, 0);
			handle.graphics.drawRect(-15, -15, 30, 30);
			handle.graphics.endFill();
			_area.addChild(handle);
			handle.x = x;
			handle.y = y;
			handle.name = name;
			return handle;
		}
		
		private function initArea():void {
			_area = new Sprite();
			addChild(_area);
			
			_areaRotateNW = createRotater(-150, -150, 'ROTATE_NW');
			_areaRotateNE = createRotater(150, -150, 'ROTATE_NE');
			_areaRotateSW = createRotater(-150, 150, 'ROTATE_SW');
			_areaRotateSE = createRotater(150, 150, 'ROTATE_SE');
			
			_areaMove = new Sprite();
			_areaMove.graphics.beginFill(0xFFFFFF, 0);
			_areaMove.graphics.lineStyle(0, 0x0099FF, 1, false, LineScaleMode.NONE, CapsStyle.NONE);
			_areaMove.graphics.moveTo(-150, -150);
			_areaMove.graphics.lineTo(-150, 150);
			_areaMove.graphics.lineTo(150, 150);
			_areaMove.graphics.lineTo(150, -150);
			_areaMove.graphics.lineTo(-150, -150);
			_areaMove.graphics.endFill();
			_area.addChild(_areaMove);
			_areaMove.x = 0;
			_areaMove.y = 0;
			_areaMove.name = 'MOVE';
			
			
			_areaResizeN = createResizer(0, -150, 'RESIZE_N');
			_areaResizeW = createResizer(-150, 0, 'RESIZE_W');
			_areaResizeS = createResizer(0, 150, 'RESIZE_S');
			_areaResizeE = createResizer(150, 0, 'RESIZE_E');
			_areaResizeNW = createResizer(-150, -150, 'RESIZE_NW');
			_areaResizeNE = createResizer(150, -150, 'RESIZE_NE');
			_areaResizeSW = createResizer(-150, 150, 'RESIZE_SW');
			_areaResizeSE = createResizer(150, 150, 'RESIZE_SE');
			
			_area.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			_area.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			_area.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			_area.addEventListener(MouseEvent.ROLL_OUT, rollOut);
			
		}
		
		private function mouseOver(e:MouseEvent):void {
			if (_actionLocked) {
				_backCursor = e.target.name;
				return;
			}
			Cursor.setCursor(getCursor(e.target.name));
		}
		
		private function mouseOut(e:MouseEvent):void {
			if (_actionLocked) {
				_backCursor = '';
				return;
			}
		}
		
		private function rollOut(e:MouseEvent):void {
			if (_actionLocked) {
				_backCursor = '';
				return;
			}
			Cursor.reset();
		}
		
		private function mouseDown(e:MouseEvent):void {
			if (_timer.running) {
				_timer.reset();
				dispatchEvent(new ImageEvent(ImageEvent.DOUBLE_CLICK));
				e.updateAfterEvent();
				return;
			} else {
				_timer.start();
			}
			FocusManager.focus(this);
			this.visible = true;
			_actionLocked = true;
			_startPoint = new Point(e.stageX, e.stageY);
			_origRectangle = new Rectangle(_area.x, _area.y, _areaMove.width, _areaMove.height);
			_origin = new Point(_area.x, _area.y);
			_startRotation = getDegree(this.globalToLocal(_startPoint), _origin);
			_origRotation = _area.rotation;
			_state = e.target.name;
			switch (true) {
			case _state == 'MOVE':
				_dragFunc = dragMove;
				break;
			case _state.substr(0, 6) == 'ROTATE':
				_dragFunc = dragRotate;
				break;
			case _state.substr(0, 6) == 'RESIZE':
				_dragFunc = _ratio ? dragResizeRatio : dragResize;
				break;
			default:
				_state = 'MOVE';
				_dragFunc = dragMove;
				Cursor.setCursor(_state);
				break;
			}
			_backCursor = _state;
			root.stage.addEventListener(MouseEvent.MOUSE_MOVE, _dragFunc);
			root.stage.addEventListener(MouseEvent.MOUSE_UP, dragEnd);
		}
		
		private function getCursor(name:String):String {
			if (name.substr(0, 6) != 'RESIZE') {
				return name;
			}
			var a:Number = (ANGLES[name] - _area.rotation) % 180;
			if (a == 0) {
				return 'RESIZE_W';
			}
			if (a % 90 == 0) {
				return 'RESIZE_N';
			}
			var tan:Number = Math.tan(Math.PI * a / 180);
			switch (true) {
			case tan > PI_3_8 || tan < -PI_3_8: name = 'RESIZE_N'; break;
			case tan > -PI_1_8 && tan < PI_1_8: name = 'RESIZE_W'; break;
			case tan >= PI_1_8 && tan <= PI_3_8: name = 'RESIZE_SW'; break;
			case tan >= -PI_3_8 && tan <= -PI_1_8: name = 'RESIZE_SE'; break;
			}
			return name;
		}
		
		private function dragStart():void {
			_draging = true;
			dispatchEvent(new ImageEvent(ImageEvent.DRAG_START));
		}
		
		
		private function dragMove(e:MouseEvent):void {
			_draging || dragStart();
			setLeft(_origRectangle.left + e.stageX - _startPoint.x);
			setTop(_origRectangle.top + e.stageY - _startPoint.y);
		}
		
		private function dragRotate(e:MouseEvent):void {
			_draging || dragStart();
			setRotation(_origRotation + getDegree(new Point(mouseX, mouseY), _origin) - _startRotation);
		}
		
		private function dragResize(e:MouseEvent):void {
			_draging || dragStart();
			var nlPoint:Point = _area.globalToLocal(new Point(e.stageX, e.stageY));
			var slPoint:Point = _area.globalToLocal(_startPoint);
			var nH:Number = _origRectangle.height;
			var nW:Number = _origRectangle.width;
			var minsize:Number = MIN_SIZE * _scale;
			if (_state.lastIndexOf('S') > 6) {
				nH += (nlPoint.y - slPoint.y) * 2;
				if (nH < minsize) {
					nH = minsize;
				}
				setHeight(nH);
			} else if (_state.lastIndexOf('N') > 6) {
				nH += (slPoint.y - nlPoint.y) * 2;
				if (nH < minsize) {
					nH = minsize;
				}
				setHeight(nH);
			}
			if (_state.lastIndexOf('W') > 6) {
				nW += (slPoint.x - nlPoint.x) * 2;
				if (nW < minsize) {
					nW = minsize;
				}
				setWidth(nW);
			} else if (_state.lastIndexOf('E') > 6) {
				nW += (nlPoint.x - slPoint.x) * 2;
				if (nW < minsize) {
					nW = minsize;
				}
				setWidth(nW);
			}
		}
		
		private function dragResizeRatio(e:MouseEvent):void {
			_draging || dragStart();
			var nlPoint:Point = _area.globalToLocal(new Point(e.stageX, e.stageY));
			var slPoint:Point = _area.globalToLocal(_startPoint);
			var nH:Number = _origRectangle.height;
			var nW:Number = _origRectangle.width;
			if (_state.lastIndexOf('S') > 6) {
				nH += (nlPoint.y - slPoint.y) * 2;
				nW = nH * _ratio;
			} else if (_state.lastIndexOf('N') > 6) {
				nH += (slPoint.y - nlPoint.y) * 2;
				nW = nH * _ratio;
			} else if (_state.lastIndexOf('W') > 6) {
				nW += (slPoint.x - nlPoint.x) * 2;
				nH = nW / _ratio;
			} else if (_state.lastIndexOf('E') > 6) {
				nW += (nlPoint.x - slPoint.x) * 2;
				nH = nW / _ratio;
			}
			
			var minsize:Number = MIN_SIZE * _scale;
			if (_ratio > 1) {
				if (nH < minsize) {
					nH = minsize;
					nW = minsize * _ratio;
				}
			} else {
				if (nW < minsize) {
					nW = minsize;
					nH = minsize / _ratio;
				}
			}
			
			setHeight(nH);
			setWidth(nW);
		}
		
		private function getDegree(p:Point, o:Point):Number {
			var l:Number = Math.sqrt(Math.pow(o.y - p.y, 2) + Math.pow(p.x - o.x, 2));
			var cos:Number = p.x - o.x;
			var sin:Number = p.y - o.y;
			var d:Number = Math.asin(sin/l) * 180 / Math.PI;
			if (cos < 0) {
				d =  - d + (sin > 0 ? 180 : (-180));
			}
			return d;
		}
		
		private function dragEnd(e:MouseEvent):void {
			if (_dragFunc != null) {
				root.stage.removeEventListener(MouseEvent.MOUSE_MOVE, _dragFunc);
				_dragFunc = null;
			}
			root.stage.removeEventListener(MouseEvent.MOUSE_UP, dragEnd);
			_actionLocked = false;
			if (_backCursor) {
				Cursor.setCursor(getCursor(_backCursor));
			} else {
				Cursor.reset();
			}
			_state = '';
			if (_draging) {
				_draging = false;
				dispatchEvent(new ImageEvent(ImageEvent.DRAG_END));
			}
		}
		
		private function setTop(top:Number):void {
			_area.y = top;
			_layer.y = top;
		}
		
		private function setLeft(left:Number):void {
			_area.x = left;
			_layer.x = left;
		}
		
		public function setRotation(rotate:Number):void {
			var o:Number = _area.rotation;
			rotate = Math.round(rotate);
			_area.rotation = rotate;
			_layer.rotation = rotate;
			if (o != _area.rotation) {
				dispatchEvent(new ImageEvent(ImageEvent.ROTATE_CHANGE, _area.rotation));
			}
		}
		
		private function setHeight(height:Number = 0):void {
			if (height <= 0) {
				height = _decorate.height;
			} else {
				_decorate.height = height;
			}
			var halfH:Number = height / 2;
			_areaMove.height = height;
			_areaResizeNW.y = -halfH;
			_areaResizeNE.y = -halfH;
			_areaResizeSE.y = halfH;
			_areaResizeSW.y = halfH;
			
			_areaRotateNW.y = -halfH;
			_areaRotateNE.y = -halfH;
			_areaRotateSE.y = halfH;
			_areaRotateSW.y = halfH;
			
			_areaResizeN.y = -halfH;
			_areaResizeS.y = halfH;
		}
		
		private function setWidth(width:Number = 0):void {
			if (width <= 0) {
				width = _decorate.width;
			} else {
				_decorate.width = width;
			}
			var halfW:Number = width / 2;
			_areaMove.width = width;
			_areaResizeNW.x = -halfW;
			_areaResizeNE.x = halfW;
			_areaResizeSE.x = halfW;
			_areaResizeSW.x = -halfW;
			_areaRotateNW.x = -halfW;
			_areaRotateNE.x = halfW;
			_areaRotateSE.x = halfW;
			_areaRotateSW.x = -halfW;
			_areaResizeE.x = halfW;
			_areaResizeW.x = -halfW;
		}
		
		
		public function updateScale():void {
			var ns:Number = _canvas.scale / _scale;
			_scale = _canvas.scale;
			setLeft(_area.x * ns);
			setTop(_area.y * ns);
			setHeight(_areaMove.height * ns);
			setWidth(_areaMove.width * ns);
			dispatchEvent(new ImageEvent(ImageEvent.SCALE_CHANGE, _scale));
		}
		
		public function updateLayer():void {
			_area.rotation = _layer.rotation;
			setWidth();
			setHeight();
			if (_ratio) {
				fixRatio(true);
			}
		}
		public function get layer():Sprite {
			return _layer;
		}
		
		public function setVisible(value:Boolean):void {
			_area.visible = value;
			_layer.visible = value;
		}
		
		public function setPosition(left:Number, top:Number):void {
			setLeft(left * _scale);
			setTop(top * _scale);
		}
		
		override public function get rotation():Number {
			return _layer.rotation;
		}
		
		public function set rect(v:Rectangle):void {
			setLeft(v.x);
			setTop(v.y);
			setWidth(v.width);
			setHeight(v.height);
		}
		
		public function get rect():Rectangle {
			return new Rectangle(_area.x, _area.y, _areaMove.width, _areaMove.height);
		}
	}
}
