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
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;

	
	public class Cropper extends MovieClip {
		
		private const MIN_SIZE:Number = 20;
		public var overlay:MovieClip;
		public var area:MovieClip;
		private var _canvas:Canvas;
		private var _state:String = '';
		private var _draging:Boolean = false;
		private var _startPoint:Point;
		private var _origRectangle:Rectangle;
		private var _ratio:Number = 0;
		private var _actionLocked:Boolean = false;
		private var _backCursor:String = '';
		private var _dragFunc:Function;
		private var _scale:Number = 1;

		
		public function Cropper(canvas:Canvas, rect:Rectangle) {
			_canvas = canvas;
			_scale = canvas.scale;
			this.rect = rect;
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			overlay.bg.width = _canvas.width;
			overlay.bg.height = _canvas.height;
			area.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			area.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			area.addEventListener(MouseEvent.ROLL_OUT, rollOut);
			area.MOVE.doubleClickEnabled = true;
			area.MOVE.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent):void {
				dispatchEvent(new ImageEvent(ImageEvent.CROP));
			});
		}
		private function mouseOver(e:MouseEvent):void {
			if (_actionLocked) {
				_backCursor = e.target.name;
				return;
			}
			Cursor.setCursor(e.target.name);
		}
		private function rollOut(e:MouseEvent):void {
			if (_actionLocked) {
				_backCursor = '';
				return;
			}
			Cursor.reset();
		}
		private function mouseDown(e:MouseEvent):void {
			e.stopPropagation();
			_backCursor = e.target.name;
			_state = _backCursor;
			_draging = true;
			_actionLocked = true;
			_startPoint = new Point(e.stageX, e.stageY);
			_origRectangle = new Rectangle(area.x, area.y, area.MOVE.width, area.MOVE.height);
			switch (true) {
			case _state == 'MOVE':
				_dragFunc = dragMove;
				break;
			case _state.substr(0, 6) == 'RESIZE':
				_dragFunc = _ratio ? dragResizeRatio : dragResize;
				break;
			}
			root.stage.addEventListener(MouseEvent.MOUSE_MOVE, _dragFunc);
			root.stage.addEventListener(MouseEvent.MOUSE_UP, dragEnd);
		}
		
		private function dragResizeRatio(e:MouseEvent):void {
			var dX:Number = e.stageX - _startPoint.x;
			var dY:Number = e.stageY - _startPoint.y;
			var nT:Number = _origRectangle.top;
			var nL:Number = _origRectangle.left;
			var nH:Number = _origRectangle.height;
			var nW:Number = _origRectangle.width;
			if (_state.lastIndexOf('NW') > 6) {
				nT = _origRectangle.top + dY;
				if (nT < 0) {
					nT = 0;
				}
				nH = _origRectangle.bottom - nT;
				nW = nH * _ratio;
				nL = _origRectangle.right - nW;
				if (nL < 0) {
					nL = 0;
					nW = _origRectangle.right;
					nH = nW / _ratio;
					nT = _origRectangle.bottom - nH;
				}
			} else if (_state.lastIndexOf('NE') > 6) {
				nT = _origRectangle.top + dY;
				if (nT < 0) {
					nT = 0;
				}
				nH = _origRectangle.bottom - nT;
				nW = nH * _ratio;
				if (_origRectangle.left + nW > _canvas.width) {
					nW = _canvas.width - _origRectangle.left;
					nH = nW / _ratio;
					nT = _origRectangle.bottom - nH;
				}
			} else if (_state.lastIndexOf('SW') > 6) {
				nL = _origRectangle.left + dX;
				if (nL < 0) {
					nL = 0;
				}
				nW = _origRectangle.right - nL;
				nH = nW / _ratio;
				if (_origRectangle.top + nH > _canvas.height) {
					nH = _canvas.height - _origRectangle.top;
					nW = nH * _ratio;
					nL = _origRectangle.right - nW;
				}
			} else if (_state.lastIndexOf('SE')) {
				nW = _origRectangle.width + dX;
				if (_origRectangle.left + nW > _canvas.width) {
					nW = _canvas.width - _origRectangle.left;
				}
				nH = nW / _ratio;
				if (_origRectangle.top + nH > _canvas.height) {
					nH = _canvas.height - _origRectangle.top;
					nW = nH * _ratio;
				}
			}
			
			var minsize:Number = MIN_SIZE * _scale;
			if (_ratio > 1) {
				if (nH < minsize) {
					nH = minsize;
					nW = nH * _ratio;
					if (_state.lastIndexOf('N') > 6) {
						nT = _origRectangle.bottom - nH;
					}
					if (_state.lastIndexOf('W') > 6) {
						nL = _origRectangle.right - nW;
					}
				}
			} else {
				if (nW < minsize) {
					nW = minsize;
					nH = nW / _ratio;
					if (_state.lastIndexOf('N') > 6) {
						nT = _origRectangle.bottom - nH;
					}
					if (_state.lastIndexOf('W') > 6) {
						nL = _origRectangle.right - nW;
					}
				}
			}
			setTop(nT);
			setHeight(nH);
			setLeft(nL);
			setWidth(nW);
			dispatchEvent(new ImageEvent(ImageEvent.PROP_CHANGE));
		}
		
		private function dragResize(e:MouseEvent):void {
			var dX:Number = e.stageX - _startPoint.x;
			var dY:Number = e.stageY - _startPoint.y;
			var oH:Number = _origRectangle.height;
			var oW:Number = _origRectangle.width;
			var s:Array = _state.substr(7).split('');
			var i:int = -1;
			if ((i = s.indexOf('N')) > -1) {
				if (dY > oH) {
					moveN(oH);
					_startPoint.y += oH;
					_origRectangle.top = _origRectangle.bottom;
					s[i] = 'S';
					moveS(dY - oH);
				} else {
					moveN(dY);
				}
			} else if ((i = s.indexOf('S')) > -1) {
				if (dY < -oH) {
					moveS(-oH);
					_startPoint.y -= oH;
					_origRectangle.bottom = _origRectangle.top;
					s[i] = 'N';
					moveN(dY + oH);
				} else {
					moveS(dY);
				}
			}
			
			if ((i = s.indexOf('W')) > -1) {
				if (dX > oW) {
					moveW(oW);
					_startPoint.x += oW;
					_origRectangle.left = _origRectangle.right;
					s[i] = 'E';
					moveE(dX - oW);
				} else {
					moveW(dX);
				}
			} else if ((i = s.indexOf('E')) > -1) {
				if (dX < -oW) {
					moveE(-oW);
					_startPoint.x -= oW;
					_origRectangle.right = _origRectangle.left;
					s[i] = 'W';
					moveW(dX + oW);
				} else {
					moveE(dX);
				}
			}
			_state = 'RESIZE_' + s.join('');
			Cursor.setCursor(_state);
			dispatchEvent(new ImageEvent(ImageEvent.PROP_CHANGE));
		}
		
		private function dragMove(e:MouseEvent):void {
			var dX:Number = e.stageX - _startPoint.x;
			var dY:Number = e.stageY - _startPoint.y;
			var l:Number = _origRectangle.left + dX;
			var t:Number = _origRectangle.top + dY;
			var oH:Number = _origRectangle.height;
			var oW:Number = _origRectangle.width;
			if (l < 0) {
				l = 0;
			}
			if (oW + l > _canvas.width) {
				l = _canvas.width - oW;
			}
			if (t < 0) {
				t = 0;
			}
			if (oH + t > _canvas.height) {
				t = _canvas.height - oH;
			}
			setTop(t);
			setLeft(l);
		}
		
		private function moveN(dY:Number):void {
			var t:Number = _origRectangle.top + dY;
			if (_origRectangle.top + dY < 0) {
				t = 0;
			}
			setTop(t);
			setHeight(_origRectangle.bottom - t);
		}
		private function moveS(dY:Number):void {
			var h:Number = _origRectangle.height + dY;
			if (dY + _origRectangle.bottom > _canvas.height) {
				h = _canvas.height - _origRectangle.top;
			}
			setHeight(h);
		}
		private function moveW(dX:Number):void {
			var l:Number = _origRectangle.left + dX;
			if (_origRectangle.left + dX < 0) {
				l = 0;
			}
			setLeft(l);
			setWidth(_origRectangle.right - l);
		}
		private function moveE(dX:Number):void {
			var w:Number = _origRectangle.width + dX;
			if (dX + _origRectangle.right > _canvas.width) {
				w = _canvas.width - _origRectangle.left;
			}
			setWidth(w);
		}
		
		private function dragEnd(e:MouseEvent):void {
			if (_dragFunc != null) {
				root.stage.removeEventListener(MouseEvent.MOUSE_MOVE, _dragFunc);
				_dragFunc = null;
			}
			root.stage.removeEventListener(MouseEvent.MOUSE_UP, dragEnd);
			_actionLocked = false;
			if (_backCursor) {
				Cursor.setCursor(_backCursor);
			} else {
				Cursor.reset();
			}
			_state = '';
		}
		
		private function setTop(top:Number):void {
			overlay.erase.y = top;
			area.y = top;
		}
		
		private function setLeft(left:Number):void {
			overlay.erase.x = left;
			area.x = left;
		}
		
		private function setHeight(height:Number):void {
			overlay.erase.height = height;
			area.MOVE.height = height;
			area.RESIZE_SW.y = height;
			area.RESIZE_SE.y = height;
			area.RESIZE_W.y = height / 2;
			area.RESIZE_S.y = area.RESIZE_SW.y;
			area.RESIZE_E.y = area.RESIZE_W.y;
		}
		
		private function setWidth(width:Number):void {
			overlay.erase.width = width;
			area.MOVE.width = width;
			area.RESIZE_NE.x = width;
			area.RESIZE_SE.x = width;
			area.RESIZE_N.x = width / 2;
			area.RESIZE_S.x = area.RESIZE_N.x;
			area.RESIZE_E.x = area.RESIZE_NE.x;
		}
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (value) {
				_scale = _canvas.scale;
				overlay.bg.width = _canvas.width;
				overlay.bg.height = _canvas.height;
			}
		}
		
		public function fixRatio(flag:Boolean = true):Number {
			var o:Number = _ratio;
			if (flag) {
				_ratio = area.MOVE.width / area.MOVE.height;
				area.RESIZE_N.visible = false;
				area.RESIZE_W.visible = false;
				area.RESIZE_S.visible = false;
				area.RESIZE_E.visible = false;
			} else {
				_ratio = 0;
				area.RESIZE_N.visible = true;
				area.RESIZE_W.visible = true;
				area.RESIZE_S.visible = true;
				area.RESIZE_E.visible = true;
			}
			return _ratio || o;
		}
		
		public function updateScale():void {
			var ns:Number = _canvas.scale / _scale;
			_scale = _canvas.scale;
			setLeft(area.x * ns);
			setTop(area.y * ns);
			setHeight(overlay.erase.height * ns);
			setWidth(overlay.erase.width * ns);
			overlay.bg.width = _canvas.width;
			overlay.bg.height = _canvas.height;
		}
		
		public function set rect(v:Rectangle):void {
			setLeft(v.x);
			setTop(v.y);
			setWidth(v.width);
			setHeight(v.height);
		}
		
		public function set clip(rec:Rectangle):void {
			setLeft(rec.left * _scale);
			setTop(rec.top * _scale);
			setWidth(rec.width * _scale);
			setHeight(rec.height * _scale);
		}
		
		public function get clip():Rectangle {
			return new Rectangle(area.x / _scale, area.y / _scale, overlay.erase.width / _scale, overlay.erase.height / _scale);
		}
	}
}
