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
	import com.adobe.images.JPGEncoder;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.*;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class QualityControlPanel extends ControlPanel 
	{
		[Embed (source = "/assets/info-quality-black.png")]
		private const INFO_QUALITY:Class;
		private var _inited:Boolean = false;
		
		public function QualityControlPanel(width:Number=210) 
		{
			super(width);
		}
		
		override protected function init(e:Event):void {
			super.init(e);
			var s:Slider = addSlider("quality", "输出品质", 1, 100, Number(Global.defaultQuality)).getChildAt(1) as Slider;
			
			var icon:Bitmap = new INFO_QUALITY() as Bitmap;
			addChild(icon);
			icon.x = _margin + 9;
			icon.y = (_top += _marginV + 10);
			
			var text:TextField = new TextField();
			text.defaultTextFormat = Global.textFormat;
			text.autoSize = TextFieldAutoSize.LEFT;
			text.text = Global.formatByte(Global.container.bytes);
			text.selectable = false;
			addChild(text);
			text.x = _margin + 30;
			text.y = _top;
			
			var btn:Button = new Button(40, 16);
			btn.setText("估算", Global.textHoverFormat);
			btn.addEventListener(MouseEvent.CLICK, function():void{
				text.text = Global.formatByte((new JPGEncoder(quality)).encode(Global.container.bitmapData).length);
			});
			addChild(btn);
			btn.x = _margin + 80;
			btn.y = _top;
		}
		
		public function get quality():Number {
			return _params.quality.value;
		}
	}
}