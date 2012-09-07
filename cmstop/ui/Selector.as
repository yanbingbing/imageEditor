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
	import cmstop.FocusManager;
	import cmstop.Global;
	import cmstop.events.ImageEvent;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class Selector extends Sprite 
	{
		[Embed (source = "/assets/icon-down.png")]
		private const ICON_DOWN:Class;
		
		private const MARGIN:Number = 3;
		private const LINE_WIDTH:Number = 1;
		private const ITEM_HEIGHT:Number = 25;
		private const HOVER_COLOR:uint = 0x009DE6;
		private const FOCUS_COLOR:uint = 0x009DE6;
		
		private var _fieldHeight:Number = 20;
		private var _iconWidth:Number = 20;
		private var _itemMaxWidth:Number = 0;
		/**
		 * 最大允许宽度
		 */
		private var _maxWidth:Number;
		private var _maxHeight:Number;
		/**
		 * 当前使用的宽度
		 */
		private var _curWidth:Number = 0;
		/**
		 * 动态适应宽度
		 */
		private var _dnyWidth:Number = 80;
		
		private var _inited:Boolean = false;
		private var _dropBox:Sprite = new Sprite();
		private var _dropContent:Sprite = new Sprite();
		private var _scroll:ScrollPanel;
		private var _txt:TextField = new TextField();
		private var _field:Sprite = new Sprite();
		
		private var _button:Button;
		
		private var _hoverIndex:int = -1;
		private var _focusIndex:int = -1;
		
		private var _length:uint = 0;
		private var _source:Array = new Array();
		private var _value:* = null;
		private var _valueStack:Array = new Array();
		
		public function Selector(source:Array = null, value:* = null, maxWidth:Number = 180, maxHeight:Number = 200) 
		{
			_maxWidth = maxWidth;
			_maxHeight = maxHeight;
			_value = value;
			if (source) {
				_source = source;
				_length = _source.length;
				_source.forEach(renderItem);
			}
			
			var icon:Bitmap = new ICON_DOWN() as Bitmap;
			_fieldHeight = icon.height / 3 - 2;
			_iconWidth = icon.width;
			
			_button = new Button(icon, 3);
			_button.addState(Button.STATE_HOVER, null, -1, 1)
					.addState(Button.STATE_ACTIVED, null, -1, 2);
			_button.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
				switch(_button.state) {
				case Button.STATE_DEFAULT: case Button.STATE_HOVER:
					showBox();
					break;
				default:
					hideBox();
					break;
				}
			});
			addChild(_button);
			
			_txt.autoSize = TextFieldAutoSize.LEFT;
			_txt.multiline = false;
			_txt.mouseEnabled = false;
			_txt.setTextFormat(Global.textFormat);
			_txt.text = "请选择";
			_field.addChild(_txt);
			_txt.x = MARGIN;
			addChild(_field);
			_field.x = LINE_WIDTH / 2;
			_field.y = (_fieldHeight + LINE_WIDTH - _txt.height) / 2;
			
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		private function init(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			_inited = true;
			stage.addChild(_dropBox);
			_dropBox.visible = false;
			adapt();
			FocusManager.addItem(_dropBox, this, hideBox);
			_scroll = new ScrollPanel(_dropContent, _maxHeight, _maxWidth);
			_dropBox.addChild(_scroll);
			_dropContent.addEventListener(MouseEvent.MOUSE_MOVE, mouseOver);
			_dropContent.addEventListener(MouseEvent.ROLL_OUT, unHover);
			_dropContent.addEventListener(MouseEvent.MOUSE_WHEEL, mouseOver);
			_dropContent.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			this.value = _value;
			_dropBox.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			var t:Selector = this;
			stage.stageFocusRect = false;
			addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
				stage.focus = t;
				if (!_dropBox.visible && !_button.contains(e.target as DisplayObject)) {
					showBox();
				}
			});
		}
		private function adapt():void {
			if (!_inited) return;
			var halfLineWidth:Number = LINE_WIDTH / 2;
			if (_dnyWidth != _curWidth) {
				_curWidth = _dnyWidth;
				_button.x = _curWidth + halfLineWidth - _iconWidth;
				_button.y = 0;
				this.graphics.clear();
				this.graphics.beginFill(0xFAFAFA);
				this.graphics.lineStyle(LINE_WIDTH, 0xA2A2A2);
				this.graphics.drawRect(halfLineWidth, halfLineWidth, _curWidth + LINE_WIDTH, _fieldHeight + LINE_WIDTH);
				this.graphics.endFill();
				_field.scrollRect = new Rectangle(0, 0, _curWidth - _iconWidth, _fieldHeight);
			}
			if (_length > 0) {
				var newHeight:Number = ITEM_HEIGHT * _length;
				_dropContent.graphics.clear();
				_dropContent.graphics.beginFill(0xFFFFFF);
				_dropContent.graphics.drawRect(0, 0, _curWidth, newHeight);
				_dropContent.graphics.endFill();
				
				_dropBox.graphics.clear();
				_dropBox.graphics.beginFill(0, 0);
				_dropBox.graphics.lineStyle(LINE_WIDTH, 0xA2A2A2);
				_dropBox.graphics.drawRect(-halfLineWidth, -halfLineWidth, _curWidth + LINE_WIDTH, Math.min(_maxHeight, newHeight) + LINE_WIDTH);
				_dropBox.graphics.endFill();
			}
		}
		private function getItem(index:int):Sprite {
			return (index >= 0 && index < _length) ? _dropContent.getChildAt(index) as Sprite : null;
		}
		private function keyDown(e:KeyboardEvent):void {
			var index:int;
			switch(e.keyCode) {
			case 38:// UP
				if (_dropBox.visible) {
					index = _hoverIndex - 1;
					if (index < 0) {
						index += _length;
					}
					unHover();
					hover(index);
				} else {
					showBox();
				}
				break;
			case 40:// DOWN
				if (_dropBox.visible) {
					index = _hoverIndex + 1;
					if (index >= _length) {
						index = 0;
					}
					unHover();
					hover(index);
				} else {
					showBox();
				}
				break;
			case 13:// ENTER
				if (_dropBox.visible) {
					focus(_hoverIndex);
					hideBox();
				} else {
					showBox();
				}
				break;
			case 27:// ESC
				_dropBox.visible && hideBox();
				break;
			}
		}
		private function mouseOver(e:MouseEvent):void {
			var index:int = Math.floor(_dropContent.mouseY / ITEM_HEIGHT);
			if (_hoverIndex == index) {
				return;
			}
			unHover();
			hover(index);
		}
		private function mouseDown(e:MouseEvent):void {
			var index:int = Math.floor(_dropContent.mouseY / ITEM_HEIGHT);
			hideBox();
			focus(index);
		}
		private function hideBox():void {
			_button.state = Button.STATE_DEFAULT;
			_dropBox.visible = false;
		}
		private function showBox():void {
			var pos:Point = localToGlobal(new Point());
			_dropBox.x = pos.x + LINE_WIDTH;
			_dropBox.y = pos.y + _fieldHeight + LINE_WIDTH * 4;
			_button.state = Button.STATE_ACTIVED;
			stage.setChildIndex(_dropBox, stage.numChildren-1);
			_dropBox.visible = true;
			unHover();
			hover(_focusIndex);
		}
		private function focus(index:int):void {
			var s:Sprite;
			if ((s = getItem(index)) != null && _focusIndex != index) {
				clearState(_focusIndex);
				s.graphics.clear();
				s.graphics.beginFill(FOCUS_COLOR, 0.6);
				s.graphics.drawRect(0, 0, _curWidth, ITEM_HEIGHT);
				s.graphics.endFill();
				_txt.text = _source[index].name;
				_focusIndex = index;
				dispatchEvent(new ImageEvent(ImageEvent.VALUE_CHANGE, _valueStack[index]));
			}
		}
		private function hover(index:int):void {
			var s:Sprite;
			if ((s = getItem(index)) != null) {
				if (index != _focusIndex) {
					s.graphics.clear();
					s.graphics.beginFill(HOVER_COLOR, 0.2);
					s.graphics.drawRect(0, 0, _curWidth, ITEM_HEIGHT);
					s.graphics.endFill();
				}
				if (s.y - _scroll.scrollTop < 0) {
					_scroll.scrollTop = s.y;
				} else if (s.y + ITEM_HEIGHT - _maxHeight > _scroll.scrollTop) {
					_scroll.scrollTop = s.y + ITEM_HEIGHT - _maxHeight;
				}
				_hoverIndex = index;
			}
		}
		private function clearState(index:int):void {
			var s:Sprite;
			if ((s = getItem(index)) != null) {
				s.graphics.clear();
				s.graphics.beginFill(0, 0);
				s.graphics.drawRect(0, 0, _curWidth, ITEM_HEIGHT);
				s.graphics.endFill();
			}
		}
		private function unHover(e:MouseEvent = null):void {
			if (_hoverIndex != _focusIndex) {
				clearState(_hoverIndex);
			}
			_hoverIndex = -1;
		}
		private function renderItem(item:Object, index:uint=0, array:Array=null):void {
			var t:TextField = new TextField();
			t.autoSize = TextFieldAutoSize.LEFT;
			t.multiline = false;
			t.mouseEnabled = false;
			t.text = item.name;
			t.setTextFormat(Global.textFormat);
			var s:Sprite = new Sprite();
			s.addChild(t);
			t.x = MARGIN;
			t.y = (ITEM_HEIGHT - t.height) / 2;
			s.y = _dropContent.numChildren * ITEM_HEIGHT;
			_dropContent.addChild(s);
			_valueStack.push(item.value);
			_dnyWidth = Math.min(_maxWidth, Math.max(_dnyWidth, s.width));
		}
		public function addItem(name:String, value:*, font:String = null):void {
			var item:Object = {
				name:name,
				value:value,
				font:font
			};
			_length = _source.push(item);
			renderItem(item);
			adapt();
		}
		public function set value(value:*):void {
			if (_inited) {
				focus(_valueStack.indexOf(value));
			} else {
				_value = value;
			}
		}
		public function get value():* {
			return _focusIndex > -1 ? _valueStack[_focusIndex] : null;
		}
	}
}