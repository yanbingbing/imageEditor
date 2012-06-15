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
	import cmstop.Global;
	import cmstop.XLoader;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	
	public class ControlPanel extends Sprite 
	{
		[Embed (source = "/assets/seprator.png")]
		private const SEPRATOR:Class;
		[Embed (source = "/assets/button.png")]
		private const BUTTON:Class;
		
		protected var _width:Number;
		protected var _margin:Number = 10;
		protected var _marginV:Number = 3;
		protected var _top:Number = 5;
		protected var _inRead:Boolean = false;
		protected var _overlay:Overlay = null;
		protected var _params:Object = new Object();
		
		public function ControlPanel(width:Number = 210) 
		{
			_width = width;
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		protected function init(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}
		public function assoc(overlay:Overlay, write:Boolean = false):void {
			if (_overlay == null) {
				for (var key:String in _params) {
					_params[key].initValue = _params[key].value;
				}
			}
			if (_overlay != overlay) {
				overlay.addEventListener(Event.REMOVED_FROM_STAGE, loseAssoc);
				if (_overlay != null) {
					_overlay.removeEventListener(Event.REMOVED_FROM_STAGE, loseAssoc);
				}
				_overlay = overlay;
				if (write) {
					writeParams();
				}
				readParams();
			}
		}
		public function unAssoc():void {
			if (_overlay) {
				_overlay.removeEventListener(Event.REMOVED_FROM_STAGE, loseAssoc);
				_overlay = null;
			}
			_inRead = true;
			for (var key:String in _params) {
				_params[key].value = _params[key].initValue;
				_params[key].setter(_params[key].initValue);
			}
			_inRead = false;
		}
		
		private function loseAssoc(e:Event):void {
			if (e.currentTarget == _overlay) {
				_overlay = null;
				_inRead = true;
				for (var key:String in _params) {
					_params[key].value = _params[key].initValue;
					_params[key].setter(_params[key].initValue);
				}
				_inRead = false;
			}
		}
		
		public function hasAssoc():Boolean {
			return _overlay != null;
		}
		
		public function get overlay():Overlay {
			return _overlay;
		}
		
		private function readParams():void {
			_inRead = true;
			var params:Object = _overlay.params;
			for (var key:String in _params) {
				_params[key].value = params[key];
				_params[key].setter(params[key]);
			}
			_inRead = false;
		}
		
		private function writeParams():void {
			// genarate params
			var newParams:Object = new Object();
			for (var key:String in _params) {
				newParams[key] = _params[key].value;
			}
			// write
			_overlay.params = newParams;
		}
		
		public function setParam(key:String, value:*):void {
			_inRead = true;
			if (key in _params) {
				_params[key].value = value;
				_params[key].setter(value);
			}
			_inRead = false;
		}
		
		public function getParam(key:String):* {
			return _params[key].value;
		}
		
		protected function change(name:String, newValue:*, log:Boolean = true):void {
			var oldValue:* = _params[name].value;
			if (_inRead || oldValue == newValue) {
				return;
			}
			_params[name].value = newValue;
			if (!_overlay) {
				_params[name].initValue = newValue;
			} else {
				_overlay.setParam(name, newValue);
				log && Global.container.log('OverlayChange', _overlay, name, oldValue, newValue);
			}
		}
		
		protected function addItem(name:String, init:*, setter:Function):void {
			_params[name] = {
				'initValue':init,
				'value':init,
				'setter':setter
			};
		}
		
		protected function createButton(text:String, icon:Bitmap = null):Button {
			var btn:Button = new Button(new BUTTON() as Bitmap, 2);
			btn.setText(text, Global.textFormat)
				.addState(Button.STATE_HOVER, Global.textHoverFormat, -1, 1);
			if (icon) {
				btn.setIconImage(icon, 2);
			}
			return btn;
		}
		
		protected function addPxInput(title:String):TextField {
			var label:TextField = new TextField();
			label.defaultTextFormat = Global.textFormat;
			label.height = 20;
			label.width = 20;
			label.multiline = false;
			label.mouseEnabled = false;
			label.selectable = false;
			label.text = title;
			addChild(label);
			label.x = _margin + 8;
			label.y = (_top += _marginV + 3);
			var input:TextField = new TextField();
			input.defaultTextFormat = Global.inputFormat;
			input.height = 18;
			input.width = 58;
			input.multiline = false;
			input.restrict = '\.0-9';
			input.type = TextFieldType.INPUT;
			input.border = true;
			input.background = true;
			input.borderColor = 0xA2A2A2;
			input.backgroundColor = 0xFAFAFA;
			addChild(input);
			input.x = _margin + 30;
			input.y = _top;
			label = new TextField();
			label.defaultTextFormat = Global.textFormat;
			label.height = 20;
			label.width = 23;
			label.multiline = false;
			label.mouseEnabled = false;
			label.selectable = false;
			label.text = 'px';
			addChild(label);
			label.x = _margin + 90;
			label.y = _top;
			_top += 20;
			return input;
		}
		
		protected function addTitle(title:String):void {
			var label:TextField = new TextField();
			label.defaultTextFormat = Global.titleFormat;
			label.multiline = false;
			label.mouseEnabled = false;
			label.selectable = false;
			label.text = title;
			label.x = _margin;
			label.y = (_top += _marginV);
			label.height = 20;
			_top += label.height;
			addChild(label);
		}
		
		protected function addLabel(title:String, container:Sprite = null):void {
			var label:TextField = new TextField();
			label.defaultTextFormat = Global.textFormat;
			label.multiline = false;
			label.mouseEnabled = false;
			label.selectable = false;
			label.text = title;
			label.height = 20;
			if (container) {
				container.addChild(label);
			} else {
				label.x = _margin + 8;
				label.y = (_top += _marginV);
				_top += label.height;
				addChild(label);
			}
		}
		
		protected function addSlider(name:String, title:String, min:Number, max:Number, init:Number, precision:uint = 0, noUplimit:Boolean = false):Sprite {
			var container:Sprite = new Sprite();
			addChild(container);
			container.x = _margin + 8;
			container.y = (_top += _marginV);
			addLabel(title, container);
			var slider:Slider = new Slider();
			container.addChild(slider);
			slider.x = 6;
			slider.y = 25;
			var text:TextField = new TextField();
			text.height = 18;
			text.autoSize = TextFieldAutoSize.LEFT;
			text.maxChars = Math.max(max.toFixed(precision).length, min.toFixed(precision).length, 5);
			text.restrict = '\-\.0-9';
			text.type = TextFieldType.INPUT;
			text.border = true;
			text.background = true;
			text.borderColor = 0xA2A2A2;
			text.backgroundColor = 0xFAFAFA;
			container.addChild(text);
			text.x = 157;
			text.y = 15;
			text.textColor = 0x454545;
			slider.addEventListener(ImageEvent.SLIDER_CHANGE, function():void {
				text.text = toPrecision(slider.percent * (max - min) + min, precision);
				change(name, Number(text.text), false);
			});
			var oldValue:Number;
			slider.addEventListener(ImageEvent.DRAG_START, function():void {
				oldValue = Number(toPrecision(slider.percent * (max - min) + min, precision));
			});
			slider.addEventListener(ImageEvent.DRAG_END, function():void {
				var newValue:Number = Number(toPrecision(slider.percent * (max - min) + min, precision));
				if (_overlay && oldValue != newValue) {
					Global.container.log('OverlayChange', _overlay, name, oldValue, newValue);
				}
			});
			slider.addEventListener(Event.ADDED_TO_STAGE, function():void {
				slider.percent = (init - min) / (max - min);
				text.text = toPrecision(init, precision);
			});
			var _c:Function = function():void {
				var v:Number = Number(text.text);
				if (v < min) {
					v = min;
				} else if (!noUplimit && v > max) {
					v = max;
				}
				text.text = toPrecision(v, precision);
				slider.percent = (v - min) / (max - min);
				change(name, v);
			};
			text.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
				e.keyCode == 13 && _c();
			});
			text.addEventListener(FocusEvent.FOCUS_OUT, _c);
			addItem(name, init, function(value:*):void {
				if (value == null) {
					value = init;
				}
				slider.percent = (Number(value) - min) / (max - min);
				text.text = toPrecision(Number(value), precision);
			});
			_top += 30;
			return container;
		}
		
		protected function toPrecision(v:Number, p:uint = 0):String {
			if (int(v) != v && p) {
				return v.toFixed(p);
			} else {
				return int(v).toString();
			}
		}
		
		protected function addSeprator():void {
			var s:Bitmap = new SEPRATOR() as Bitmap;
			s.y = (_top += 5);
			s.x = _margin + 3;
			addChild(s);
			_top += s.height + 5;
		}
		
		
		protected function createTextButton(text:String, index:uint, func:Function):Sprite {
			var btn:Sprite = new Sprite();
			btn.graphics.beginFill(0, 0);
			btn.graphics.drawRect(0, 0, 60, 20);
			btn.graphics.endFill();
			var t:TextField = new TextField();
			t.defaultTextFormat = Global.textFormat;
			t.autoSize = TextFieldAutoSize.LEFT;
			t.text = text;
			t.mouseEnabled = false;
			btn.addChild(t);
			btn.buttonMode = true;
			t.y = (20 - t.textHeight) / 2;
			btn.addEventListener(MouseEvent.ROLL_OVER, function():void {
				t.setTextFormat(Global.textHoverFormat);
			});
			btn.addEventListener(MouseEvent.ROLL_OUT, function():void {
				t.setTextFormat(Global.textFormat);
			});
			btn.addEventListener(MouseEvent.CLICK, function():void {
				func(text);
			});
			btn.x = (index % 3) * 60;
			btn.y = Math.floor(index / 3) * 22;
			return btn;
		}
		
		private function createImageButton(item:Object, index:uint, func:Function):Sprite {
			var btn:Sprite = new Sprite();
			btn.graphics.beginFill(0xFFFFFF);
			btn.graphics.lineStyle(2, 0xBBBBBB);
			btn.graphics.drawRect(0, 0, 56, 56);
			btn.graphics.endFill();
			btn.addEventListener(MouseEvent.ROLL_OVER, function():void {
				btn.graphics.clear();
				btn.graphics.beginFill(0xFFFFFF);
				btn.graphics.lineStyle(2, 0x0066CC);
				btn.graphics.drawRect(0, 0, 56, 56);
				btn.graphics.endFill();
			});
			btn.addEventListener(MouseEvent.ROLL_OUT, function():void {
				btn.graphics.clear();
				btn.graphics.beginFill(0xFFFFFF);
				btn.graphics.lineStyle(2, 0xBBBBBB);
				btn.graphics.drawRect(0, 0, 56, 56);
				btn.graphics.endFill();
			});
			var loading:Animate = new Animate(20);
			btn.addChild(loading);
			loading.x = 28;
			loading.y = 28;
			XLoader.load(XLoader.IMAGE, new URLRequest(item.url), function(data:BitmapData, bytes:*):void{
				btn.removeChild(loading);
				var scale:Number = 54 / (data.width > data.height ? data.height : data.width);
				var mx:Matrix = new Matrix();
				mx.scale(scale, scale);
				var snap:BitmapData = new BitmapData(54, 54, true, 0xFFFFFF);
				snap.draw(data, mx);
				var bmp:Bitmap = new Bitmap(snap);
				btn.addChild(bmp);
				bmp.x = 1;
				bmp.y = 1;
				btn.addEventListener(MouseEvent.CLICK, function():void {
					func(data, uint(item.pos), item.alpha == null ? -1 : Number(item.alpha));
				});
			}, function(type:String, text:String):void{
				btn.removeChild(loading);
			});
			btn.buttonMode = true;
			btn.x = 1 + (index % 3) * 60;
			btn.y = 1 + Math.floor(index / 3) * 60;
			return btn;
		}
		
		protected function addTextList(url:String, func:Function, defaultSource:Array):void {
			var list:Sprite = new Sprite();
			var loading:Animate = new Animate(30);
			list.graphics.beginFill(0, 0);
			list.graphics.drawRect(0, 0, 180, 90);
			list.graphics.endFill();
			list.addChild(loading);
			loading.x = 90;
			loading.y = 20;
			var panel:ScrollPanel = new ScrollPanel(list, 90);
			addChild(panel);
			panel.x = _margin + 7;
			panel.y = (_top += _marginV);
			_top += 90;
			var data:URLVariables = new URLVariables();
			data[Global.authFieldName] = Global.authCookie;
			var request:URLRequest = new URLRequest(Global.getClientUrl(url, data));
			var showSource:Function = function(source:Array):void {
				source.forEach(function(item:String, index:uint, arr:Array) {
					list.addChild(createTextButton(item, index, func));
				});
				list.graphics.clear();
				list.graphics.beginFill(0, 0);
				list.graphics.drawRect(0, 0, 180, list.height);
				list.graphics.endFill();
				panel.adapt();
			};
			XLoader.load(XLoader.TEXT, request, function(content:*):void {
				list.removeChild(loading);
				showSource((content is Array) && content.length ? content as Array : defaultSource);
			}, function(type:String, text:String):void {
				list.removeChild(loading);
				showSource(defaultSource);
			});
		}
		
		protected function addImageList(url:String, func:Function):void {
			var list:Sprite = new Sprite();
			var loading:Animate = new Animate(30);
			list.graphics.beginFill(0, 0);
			list.graphics.drawRect(0, 0, 180, 120);
			list.graphics.endFill();
			list.addChild(loading);
			loading.x = 90;
			loading.y = 20;
			var panel:ScrollPanel = new ScrollPanel(list, 120);
			addChild(panel);
			panel.x = _margin + 7;
			panel.y = (_top += _marginV);
			_top += 120;
			var data:URLVariables = new URLVariables();
			data[Global.authFieldName] = Global.authCookie;
			var request:URLRequest = new URLRequest(Global.getClientUrl(url, data));
			XLoader.load(XLoader.TEXT, request, function(content:*):void {
				list.removeChild(loading);
				var json:Array = (content is Array) ? content as Array : null;
				if (json) {
					json.forEach(function(item:Object, index:uint, arr:Array) {
						list.addChild(createImageButton(item, index, func));
					});
					list.graphics.clear();
					list.graphics.beginFill(0, 0);
					list.graphics.drawRect(0, 0, 180, list.height);
					list.graphics.endFill();
					panel.adapt();
				}
			}, function(type:String, text:String):void {
				list.removeChild(loading);
			});
		}
		
		public function get panelName():String {
			return "PANEL";
		}
	}

}