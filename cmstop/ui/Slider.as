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
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Slider extends Sprite 
	{
		[Embed (source = "/assets/slider-bg-h.png")]
		private const SLIDER_BG_H:Class;
		[Embed (source = "/assets/slider-bg-v.png")] 
		private const SLIDER_BG_V:Class;
		[Embed (source = "/assets/icon-slider.png")]
		private const ICON_SLIDER:Class;
		
		private var _size:Number;
		private var _vertical:Boolean;
		private var _slider:Sprite;
		private var _btn:Bitmap;
		
		private var _draging:Boolean = false;
		private var _clickMou:Number;
		private var _clickPos:Number;
		private var _endOver:Boolean;
		public function Slider(vertical:Boolean = false) 
		{
			_vertical = vertical;
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		private function init(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			var bg:Bitmap;
			var margin:Number = 3;
			var bar:Sprite = new Sprite();
			if (_vertical) {
				bg = new SLIDER_BG_V() as Bitmap;
				_size = bg.height - margin*2;
				bg.x = -bg.width / 2;
				bg.y = -margin;
			} else {
				bg = new SLIDER_BG_H() as Bitmap;
				_size = bg.width - margin*2;
				bg.x = -margin;
				bg.y = -bg.height / 2;
			}
			bar.addChild(bg);
			addChild(bar);
			
			bar.buttonMode = true;
			bar.addEventListener(MouseEvent.MOUSE_DOWN, mouseSeek);
			
			_slider = new Sprite();
			_btn = new ICON_SLIDER() as Bitmap;
			var s:Sprite = new Sprite();
			var w:Number = _btn.width;
			var h:Number = _btn.height / 2;
			this.graphics.beginFill(0, 0);
			this.graphics.drawRect(0, -h / 2, _size, h);
			this.graphics.endFill();
			s.addChild(_btn);
			s.scrollRect = new Rectangle(0, 0, w, h);
			_btn.y = 0;
			_slider.addChild(s);
			s.x = -w / 2;
			s.y = -h / 2;
			addChild(_slider);
			_slider.x = 0;
			0;
			_slider.buttonMode = true;
			_slider.addEventListener(MouseEvent.ROLL_OVER, rollOver);
			_slider.addEventListener(MouseEvent.ROLL_OUT, rollOut);
			_slider.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		}
		
		private function rollOver(e:MouseEvent):void {
			if (_draging) {
				_endOver = true;
				return;
			}
			_btn.y = -_btn.height / 2;
		}
		private function rollOut(e:MouseEvent):void {
			if (_draging) {
				_endOver = false;
				return;
			}
			_btn.y = 0;
		}
		private function mouseDown(e:MouseEvent):void {
			_clickMou = _vertical ? e.stageY : e.stageX;
			_clickPos = _vertical ? _slider.y : _slider.x;
			root.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			root.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		private function mouseMove(e:MouseEvent):void {
			if (!_draging) {
				_draging = true;
				dispatchEvent(new ImageEvent(ImageEvent.DRAG_START));
			}
			setPos((_vertical ? e.stageY : e.stageX) - _clickMou + _clickPos);
			e.updateAfterEvent();
		}
		private function mouseSeek(e:MouseEvent):void {
			dispatchEvent(new ImageEvent(ImageEvent.DRAG_START));
			setPos(_vertical ? e.localY : e.localX);
			dispatchEvent(new ImageEvent(ImageEvent.DRAG_END));
			e.updateAfterEvent();
		}
		private function setPos(pos:Number):void {
			if (pos < 0) {
				pos = 0;
			} else if (pos > _size) {
				pos = _size;
			}
			if (_vertical) {
				_slider.y = pos;
			} else {
				_slider.x = pos;
			}
			dispatchEvent(new ImageEvent(ImageEvent.SLIDER_CHANGE, pos / _size));
		}
		private function mouseUp(e:MouseEvent):void {
			root.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			root.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if (_draging) {
				_draging = false;
				dispatchEvent(new ImageEvent(ImageEvent.DRAG_END));
			}
			_btn.y = _endOver ? ( -_btn.height / 2) : 0;
		}
		
		public function inDrag():Boolean {
			return _draging;
		}
		
		public function set percent(v:Number):void {
			if (v < 0) {
				v = 0
			} else if (v > 1) {
				v = 1;
			}
			var nPos:Number = v * _size;
			if (_vertical) {
				_slider.y = nPos;
			} else {
				_slider.x = nPos;
			}
		}
		public function get percent():Number {
			return (_vertical ? _slider.y : _slider.x) / _size;
		}
	}
}