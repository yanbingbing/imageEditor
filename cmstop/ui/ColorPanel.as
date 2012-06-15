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
	import cmstop.FocusManager;
	import cmstop.Global;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	
	public class ColorPanel extends Sprite 
	{
		[Embed (source = "/assets/color-panel.png")]
		private const COLOR_PANEL:Class;
		private var _colorPanelData:BitmapData;
		private var _color:int = -1;
		private var _hoverColor:uint = 0;
		private var _colorTip:Shape;
		private var _colorTxt:TextField;
		private var _button:Shape = new Shape();
		private var _panel:Sprite = new Sprite();
		private var _inited:Boolean = false;
		
		public function ColorPanel(color:uint = 0) 
		{
			this.graphics.beginFill(0xFFFFFF);
			this.graphics.drawRect(1, 1, 21, 21);
			this.graphics.endFill();
			this.graphics.lineStyle(1, 0xA2A2A2);
			this.graphics.drawRect(0, 0, 20, 20);
			this.graphics.lineStyle(1);
			this.graphics.beginFill(0x3B3030);
			this.graphics.drawTriangles(Vector.<Number>([20, 16,  20, 20, 16, 20]));
			this.graphics.endFill();
			
			addChild(_button);
			setColor(color);
			addEventListener(MouseEvent.MOUSE_DOWN, showPanel);
			addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		}
		
		private function setColor(color:uint):void {
			if (_color == color) return;
			_color = color;
			_button.graphics.clear();
			_button.graphics.beginFill(0, 0);
			_button.graphics.drawRect(0, 0, 21, 21);
			_button.graphics.endFill();
			
			_button.graphics.beginFill(color);
			_button.graphics.drawRect(2, 2, 16, 16);
			_button.graphics.endFill();
			dispatchEvent(new ImageEvent(ImageEvent.VALUE_CHANGE, _color));
		}
		
		private function initPanel():void {
			if (_inited) return;
			var bmp:Bitmap = new COLOR_PANEL() as Bitmap;
			_colorPanelData = bmp.bitmapData;
			
			_panel.graphics.beginFill(0xFFFFFF);
			_panel.graphics.lineStyle(1, 0xCCCCCC);
			_panel.graphics.drawRect(0, 0, bmp.width + 5, bmp.height + 28);
			_panel.graphics.endFill();
			_colorTip = new Shape();
			_panel.addChild(_colorTip);
			_colorTip.x = 3;
			_colorTip.y = 3;
			setTipColor(_color);
			
			_colorTxt = new TextField();
			_colorTxt.width = 60;
			_colorTxt.height = 20;
			_colorTxt.type = TextFieldType.INPUT;
			_colorTxt.border = true;
			_colorTxt.background = true;
			_colorTxt.defaultTextFormat = Global.inputFormat;
			_colorTxt.restrict = "#A-Fa-f0-9";
			_colorTxt.maxChars = 7;
			_colorTxt.addEventListener(Event.CHANGE, textChange);
			_panel.addChild(_colorTxt);
			_colorTxt.x = 48;
			_colorTxt.y = 2;
			setTxtValue(_color);
			var s:Sprite = new Sprite();
			s.addChild(bmp);
			_panel.addChild(s);
			s.x = 3;
			s.y = 25;
			s.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			s.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addChild(_panel);
			_panel.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			addEventListener(Event.REMOVED, function(e:Event):void {
				stage.removeChild(_panel);
			});
			FocusManager.addItem(_panel, this, hidePanel);
			stage.stageFocusRect = false;
			_inited = true;
		}
		private function showPanel(e:MouseEvent):void {
			initPanel();
			stage.focus = this;
			var pos:Point = localToGlobal(new Point(0, 0));
			_panel.x = pos.x + this.width + 1;
			_panel.y = pos.y + 1;
			_panel.visible = true;
			stage.setChildIndex(_panel, stage.numChildren - 1);
		}
		private function hidePanel():void {
			_panel.visible = false;
		}
		private function setTipColor(color:uint):void {
			_colorTip.graphics.clear();
			_colorTip.graphics.lineStyle(1);
			_colorTip.graphics.beginFill(color);
			_colorTip.graphics.drawRect(0, 0, 40, 20);
			_colorTip.graphics.endFill();
		}
		private function setTxtValue(color:uint):void {
			_colorTxt.text = pad0(color.toString(16));
		}
		private function keyDown(e:KeyboardEvent):void {
			if (!_panel.visible) {
				return;
			}
			switch(e.keyCode) {
			case 13:// ENTER
				mouseDown();
				break;
			case 27:// ESC
				hidePanel();
				break;
			}
		}
		private function mouseMove(e:MouseEvent):void {
			var color:uint = _colorPanelData.getPixel(e.localX, e.localY);
			setTipColor(color);
			setTxtValue(color);
			_hoverColor = color;
			e.updateAfterEvent();
		}
		private function mouseDown(e:MouseEvent=null):void {
			hidePanel();
			setColor(_hoverColor);
		}
		private function textChange(e:Event):void {
			var color:uint = parseInt("0x"+_colorTxt.text.substr(1));
			setTipColor(color);
			_hoverColor = color;
		}
		private function pad0(str:String):String {
			return "#" + ("000000".substr(0, 6 - str.length)) + str.toUpperCase();
		}
		
		public function set value(color:uint):void {
			setColor(color);
		}
		
		public function get value():uint {
			return uint(_color);
		}
	}
}