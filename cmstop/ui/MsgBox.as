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
	import cmstop.Global;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	public class MsgBox extends Sprite 
	{
		[Embed (source = "/assets/button.png")]
		private const BUTTON:Class;
		
		private var _overlay:Boolean = false;
		private var _box:Sprite = null;
		private var _timer:Timer = new Timer(25);
		private var _escaped:uint = 0;
		private var _timeout:uint = 0;
		private static var _instance:MsgBox = null;
		
		public function MsgBox()
		{
			addEventListener(Event.ADDED_TO_STAGE, function():void {
				stage.addEventListener(Event.RESIZE, resize);
			});
			_timer.addEventListener(TimerEvent.TIMER, fadeOut);
		}
		public static function getInstance(stage:Stage):MsgBox {
			if (_instance) {
				stage.setChildIndex(_instance, stage.numChildren - 1);
			} else {
				_instance = new MsgBox();
				stage.addChild(_instance);
			}
			return _instance;
		}
		private function resize(e:Event):void {
			if (_overlay) {
				drawOverlay();
			}
		}
		public function confirm(text:String, yes:Function = null, no:Function = null):void {
			var t:TextField = createText(text, 160);
			var yesbtn:Button = createButton("确定");
			initBox(200, yesbtn.height + 50 + t.textHeight);
			showOverlay();
			_box.addChild(t);
			t.x = (200 - t.textWidth) / 2;
			t.y = 20;
			_box.addChild(yesbtn);
			yesbtn.y = t.y + t.textHeight + 10;
			yesbtn.addEventListener(MouseEvent.CLICK, function():void {
				hide();
				if (yes != null) {
					yes();
				}
			});
			if (no != null) {
				yesbtn.x = 20;
				var nobtn:Button = createButton("取消");
				_box.addChild(nobtn);
				nobtn.y = yesbtn.y;
				nobtn.x = 180 - nobtn.width;
				nobtn.addEventListener(MouseEvent.CLICK, function():void {
					hide();
					no();
				});
			} else {
				yesbtn.x = (200 - yesbtn.width) / 2;
			}
		}
		
		public function tip(text:String, timeout:uint = 1000):void {
			hideOverlay();
			var t:TextField = createText(text, 160);
			var h:Number = Math.max(60, t.textHeight);
			initBox(200, h);
			_box.addChild(t);
			t.x = (200 - t.textWidth) / 2;
			t.y = (h - t.textHeight) / 2;
			fade(timeout);
		}
		
		public function loading(text:String = null):void {
			var ani:Animate = new Animate(60, 0xFFFFFF);
			var w:Number = 100, h:Number = 100;
			var t:TextField = null;
			if (text) {
				t = createText(text, 160);
				w = 200;
				h = t.textHeight + 110;
			}
			initBox(w, h);
			showOverlay();
			_box.addChild(ani);
			ani.x = w / 2;
			ani.y = 50;
			if (t) {
				_box.addChild(t);
				t.x = (w - t.textWidth) / 2;
				t.y = 90;
			}
		}
		
		public function hide():void {
			_box.visible = false;
			clearBox();
			hideOverlay();
		}
		
		private function fadeOut(e:TimerEvent):void {
			_escaped += _timer.delay;
			if (_timeout == 0 || _escaped >= _timeout) {
				var a:Number = 1 - (_escaped - _timeout) / 1000;
				if (a < 0) {
					hide();
					_box.alpha = 1;
					_timer.reset();
				} else {
					_box.alpha = a;
				}
			}
			if (_escaped - _timeout > 2000) {
				_timer.reset();
			}
		}
		
		private function fade(timeout:uint = 0):void {
			_timer.reset();
			_box.alpha = 1;
			_escaped = 0;
			_timeout = timeout;
			_timer.start();
		}
		
		private function clearBox():void {
			_timer.reset();
			while (_box.numChildren > 0) {
				_box.removeChildAt(_box.numChildren-1);
			}
			_box.graphics.clear();
		}
		private function centerBox():void {
			_box.x = (stage.stageWidth - _box.width) / 2;
			_box.y = (stage.stageHeight - _box.height) / 2;
		}
		private function initBox(width:Number, height:Number):void {
			if (_box != null) {
				clearBox();
			} else {
				_box = new Sprite();
			}
			_box.graphics.beginFill(0, 0.6);
			_box.graphics.drawRoundRect(0, 0, Math.min(width, stage.stageWidth * .5), Math.min(height, stage.stageHeight * .5), 30);
			_box.graphics.endFill();
			addChild(_box);
			centerBox();
			_box.visible = true;
		}
		private function createText(text:String, width:Number):TextField {
			var t:TextField = new TextField();
			t.defaultTextFormat = Global.messageFormat;
			t.type = TextFieldType.DYNAMIC;
			t.width = width;
			t.multiline = true;
			t.wordWrap = true;
			t.text = text;
			return t;
		}
		private function createButton(text:String):Button {
			var btn:Button = new Button(new BUTTON() as Bitmap, 2);
			btn.setText(text, Global.textFormat)
				.addState(Button.STATE_HOVER, Global.textFormat, 1);
			return btn;
		}
		private function drawOverlay():void {
			this.graphics.clear();
			this.graphics.beginFill(0, 0);
			this.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			this.graphics.endFill();
		}
		private function showOverlay():void {
			if (!_overlay) {
				_overlay = true;
				drawOverlay();
			}
		}
		private function hideOverlay():void {
			_overlay = false;
			this.graphics.clear();
		}
	}
}