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
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	
	public class ScrollPanel extends Sprite 
	{
		private const SLIDER_WIDTH:Number = 8;
		private const MIN_SLIDER_HEIGHT:Number = 30;
		
		private var _content:DisplayObject;
		private var _scrollBar:Sprite = new Sprite();
		private var _sliderBar:Sprite = new Sprite();
		private var _slider:Sprite = new Sprite();
		private var _sliderWidth:Number = 12;
		private var _totalHeight:Number;
		private var _sliderBarHeight:Number;
		private var _maxHeight:Number;
		private var _maxWidth:Number;
		private var _percent:Number;
		
		private var _draging:Boolean = false;
		private var _clickMou:Number;
		private var _clickPos:Number;
		private var _endOver:Boolean;
		private var _ivalhide:uint;
		
		public function ScrollPanel(content:DisplayObject, maxHeight:Number, maxWidth:Number = 180)
		{
			_maxHeight = maxHeight;
			_maxWidth = maxWidth;
			_content = content;
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		public function set scrollTop(top:Number):void {
			setPercent(top / (_content.height - _maxHeight));
			setSliderPos();
			setContentPos();
		}
		public function get scrollTop():Number {
			return -_content.y;
		}
		private function init(e:Event):void {
			_sliderBar.addChild(_slider);
			_scrollBar.addChild(_sliderBar);
			addChild(_scrollBar);
			qHide();
			
			// _content.addEventListener(Event.ENTER_FRAME, resize);
			_content.addEventListener(Event.ADDED_TO_STAGE, adapt);
			addChildAt(_content, 0);
			_scrollBar.addEventListener(MouseEvent.ROLL_OVER, rollOver);
			_scrollBar.addEventListener(MouseEvent.ROLL_OUT, rollOut);
			_slider.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		}
		private function setPercent(percent:Number):void {
			if (percent > 1) {
				percent = 1;
			} else if (percent < 0) {
				percent = 0;
			}
			_percent = percent;
		}
		public function adapt(e:Event = null):void {
			if (_content.height == _totalHeight) {
				return;
			}
			_totalHeight = _content.height;
			var sliderHeight:Number = Math.max(Math.pow(_maxHeight, 2) / _totalHeight, MIN_SLIDER_HEIGHT);
			_sliderBarHeight = _maxHeight - sliderHeight;
			
			this.scrollRect = new Rectangle(0, 0, Math.min(_content.width, _maxWidth), Math.min(_totalHeight, _maxHeight));
			_scrollBar.graphics.clear();
			_sliderBar.graphics.clear();
			_slider.graphics.clear();
			_scrollBar.x = Math.min(_content.width, _maxWidth) - SLIDER_WIDTH;
			if (_sliderBarHeight <= 0) {
				removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
				_scrollBar.visible = false;
				return;
			}
			addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
			_scrollBar.visible = true;
			_scrollBar.graphics.beginFill(0, 0);
			_scrollBar.graphics.drawRect(0, 0, SLIDER_WIDTH, _maxHeight);
			_scrollBar.graphics.endFill();
			
			_sliderBar.graphics.beginFill(0, 0);
			_sliderBar.graphics.drawRect( -2, 0, 4, _sliderBarHeight);
			_sliderBar.graphics.endFill();
			_sliderBar.y = sliderHeight / 2;
			
			_slider.graphics.beginFill(0x4F4F4F, 0.9);
			_slider.graphics.drawRoundRect(0, -sliderHeight / 2, SLIDER_WIDTH, sliderHeight, SLIDER_WIDTH);
			_slider.graphics.endFill();
			setPercent(-_content.y / (_content.height - _maxHeight));
			setSliderPos();
		}
		
		private function setSliderPos():void {
			_slider.y = _sliderBarHeight * _percent;
		}
		private function setContentPos():void {
			_content.y = -(_content.height - _maxHeight) * _percent;
		}
		
		private function iShow():void {
			if (_ivalhide) {
				clearTimeout(_ivalhide);
				_ivalhide = 0;
			}
			_scrollBar.alpha = 1;
		}
		private function iHide():void {
			if (_ivalhide) {
				clearTimeout(_ivalhide);
			}
			_ivalhide = setTimeout(qHide, 500);
		}
		private function qHide(e:Event = null):void {
			if (_ivalhide) {
				clearTimeout(_ivalhide);
				_ivalhide = 0;
			}
			_scrollBar.alpha = 0.3;
		}
		private function rollOver(e:MouseEvent):void {
			if (_draging) {
				_endOver = true;
				return;
			}
			iShow();
		}
		private function rollOut(e:MouseEvent):void {
			if (_draging) {
				_endOver = false;
				return;
			}
			iHide();
		}
		private function mouseWheel(e:MouseEvent):void {
			if (_draging) {
				return;
			}
			var oPercent:Number = _percent;
			setPercent( - (_content.y + e.delta * 20 / 3) / (_content.height - _maxHeight));
			if (oPercent != _percent) {
				setSliderPos();
				setContentPos();
				iShow();
				iHide();
			}
			e.updateAfterEvent();
		}
		private function mouseDown(e:MouseEvent):void {
			_draging = true;
			_clickMou = e.stageY;
			_clickPos = _slider.y;
			root.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			root.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		private function mouseMove(e:MouseEvent):void {
			setPercent((e.stageY - _clickMou + _clickPos) / _sliderBarHeight);
			setSliderPos();
			setContentPos();
			e.updateAfterEvent();
		}
		private function mouseUp(e:MouseEvent):void {
			root.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			root.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			_draging = false;
			if (!_endOver) {
				iHide();
			}
		}
	}
}