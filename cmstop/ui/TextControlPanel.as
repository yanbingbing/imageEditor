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
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.Font;
	
	public class TextControlPanel extends ControlPanel
	{
		private var _container:CanvasContainer;
		
		public function TextControlPanel(width:Number = 210) 
		{
			super(width);
			_container = Global.container;
		}
		override protected function init(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			addTitle("基本属性");
			addLabel("字体");
			
			// 字体
			var allFonts:Array = Font.enumerateFonts(true);
			var source:Array = [{
				name:"无",
				value:"None"
			}];
			allFonts.sortOn("fontName", Array.DESCENDING).forEach(function(item:Font, index:uint, arr:Array) {
				source.push({
					name:item.fontName,
					value:item.fontName
				});
			});
			var fontSelector:Selector = new Selector(source, "None", 150);
			addChild(fontSelector);
			fontSelector.x = _margin + 8;
			fontSelector.y = _top;
			addItem("fontName", fontSelector.value, function(value:*):void {
				fontSelector.value = value == null ? "None" : String(value);
			});
			fontSelector.addEventListener(ImageEvent.VALUE_CHANGE, function():void {
				change("fontName", fontSelector.value);
			});
			
			// 字体颜色
			var fontColor:ColorPanel = new ColorPanel();
			addChild(fontColor);
			fontColor.x = _margin + 163;
			fontColor.y = _top;
			addItem("fontColor", fontColor.value, function(value:*):void {
				fontColor.value = value == null ? 0 : uint(value);
			});
			fontColor.addEventListener(ImageEvent.VALUE_CHANGE, function():void {
				change("fontColor", fontColor.value);
			});
			_top += 23;
			
			// 字号滑杆
			addSlider("fontSize", "字号", 5, 72, 12, 0, true);
			
			// 角度滑杆
			addSlider("fontAngle", "角度", -180, 180, 0);
			
			// 透明度滑杆
			addSlider("fontAlpha", "不透明度", 0, 1, 1, 2);
			_top += 5;
			
			// 加粗 斜体 checkbox
			var b:CheckBox = new CheckBox("加粗");
			var i:CheckBox = new CheckBox("斜体");
			var u:CheckBox = new CheckBox("下划线");
			addChild(b);
			addChild(i);
			addChild(u);
			addItem("fontBold", false, function(value:*):void {
				b.checked = value == null ? false : Boolean(value);
			});
			addItem("fontItalic", false, function(value:*):void {
				i.checked = value == null ? false : Boolean(value);
			});
			addItem("fontUnderline", false, function(value:*):void {
				u.checked = value == null ? false : Boolean(value);
			});
			b.addEventListener(ImageEvent.VALUE_CHANGE, function():void {
				change("fontBold", b.checked);
			});
			i.addEventListener(ImageEvent.VALUE_CHANGE, function():void {
				change("fontItalic", i.checked);
			});
			u.addEventListener(ImageEvent.VALUE_CHANGE, function():void {
				change("fontUnderline", u.checked);
			});
			b.x = _margin + 8;
			b.y = (_top += _marginV);
			i.x = _margin + 63;
			i.y = _top;
			u.x = _margin + 118;
			u.y = _top;
			_top += b.height;
			addSeprator();
			
			addTitle("效果");
			addLabel("滤镜");
			
			// 滤镜选择器
			var effectSelector:Selector = new Selector([
				{ name:"无", value:"None"},
				{ name:"模糊", value:"Blur"}, // size
				{ name:"发光", value:"Glow"}, // size color alpha 
				{ name:"投影", value:"DropShadow"} // size color alpha angle distance
			], null, 150);
			addChild(effectSelector);
			effectSelector.x = _margin + 8;
			effectSelector.y = _top;
			addItem("effectName", effectSelector.value, function(value:*):void {
				effectSelector.value = value == null ? "None" : String(value);
			});
			
			// 滤镜颜色选择器
			var ecolor:ColorPanel = new ColorPanel();
			addChild(ecolor);
			ecolor.x = _margin + 97;
			ecolor.y = _top + 1;
			addItem("effectColor", ecolor.value, function(value:*):void {
				ecolor.value = value == null ? 0 :  uint(value);
			});
			ecolor.addEventListener(ImageEvent.VALUE_CHANGE, function():void {
				change("effectColor", ecolor.value);
			});
			_top += 20;
			
			// 滤镜大小滑杆
			var esize:Sprite = addSlider("effectSize", "大小", 1, 50, 4, 0, true);
			
			// 滤镜透明度滑杆
			var ealpha:Sprite = addSlider("effectAlpha", "不透明度", 0, 1, 1, 2);
			
			// 滤镜方向滑杆
			var eangle:Sprite = addSlider("effectAngle", "方向", 0, 360, 45);
			
			// 滤镜偏移滑杆
			var edistance:Sprite = addSlider("effectDistance", "偏移", 1, 50, 4, 1, true);
			
			
			effectSelector.addEventListener(ImageEvent.VALUE_CHANGE, function():void {
				change("effectName", effectSelector.value);
				switch(effectSelector.value) {
				case "None":
					esize.visible = false;
					ecolor.visible = false;
					ealpha.visible = false;
					eangle.visible = false;
					edistance.visible = false;
					break;
				case "Blur":
					esize.visible = true;
					ecolor.visible = false;
					ealpha.visible = false;
					eangle.visible = false;
					edistance.visible = false;
					break;
				case "Glow":
					esize.visible = true;
					ecolor.visible = true;
					ealpha.visible = true;
					eangle.visible = false;
					edistance.visible = false;
					break;
				case "DropShadow":
					esize.visible = true;
					ecolor.visible = true;
					ealpha.visible = true;
					eangle.visible = true;
					edistance.visible = true;
					break;
				}
			});
			effectSelector.value = "None";
		}
		
		public function addText(pos:Point):void {
			var text:Text = new Text(_container, this);
			Overlay.add(text, _container, this, pos);
			text.setEdit();
		}
		
		override public function get panelName():String {
			return "TEXT";
		}
	}
}