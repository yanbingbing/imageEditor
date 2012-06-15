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
	import cmstop.ui.CanvasContainer;
	import cmstop.ui.ImageEditor;
	import com.adobe.serialization.json.JSON;
	import flash.external.ExternalInterface;
	import flash.net.URLVariables;
	import flash.text.TextFormat;
	
	public class Global 
	{
		public static const UPLOAD_FIELD_NAME:String = "file";
		
		public static const DEFAULT_SIZES:Array = ["90*90", "120*90", "320*320"];
		public static const DEFAULT_RATIOS:Array = ["1:1", "1:2", "2:1", "4:3", "3:4", "16:9", "9:16"];
		
		public static var editor:ImageEditor;
		public static var container:CanvasContainer;
		
		public static var params:Object;
		public static var clientHost:String;
		public static var clientPath:String;
		public static var authCookie:String;
		public static var authFieldName:String = "Auth-Cookie";
		public static var uploadFieldName:String = "file";
		public static var readFieldName:String = "file";
		public static var sizeListUrl:String = "?app=system&controller=imgeditor&action=getPresetSizes";
		public static var ratioListUrl:String = "?app=system&controller=imgeditor&action=getPresetRatio";
		public static var waterListUrl:String = "?app=system&controller=imgeditor&action=getWatermarkSchemes";
		public static var saveUrl:String = "?app=system&controller=imgeditor&action=saveImage";
		public static var readUrl:String = "?app=system&controller=imgeditor&action=loadImage";
		
		public static var messageFormat:TextFormat = new TextFormat("Microsoft YaHei, NSimSun, SimSun, STSong", 15, 0xFFFFFF);
		public static var tabFormat:TextFormat = new TextFormat("NSimSun, SimSun, STSong", 13, 0x666666, false);
		public static var tabHoverFormat:TextFormat = new TextFormat("NSimSun, SimSun, STSong", 13, 0x009DE6, false);
		public static var tabDisabledFormat:TextFormat = new TextFormat("NSimSun, SimSun, STSong", 13, 0x009DE6, true);
		public static var titleFormat:TextFormat = new TextFormat("NSimSun, SimSun, STSong", 13, 0x454545, true);
		public static var textFormat:TextFormat = new TextFormat("NSimSun, SimSun, STSong", 12, 0x454545);
		public static var textHoverFormat:TextFormat = new TextFormat("NSimSun, SimSun, STSong", 12, 0x009DE6);
		public static var textWhiteFormat:TextFormat = new TextFormat("NSimSun, SimSun, STSong", 12, 0xFFFFFF);
		public static var inputFormat:TextFormat = new TextFormat("NSimSun, SimSun, STSong", 12, null, null, null, null, null, null, null, 5, 5);
		
		private static var _r_protocol:RegExp = /^\w{3-5}:\/\//;
		
		public function Global()
		{
		}
		public static function getClientUrl(script:String, data:URLVariables = null):String {
			if (data) {
				script += (script.indexOf("?") != -1 ? "&" : "?") + data.toString();
			}
			if (_r_protocol.test(script)) {
				return script;
			}
			if (script.charAt(0) != "/") {
				var path:Array = clientPath.split("/");
				path[path.length - 1] = script.charAt(0) == "?"
					? (path[path.length - 1] + script)
					: script;
				script = path.join("/");
			}
			return clientHost + script;
		}
		
		public static function formatByte(bytes:Number):String {
			if (bytes < 1000) {
				return bytes + ' B';
			} else if ((bytes /= 1024) < 1000) {
				return bytes.toFixed(1) + ' KB';
			} else {
				return Number(bytes / 1024).toFixed(1) + ' M';
			}
		}
		public static function dump(val:*):void {
			trace(val);
			ExternalInterface.call("console.info("+JSON.encode(val)+")");
		}
		
		public static function trigger(evt:String, ...args):void {
			ExternalInterface.call('ImageEditor.trigger("' + params.guid + '", "' + evt + '", '+JSON.encode(args)+')');
		}
	}
}