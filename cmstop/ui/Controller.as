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
	
	import cmstop.events.ImageEvent;
	import cmstop.FocusManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	
	public class Controller extends MovieClip {
		
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
		public var area:MovieClip;
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
			addEventListener(Event.ADDED_TO_STAGE, init);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, function():void{
				_timer.reset();
			});
		}
		
		public function fixRatio(flag:Boolean = true):void {
			if (flag) {
				_ratio = area.MOVE.width / area.MOVE.height;
			} else {
				_ratio = 0;
			}
		}
		
		private function init(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			area.x = _layer.x;
			area.y = _layer.y;
			area.rotation = _layer.rotation;
			
			setWidth();
			setHeight();
			
			area.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			_layer.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			area.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			area.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			area.addEventListener(MouseEvent.ROLL_OUT, rollOut);
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
			_origRectangle = new Rectangle(area.x, area.y, area.MOVE.width, area.MOVE.height);
			_origin = new Point(area.x, area.y);
			_startRotation = getDegree(this.globalToLocal(_startPoint), _origin);
			_origRotation = area.rotation;
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
			var a:Number = (ANGLES[name] - area.rotation) % 180;
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
			var nlPoint:Point = area.globalToLocal(new Point(e.stageX, e.stageY));
			var slPoint:Point = area.globalToLocal(_startPoint);
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
			var nlPoint:Point = area.globalToLocal(new Point(e.stageX, e.stageY));
			var slPoint:Point = area.globalToLocal(_startPoint);
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
			area.y = top;
			_layer.y = top;
		}
		
		private function setLeft(left:Number):void {
			area.x = left;
			_layer.x = left;
		}
		
		public function setRotation(rotate:Number):void {
			var o:Number = area.rotation;
			rotate = Math.round(rotate);
			area.rotation = rotate;
			_layer.rotation = rotate;
			if (o != area.rotation) {
				dispatchEvent(new ImageEvent(ImageEvent.ROTATE_CHANGE, area.rotation));
			}
		}
		
		private function setHeight(height:Number = 0):void {
			if (height <= 0) {
				height = _decorate.height;
			} else {
				_decorate.height = height;
			}
			var halfH:Number = height / 2;
			area.MOVE.height = height;
			area.RESIZE_NW.y = -halfH;
			area.RESIZE_NE.y = -halfH;
			area.RESIZE_SE.y = halfH;
			area.RESIZE_SW.y = halfH;
			area.ROTATE_NW.y = -halfH;
			area.ROTATE_NE.y = -halfH;
			area.ROTATE_SE.y = halfH;
			area.ROTATE_SW.y = halfH;
			area.RESIZE_N.y = -halfH;
			area.RESIZE_S.y = halfH;
		}
		
		private function setWidth(width:Number = 0):void {
			if (width <= 0) {
				width = _decorate.width;
			} else {
				_decorate.width = width;
			}
			var halfW:Number = width / 2;
			area.MOVE.width = width;
			area.RESIZE_NW.x = -halfW;
			area.RESIZE_NE.x = halfW;
			area.RESIZE_SE.x = halfW;
			area.RESIZE_SW.x = -halfW;
			area.ROTATE_NW.x = -halfW;
			area.ROTATE_NE.x = halfW;
			area.ROTATE_SE.x = halfW;
			area.ROTATE_SW.x = -halfW;
			area.RESIZE_E.x = halfW;
			area.RESIZE_W.x = -halfW;
		}
		
		
		public function updateScale():void {
			var ns:Number = _canvas.scale / _scale;
			_scale = _canvas.scale;
			setLeft(area.x * ns);
			setTop(area.y * ns);
			setHeight(area.MOVE.height * ns);
			setWidth(area.MOVE.width * ns);
			dispatchEvent(new ImageEvent(ImageEvent.SCALE_CHANGE, _scale));
		}
		
		public function updateLayer():void {
			area.rotation = _layer.rotation;
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
			area.visible = value;
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
			return new Rectangle(area.x, area.y, area.MOVE.width, area.MOVE.height);
		}
	}
}
