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
package cmstop.events 
{
	import flash.events.Event;
	
	public class ImageEvent extends Event 
	{
		public static const DOUBLE_CLICK:String = "double_click";
		public static const CROP:String = "crop";
		public static const SCALE_CHANGE:String = "scale_change";
		public static const ROTATE_CHANGE:String = "rotate_change";
		public static const CANVAS_INITED:String = "canvas_inited";
		public static const SLIDER_CHANGE:String = "slider_change";
		public static const VALUE_CHANGE:String = "value_change";
		public static const PROP_CHANGE:String = "prop_change";
		public static const UPLOAD_COMPLETE:String = "upload_complete";
		public static const UPLOAD_ERROR:String = "upload_error";
		public static const BITMAPDATA_CHANGE:String = "bitmapdata_change";
		public static const HISTORY_CHANGE:String = "history_change";
		public static const DRAG_START:String = "drag_start";
		public static const DRAG_END:String = "drag_end";
		public var data:Object;
		public var where:Object;
		public function ImageEvent(type:String, data:Object = null, where:Object = null) 
		{
			super(type);
			this.data = data;
			this.where = where;
		}
	}
}