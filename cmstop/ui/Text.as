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
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.filters.BlurFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import fl.text.TLFTextField;
	import flash.text.TextFormatAlign;
	import flash.ui.MouseCursor;
	import flash.utils.setTimeout;
	
	public class Text extends Overlay
	{
		private var _txtInput:TLFTextField = new TLFTextField();
		private var _txt:TLFTextField;
		private var _oldTxt:TLFTextField;
		private var _oldRect:Rectangle;
		private var _ctrlSize:Sprite = new Sprite();
		private var _ctrlLayer:Sprite = new Sprite();
		private var _txtFormat:TextFormat;
		private var _firstEdit:Boolean = true;
		
		public function Text(container:CanvasContainer, panel:ControlPanel) 
		{
			super(container, panel);
			var size:Number = panel.getParam('fontSize') as Number;
			if (size < 24 / container.scale) {
				size = 24 / container.scale;
				panel.setParam('fontSize', size);
			}
			_txtFormat = _txtInput.getTextFormat();
			if (panel.getParam('fontName') == "None") {
				panel.setParam('fontName', _txtFormat.font);
			}
			_txtFormat.size = size;
			_txtFormat.align = TextFormatAlign.LEFT;
			_txtFormat.leftMargin = 10;
			_txtFormat.rightMargin = 10;
			_txtInput.type = TextFieldType.INPUT;
			_txtInput.autoSize = TextFieldAutoSize.LEFT;
			_txtInput.text = '';
			_txtInput.setTextFormat(_txtFormat);
			addChild(cloneTxt());
			
			_ctrlSize.addChild(_txtInput);
			_ctrlLayer.addChild(_ctrlSize);
			
			_params = {
				fontName:_txtFormat.font,
				fontColor:_txtFormat.color,
				fontSize:_txtFormat.size,
				fontBold:_txtFormat.bold,
				fontItalic:_txtFormat.italic,
				fontUnderline:_txtFormat.underline,
				fontAngle:0,
				fontAlpha:this.alpha,
				effectName:null,
				effectSize:null,
				effectColor:null,
				effectAlpha:null,
				effectAngle:null,
				effectDistance:null
			};
		}
		
		private function cloneTxt():TLFTextField {
			_txt = new TLFTextField();
			_txt.type = TextFieldType.DYNAMIC;
			_txt.selectable = false;
			_txt.autoSize = _txtInput.autoSize;
			_txt.text = _txtInput.text;
			_txt.setTextFormat(_txtInput.getTextFormat());
			_txt.filters = _txtInput.filters;
			return _txt;
		}
		
		override public function assoc(controller:Controller, layer:Sprite):void {
			super.assoc(controller, layer);
			_ctrlLayer.visible = false;
			_controller.fixRatio();
			_controlay.addChild(_ctrlLayer);
			_controller.addEventListener(ImageEvent.DOUBLE_CLICK, setEdit);
			_controller.addEventListener(ImageEvent.ROTATE_CHANGE, rotateChange);
		}
		public function setEdit(e:ImageEvent = null):void {
			_controller.setVisible(false);
			_ctrlLayer.visible = true;
			_oldTxt = getChildAt(0) as TLFTextField;
			_oldRect = _controller.rect;
			_txtInput.textFlow.interactionManager.setFocus();
			placeInput();
			setTimeout(function():void {
				root.stage.addEventListener(MouseEvent.MOUSE_DOWN, blur);
				_txtInput.addEventListener(Event.CHANGE, txtChange);
				_controller.addEventListener(ImageEvent.SCALE_CHANGE, placeInput);
			}, 0);
		}
		private function placeInput(e:ImageEvent = null):void {
			var rect:Rectangle = _controller.rect;
			_ctrlLayer.x = rect.x;
			_ctrlLayer.y = rect.y;
			_ctrlLayer.rotation = _controller.rotation;
			_ctrlSize.height = rect.height;
			_ctrlSize.width = rect.width;
			adaptInput();
		}
		private function adaptInput():void {
			_txtInput.x = -_txtInput.textWidth / 2;
			_txtInput.y = -_txtInput.textHeight / 2 + _txtInput.textHeight * .1;
			_ctrlLayer.graphics.clear();
			_ctrlLayer.graphics.beginFill(0xFFFFFF, 0.5);
			_ctrlLayer.graphics.lineStyle(0, 0x0099FF);
			_ctrlLayer.graphics.drawRect(-_ctrlSize.width / 2-5, -_ctrlSize.height / 2-5, _ctrlSize.width+10, _ctrlSize.height+10);
			_ctrlLayer.graphics.endFill();
		}
		private function rotateChange(e:ImageEvent):void {
			_params.fontAngle = _layer.rotation;
			_panel.overlay == this && _panel.setParam("fontAngle", _layer.rotation);
		}
		private function txtChange(e:Event):void {
			removeChildAt(0);
			addChild(cloneTxt());
			dispatchEvent(new ImageEvent(ImageEvent.PROP_CHANGE));
			adaptInput();
		}
		private function blur(e:MouseEvent):void {
			if (_ctrlLayer.contains(e.target as DisplayObject)) {
				return;
			}
			root.stage.removeEventListener(MouseEvent.MOUSE_DOWN, blur);
			_txtInput.removeEventListener(Event.CHANGE, txtChange);
			_controller.removeEventListener(ImageEvent.SCALE_CHANGE, placeInput);
			_ctrlLayer.visible = false;
			_controller.setVisible(true);
			
			removeChildAt(0);
			var newTxt:TLFTextField = cloneTxt();
			addChild(newTxt);
			
			if (Cursor.getCursor() == MouseCursor.IBEAM) {
				Cursor.reset();
			}
			dispatchEvent(new ImageEvent(ImageEvent.PROP_CHANGE, _txtInput.text ? null : "deleted"));
			e.updateAfterEvent();
			if (_firstEdit) {
				_firstEdit = false;
				_txtInput.text && _container.log('OverlayAdd', _controller, _layer, _controller.rect, _canvas.scale);
			} else {
				if (_oldTxt && newTxt.text != _oldTxt.text) {
					_container.log('TextChange', _controller, this, _oldTxt, newTxt, _oldRect, _controller.rect, _canvas.scale);
				}
				_oldTxt = null;
			}
		}
		/**
		 * internal for log
		 */
		public function setLogText(txt:TLFTextField):void {
			removeChildAt(0);
			_txt = txt;
			addChild(txt);
			_txtInput.text = txt.text;
			dispatchEvent(new ImageEvent(ImageEvent.PROP_CHANGE, txt.text ? (_layer.parent == null ? "added" : null) : "deleted"));
		}
		override protected function update():void {
			_txtFormat.size = _params.fontSize;
			_txtFormat.font = _params.fontName;
			_txtFormat.align = TextFormatAlign.LEFT;
			_txtFormat.color = _params.fontColor;
			_txtFormat.bold = _params.fontBold;
			_txtFormat.italic = _params.fontItalic;
			_txtFormat.underline = _params.fontUnderline;
			_txtInput.setTextFormat(_txtFormat);
			switch(_params.effectName) {
			case "Blur":
				_txtInput.filters = [new BlurFilter(_params.effectSize, _params.effectSize)];
				break;
			case "Glow":
				_txtInput.filters = [new GlowFilter(_params.effectColor, _params.effectAlpha, _params.effectSize, _params.effectSize)];
				break;
			case "DropShadow":
				_txtInput.filters = [new DropShadowFilter(_params.effectDistance, _params.effectAngle, _params.effectColor, _params.effectAlpha, _params.effectSize, _params.effectSize)];
				break;
			case "None": default:
				_txtInput.filters = [];
				break;
			}
			
			removeChildAt(0);
			addChild(cloneTxt());
			this.alpha = _params.fontAlpha;
			
			_layer.rotation = _params.fontAngle;
			dispatchEvent(new ImageEvent(ImageEvent.PROP_CHANGE));
		}
		
		public function set fontName(value:*):void {
			_params.fontName = value == null ? null : String(value);
		}
		public function set fontColor(value:*):void {
			_params.fontColor = value == null ? 0 : uint(value);
		}
		public function set fontSize(value:*):void {
			_params.fontSize = value == null ? null : uint(value);
		}
		public function set fontBold(value:*):void {
			_params.fontBold = value == null ? false : Boolean(value);
		}
		public function set fontItalic(value:*):void {
			_params.fontItalic = value == null ? false : Boolean(value);
		}
		public function set fontUnderline(value:*):void {
			_params.fontUnderline = value == null ? false : Boolean(value);
		}
		public function set fontAngle(value:*):void {
			_params.fontAngle = value == null ? 0 : Number(value);
		}
		public function set fontAlpha(value:*):void {
			_params.fontAlpha = value == null ? 1 : Number(value);
		}
		public function set effectName(value:*):void {
			_params.effectName = String(value);
		}
		public function set effectSize(value:*):void {
			_params.effectSize = value == null ? 4 : Number(value);
		}
		public function set effectColor(value:*):void {
			_params.effectColor = value == null ? 0 : String(value);
		}
		public function set effectAlpha(value:*):void {
			_params.effectAlpha = value == null ? 1 : Number(value);
		}
		public function set effectAngle(value:*):void {
			_params.effectAngle = value == null ? 0 : Number(value);
		}
		public function set effectDistance(value:*):void {
			_params.effectDistance = value == null ? 4 : Number(value);
		}
	}
}