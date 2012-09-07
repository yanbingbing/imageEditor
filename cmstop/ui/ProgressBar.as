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
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	public class ProgressBar extends Sprite
	{
		private static const BAR_WIDTH:Number = 200;
		private static const BAR_HEIGHT:Number = 30;
		
		private var _percentText:TextField;
		private var _bar:Sprite;
		private var _barProgress:Shape;
		
		public function ProgressBar()
		{
			var bg:Shape = new Shape();
			bg.graphics.beginFill(0x404040, .7);
			bg.graphics.drawRoundRect(-125, -50, 250, 100, 20);
			bg.graphics.endFill();
			addChild(bg);
			initBar();
			_percentText = new TextField();
			_percentText.width = 50;
			_percentText.height = 24;
			_percentText.x = -25;
			var format:TextFormat = _percentText.getTextFormat();
			format.size = 18;
			format.color = 0xE88543;
			format.align = TextFormatAlign.CENTER;
			_percentText.setTextFormat(format);
			addChild(_percentText);
			_percentText.x = 0;
			_percentText.y = 0;
			_percentText.type = TextFieldType.DYNAMIC;
			reset();
		}
		
		private function initBar():void {
			_bar = new Sprite();
			addChild(_bar);
			_bar.x = 0;
			_bar.y = 0;
			var bg:Shape = new Shape();
			bg.graphics.beginFill(0, .3);
			bg.graphics.lineStyle(2, 0x666666);
			bg.graphics.drawRoundRect(-(BAR_WIDTH+4)/2, -(BAR_HEIGHT+4)/2, BAR_WIDTH+4, BAR_HEIGHT+4, BAR_HEIGHT+4);
			bg.graphics.endFill();
			_bar.addChild(bg);
			bg.x = 0;
			bg.y = 0;
			_barProgress = new Shape();
			_bar.addChild(_barProgress);
			_barProgress.x = -BAR_WIDTH/2;
			_barProgress.y = -BAR_HEIGHT/2;
		}
		
		private function setProgress(width:Number):void {
			_barProgress.graphics.clear();
			if (width <= 0) {
				return;
			}
			_barProgress.graphics.beginFill(0xFFFFFF);
			_barProgress.graphics.drawRoundRect(0, 0, width, BAR_HEIGHT, BAR_HEIGHT);
			_barProgress.graphics.endFill();
		}
		
		public function reset():void {
			setProgress(0);
			_percentText.text = '0%';
		}
		
		public function update(percentage:Number):void {
			setProgress(BAR_WIDTH * percentage);
			cmstop.Global.dump(percentage);
			_percentText.text = int(percentage * 100) + '%';
			
		}
	}
}