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
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class Button extends Sprite 
	{
		public static const STATE_HOVER:String = 'state_hover';
		public static const STATE_DEFAULT:String = 'state_default';
		public static const STATE_DISABLED:String = 'state_disabled';
		public static const STATE_ACTIVED:String = 'state_actived';
		public static const STATE_ACTIVED_HOVER:String = 'state_actived_hover';
		
		private var _background:Bitmap = null;
		private var _backgroundIndex:Vector.<Point>;
		private var _icon:Bitmap = null;
		private var _ico:Sprite = null;
		private var _iconIndex:Vector.<Point>;
		private var _text:TextField = null;
		
		private var _state:String = Button.STATE_DEFAULT;
		private var _stateHash:Object = new Object();
		private var _isOver:Boolean = false;
		
		private var _height:Number;
		private var _width:Number;
		
		private const MARGIN:Number = 3;
		
		public function Button(backgroundOrWidth:*, heightOrCount:Number = 1)
		{
			_stateHash[Button.STATE_DEFAULT] = {
				backgroundIndex: -1,
				iconIndex: -1
			};
			if (backgroundOrWidth is Bitmap) {
				_background = backgroundOrWidth;
				addChild(_background);
				_backgroundIndex = new Vector.<Point>;
				var count:uint = uint(heightOrCount) || 1;
				_width = _background.width;
				_height = _background.height / count;
				for (var i:uint = 0; i < count; i++) {
					_backgroundIndex.push(new Point(0, -i * _height));
				}
				_stateHash[Button.STATE_DEFAULT].backgroundIndex = 0;
			} else {
				_width = Number(backgroundOrWidth);
				_height = heightOrCount;
			}
			this.scrollRect = new Rectangle(0, 0, _width, _height);
			this.graphics.beginFill(0, 0);
			this.graphics.drawRect(0, 0, _width, _height);
			this.graphics.endFill();
			this.buttonMode = true;
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
			addEventListener(Event.ADDED_TO_STAGE, function() {
				stage.addEventListener(Event.MOUSE_LEAVE, rollOut);
			});
		}
		
		private function rollOver(e:MouseEvent):void {
			_isOver = true;
			if (_state == Button.STATE_ACTIVED) {
				setStateActivedHover();
			} else if (_state == Button.STATE_DEFAULT) {
				setStateHover();
			}
		}
		private function rollOut(e:Event):void {
			_isOver = false;
			if (_state == Button.STATE_ACTIVED_HOVER) {
				setStateActived();
			} else if (_state == Button.STATE_HOVER) {
				setStateDefault();
			}
		}
		
		public function setText(text:String, format:TextFormat):Button
		{
			if (_text != null) {
				return this;
			}
			_text = new TextField();
			_text.autoSize = TextFieldAutoSize.CENTER;
			_text.defaultTextFormat = format;
			_text.text = text;
			_text.mouseEnabled = false;
			_stateHash[Button.STATE_DEFAULT].textFormat = format;
			addChild(_text);
			if (_icon != null) {
				_ico.x = (_width - _ico.width - _text.width - MARGIN) / 2;
				_text.x = _ico.x + _ico.width + MARGIN;
			} else {
				_text.x = (_width - _text.width) / 2;
			}
			_text.y = (_height - _text.height) / 2;
			return this;
		}
		
		public function setIconImage(icon:Bitmap, count:uint = 1):Button
		{
			if (_icon != null) {
				return this;
			}
			_icon = icon;
			_ico = new Sprite();
			var height:Number = _icon.height / count;
			_ico.scrollRect = new Rectangle(0, 0, _icon.width, height);
			_ico.addChild(_icon);
			addChild(_ico);
			_iconIndex = new Vector.<Point>;
			for (var i:uint=0; i < count; i++) {
				_iconIndex.push(new Point(0, -i * height));
			}
			_stateHash[Button.STATE_DEFAULT].iconIndex = 0;
			if (_text != null) {
				_ico.x = (_width - _ico.width - _text.width - MARGIN) / 2;
				_text.x = _ico.x + _ico.width + MARGIN;
			} else {
				_ico.x = (_width - _ico.width) / 2;
			}
			_ico.y = (_height - height) / 2;
			return this;
		}
		
		public function addState(state:String, textFormat:TextFormat = null, iconIndex:int = -1, backgroundIndex:int = -1):Button
		{
			_stateHash[state] = {
				textFormat:textFormat,
				iconIndex:iconIndex,
				backgroundIndex:backgroundIndex
			};
			return this;
		}
		
		private function hasState(state:String):Boolean
		{
			return (state in _stateHash);
		}
		
		private function setState(state:Object):void
		{
			if (state.iconIndex > -1 && _icon != null) {
				_icon.x = _iconIndex[state.iconIndex].x;
				_icon.y = _iconIndex[state.iconIndex].y;
			}
			if (state.backgroundIndex > -1 && _background != null) {
				_background.x = _backgroundIndex[state.backgroundIndex].x;
				_background.y = _backgroundIndex[state.backgroundIndex].y;
			}
			if (('textFormat' in state) && _text != null) {
				_text.setTextFormat(state.textFormat);
				_text.y = (_height - _text.height) / 2;
			}
		}
		
		private function setStateDisabled():void {
			setState(_stateHash[hasState(Button.STATE_DISABLED) ? Button.STATE_DISABLED : Button.STATE_DEFAULT]);
			_state = Button.STATE_DISABLED;
			this.mouseEnabled = false;
			this.buttonMode = false;
		}
		
		private function setStateHover():void {
			if (!hasState(Button.STATE_HOVER)) {
				return;
			}
			setState(_stateHash[Button.STATE_HOVER]);
			_state = Button.STATE_HOVER;
		}
		
		private function setStateDefault():void {
			if (_state == Button.STATE_DISABLED) {
				this.mouseEnabled = true;
				this.buttonMode = true;
			}
			_state = Button.STATE_DEFAULT;
			setState(_stateHash[Button.STATE_DEFAULT]);
		}
		
		private function setStateActived():void {
			if (!hasState(Button.STATE_ACTIVED)) {
				return;
			}
			if (_state == Button.STATE_DISABLED) {
				this.mouseEnabled = true;
				this.buttonMode = true;
			}
			_state = Button.STATE_ACTIVED;
			setState(_stateHash[Button.STATE_ACTIVED]);
		}
		
		private function setStateActivedHover():void {
			if (!hasState(Button.STATE_ACTIVED_HOVER)) {
				return;
			}
			_state = Button.STATE_ACTIVED_HOVER;
			setState(_stateHash[Button.STATE_ACTIVED_HOVER]);
		}
		
		public function set state(s:String):void {
			switch(s) {
			case Button.STATE_ACTIVED: case Button.STATE_ACTIVED_HOVER:
				setStateActived();
				_isOver && setStateActivedHover();
				break;
			case Button.STATE_DISABLED:
				setStateDisabled();
				break;
			case Button.STATE_DEFAULT: default:
				setStateDefault();
				_isOver && setStateHover();
				break;
			}
		}
		
		public function get state():String {
			return _state;
		}
		override public function get width():Number {
			return _width;
		}
		override public function get height():Number {
			return _height;
		}
	}
}