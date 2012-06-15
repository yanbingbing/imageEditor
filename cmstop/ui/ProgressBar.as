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
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	public class ProgressBar extends MovieClip
	{
		public var percentText:TextField;
		public var bar:MovieClip;
		public function ProgressBar()
		{
			reset();
		}
		
		public function reset():void {
			bar.progress.x = 0;
			percentText.text = '0%';
		}
		
		public function update(percentage:Number):void {
			bar.progress.x = bar.progress.width * percentage;
			percentText.text = int(percentage * 100) + '%';
		}
	}
}