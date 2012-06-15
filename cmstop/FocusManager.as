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
package cmstop 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	
	public class FocusManager 
	{
		private static var _stack:Vector.<DisplayObjectContainer> = new Vector.<DisplayObjectContainer>();
		private static var _assoc:Vector.<DisplayObjectContainer> = new Vector.<DisplayObjectContainer>();
		private static var _blur:Vector.<Function> = new Vector.<Function>();
		private static var _stage:Stage = null;
		public function FocusManager() 
		{
			return;
		}
		
		public static function init(stage:Stage):void {
			_stage = stage;
			stage.stageFocusRect = false;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
				focus(e.target as DisplayObject);
			});
		}
		
		public static function focus(t:DisplayObject):void {
			_stack.forEach(function(item:DisplayObjectContainer, index:int, vec:Vector.<DisplayObjectContainer>):void {
				if (item.contains(t)) {
					if (t is InteractiveObject) {
						_stage.focus = t as InteractiveObject;
					} else {
						_stage.focus = t.parent;
					}
					return;
				}
				if (_assoc[index] && _assoc[index].contains(t)) {
					_stage.focus = item;
					return;
				}
				item.visible && _blur[index]();
			});
		}
		
		public static function addItem(item:DisplayObjectContainer, assoc:DisplayObjectContainer = null, blur:Function = null):void {
			_stack.push(item);
			_assoc.push(assoc);
			if (blur == null) {
				blur = function() {
					item.visible = false;
				};
			}
			_blur.push(blur);
		}
	}
}