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
	
	import flash.display.BlendMode;
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Cropper extends Sprite {
		
		private const MIN_SIZE:Number = 20;
		
		private var _overlay:Sprite;
		private var _overlayErase:Shape;
		private var _overlayBg:Shape;
		
		private var _area:Sprite;
		private var _areaResizeNW:Sprite;
		private var _areaResizeN:Sprite;
		private var _areaResizeNE:Sprite;
		private var _areaResizeE:Sprite;
		private var _areaResizeSE:Sprite;
		private var _areaResizeS:Sprite;
		private var _areaResizeSW:Sprite;
		private var _areaResizeW:Sprite;
		private var _areaMove:Sprite;
		
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
			initOverlay();
			initArea();
			this.rect = rect;
		}
		
		private function initOverlay():void {
			_overlay = new Sprite();
			addChild(_overlay);
			_overlay.blendMode = BlendMode.LAYER;
			_overlayBg = new Shape();
			_overlay.addChild(_overlayBg);
			_overlayBg.x = 0;
			_overlayBg.y = 0;
			_overlayBg.graphics.beginFill(0xCCCCCC, .5);
			_overlayBg.graphics.drawRect(0, 0, _canvas.width, _canvas.height);
			_overlayBg.graphics.endFill();
			_overlayErase = new Shape();
			_overlay.addChild(_overlayErase);
			_overlayErase.blendMode = BlendMode.ERASE;
			_overlayErase.x = 0;
			_overlayErase.y = 0;
			_overlayErase.graphics.beginFill(0xFFFFFF);
			_overlayErase.graphics.drawRect(0, 0, 300, 300);
			_overlayErase.graphics.endFill();
		}
		
		private function initArea():void {
			_area = new Sprite();
			addChild(_area);
			_areaMove = new Sprite();
			_areaMove.graphics.beginFill(0xFFFFFF, 0);
			_areaMove.graphics.lineStyle(0, 0, 1, false, LineScaleMode.NONE, CapsStyle.NONE);
			_areaMove.graphics.moveTo(0, 0);
			_areaMove.graphics.lineTo(0, 300);
			_areaMove.graphics.lineTo(300, 300);
			_areaMove.graphics.lineTo(300, 0);
			_areaMove.graphics.lineTo(0, 0);
			_areaMove.graphics.endFill();
			_area.addChild(_areaMove);
			_areaMove.x = 0;
			_areaMove.y = 0;
			_areaMove.name = 'MOVE';
			
			_areaResizeN = createHandle(150, 0, 'RESIZE_N');
			_areaResizeW = createHandle(0, 150, 'RESIZE_W');
			_areaResizeS = createHandle(150, 300, 'RESIZE_S');
			_areaResizeE = createHandle(300, 150, 'RESIZE_E');
			_areaResizeNW = createHandle(0, 0, 'RESIZE_NW');
			_areaResizeNE = createHandle(300, 0, 'RESIZE_NE');
			_areaResizeSW = createHandle(0, 300, 'RESIZE_SW');
			_areaResizeSE = createHandle(300, 300, 'RESIZE_SE');
			_area.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			_area.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			_area.addEventListener(MouseEvent.ROLL_OUT, rollOut);
			_areaMove.doubleClickEnabled = true;
			_areaMove.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent):void {
				dispatchEvent(new ImageEvent(ImageEvent.CROP));
			});
		}
		
		private function createHandle(x:Number, y:Number, name:String):Sprite {
			var handle:Sprite = new Sprite();
			handle.graphics.beginFill(0xFFFFFF);
			handle.graphics.lineStyle(0, 0);
			handle.graphics.moveTo(-4, -4);
			handle.graphics.lineTo(-4, 4);
			handle.graphics.lineTo(4, 4);
			handle.graphics.lineTo(4, -4);
			handle.graphics.lineTo(-4, -4);
			handle.graphics.endFill();
			_area.addChild(handle);
			handle.x = x;
			handle.y = y;
			handle.name = name;
			return handle;
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
			_origRectangle = new Rectangle(_area.x, _area.y, _areaMove.width, _areaMove.height);
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
			_overlayErase.y = top;
			_area.y = top;
		}
		
		private function setLeft(left:Number):void {
			_overlayErase.x = left;
			_area.x = left;
		}
		
		private function setHeight(height:Number):void {
			_overlayErase.height = height;
			_areaMove.height = height;
			_areaResizeSW.y = height;
			_areaResizeSE.y = height;
			_areaResizeW.y = height / 2;
			_areaResizeS.y = _areaResizeSW.y;
			_areaResizeE.y = _areaResizeW.y;
		}
		
		private function setWidth(width:Number):void {
			_overlayErase.width = width;
			_areaMove.width = width;
			_areaResizeNE.x = width;
			_areaResizeSE.x = width;
			_areaResizeN.x = width / 2;
			_areaResizeS.x = _areaResizeN.x;
			_areaResizeE.x = _areaResizeNE.x;
		}
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (value) {
				_scale = _canvas.scale;
				_overlayBg.width = _canvas.width;
				_overlayBg.height = _canvas.height;
			}
		}
		
		public function fixRatio(flag:Boolean = true):Number {
			var o:Number = _ratio;
			if (flag) {
				_ratio = _areaMove.width / _areaMove.height;
				_areaResizeN.visible = false;
				_areaResizeW.visible = false;
				_areaResizeS.visible = false;
				_areaResizeE.visible = false;
			} else {
				_ratio = 0;
				_areaResizeN.visible = true;
				_areaResizeW.visible = true;
				_areaResizeS.visible = true;
				_areaResizeE.visible = true;
			}
			return _ratio || o;
		}
		
		public function updateScale():void {
			var ns:Number = _canvas.scale / _scale;
			_scale = _canvas.scale;
			setLeft(_area.x * ns);
			setTop(_area.y * ns);
			setHeight(_overlayErase.height * ns);
			setWidth(_overlayErase.width * ns);
			_overlayBg.width = _canvas.width;
			_overlayBg.height = _canvas.height;
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
			return new Rectangle(_area.x / _scale, _area.y / _scale, _overlayErase.width / _scale, _overlayErase.height / _scale);
		}
	}
}
