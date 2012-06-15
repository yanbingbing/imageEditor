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
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	
	public class CheckBox extends Sprite 
	{
		[Embed (source = "/assets/icon-checkbox.png")]
		private const ICON_CHECKBOX:Class;
		
		private var _checked:Boolean = false;
		private var _button:Button;
		
		public function CheckBox(title:String, checked:Boolean = false) 
		{
			var bmp:Bitmap = new ICON_CHECKBOX() as Bitmap;
			_button = new Button(20 + title.length * 15, 22);
			/*
			_button.setIconImage(bmp, 2).setText(title, new TextFormat("NSimSun, SimSun, STSong", 13, 0x454545))
				.addState(Button.STATE_ACTIVED, new TextFormat("NSimSun, SimSun, STSong", 13, 0x454545), 1);*/
			_button.setIconImage(bmp, 2).setText(title, Global.textFormat)
				.addState(Button.STATE_ACTIVED, Global.textFormat, 1);
			addChild(_button);
			addEventListener(MouseEvent.CLICK, onClick);
			this.checked = checked;
		}
		private function onClick(e:MouseEvent):void {
			this.checked = !_checked;
		}
		
		public function get checked():Boolean {
			return _checked;
		}
		public function set checked(v:Boolean):void {
			var o:Boolean = _checked;
			if (v) {
				_button.state = Button.STATE_ACTIVED;
				_checked = true;
			} else {
				_button.state = Button.STATE_DEFAULT;
				_checked = false;
			}
			if (v != o) {
				dispatchEvent(new ImageEvent(ImageEvent.VALUE_CHANGE, v));
			}
		}
	}
}