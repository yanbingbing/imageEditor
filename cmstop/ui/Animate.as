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
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class Animate extends Sprite 
	{
		private const PI_1:Number = Math.PI / 180;
		
		public function Animate(size:Number = 60, color:uint = 0) 
		{
			var w:Number = 3 * size / 10;
			var h:Number = w / 4;
			var r:Number = 7 * size / 20;
			for (var i:uint = 0; i < 12; i++) {
				addShape(w, h, r, i * 30, color);
			}
			var t:Timer = new Timer(80);
			t.addEventListener(TimerEvent.TIMER, run);
			t.start();
		}
		private function run(e:TimerEvent):void {
			this.rotation += 30;
		}
		private function addShape(w:Number, h:Number, r:Number, a:Number, color:uint):void {
			var s:Shape = new Shape();
			s.graphics.beginFill(color,  a / 360);
			s.graphics.drawRoundRect( -w / 2, -h / 2, w, h, h);
			s.graphics.endFill();
			addChild(s);
			s.rotation = a;
			s.x = r * Math.cos(a * PI_1);
			s.y = r * Math.sin(a * PI_1);
		}
	}
}