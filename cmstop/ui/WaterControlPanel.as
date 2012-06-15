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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	public class WaterControlPanel extends ControlPanel 
	{
		private var _browse:FileReference = new FileReference();
		private var _loader:Loader;
		private var _filter:Array = [new FileFilter("图片", "*.jpg;*.png;*.gif")];
		private var _container:CanvasContainer;
		
		public function WaterControlPanel(width:Number=210) 
		{
			super(width);
			_container = Global.container;
		}
		override protected function init(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			_browse.addEventListener(Event.COMPLETE, function():void {
				MsgBox.getInstance(stage).hide();
				_loader = new Loader();
				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
				try {
					_loader.loadBytes(_browse.data);
				} catch (e:Error) {
					MsgBox.getInstance(stage).tip("无效图片");
				}
			});
			_browse.addEventListener(IOErrorEvent.IO_ERROR, function():void {
				MsgBox.getInstance(stage).tip("读取文件错误");
			});
			_browse.addEventListener(Event.SELECT, function():void {
				MsgBox.getInstance(stage).loading();
				_browse.load();
			});
			addTitle("水印方案");
			addImageList(Global.waterListUrl, function(bmpData:BitmapData, pos:uint, alpha:Number):void{
				addWater(bmpData, pos-1, alpha);
			});
			
			var browser:Button = createButton("本地浏览");
			addChild(browser);
			browser.x = _margin + 110;
			browser.y = (_top += _marginV);
			_top += browser.height;
			browser.addEventListener(MouseEvent.CLICK, function():void {
				_browse.browse(_filter);
			});
			addSeprator();
			
			addTitle("水印控制");
			addLabel("位置");
			
			var hover:Function = function(item:Sprite) {
				item.graphics.clear();
				item.graphics.beginFill(0x6F6F6F);
				item.graphics.drawRect(0, 0, 48, 28);
				item.graphics.endFill();
			};
			var unhover:Function = function(item:Sprite) {
				item.graphics.clear();
				item.graphics.beginFill(0xAAAAAA);
				item.graphics.drawRect(0, 0, 48, 28);
				item.graphics.endFill();
			};
			var hoverIndex:int = -1;
			var position:Sprite = new Sprite();
			position.graphics.beginFill(0, 0);
			position.graphics.drawRect(0, 0, 150, 90);
			position.graphics.endFill();
			addChild(position);
			position.x = (_width - 150) / 2;
			position.y = (_top += _marginV);
			for (var i:uint = 0, p:Sprite; i < 9; i++) {
				p = new Sprite();
				unhover(p);
				position.addChild(p);
				p.buttonMode = true;
				p.x = (i % 3) * 51;
				p.y = Math.floor(i / 3) * 31;
			}
			position.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
				var index:int = -1;
				try {
					index = position.getChildIndex(e.target as DisplayObject);
				} catch (err:Error) { }
				if (hoverIndex > -1) {
					unhover(position.getChildAt(hoverIndex) as Sprite);
				}
				if (index > -1) {
					hover(position.getChildAt(index) as Sprite);
				}
				hoverIndex = index;
			});
			position.addEventListener(MouseEvent.ROLL_OUT, function():void {
				if (hoverIndex > -1) {
					unhover(position.getChildAt(hoverIndex) as Sprite);
				}
				hoverIndex = -1;
			});
			position.addEventListener(MouseEvent.CLICK, function():void {
				if (hoverIndex > -1) {
					if (hasAssoc()) {
						var controller:Controller = _overlay.controller;
						var oldRect:Rectangle = controller.rect;
						(_overlay as Water).setPosition(hoverIndex);
						_container.log('WaterPosition', controller, oldRect, controller.rect, _container.scale);
					}
				}
			});
			_top += 95;
			
			// 透明度滑杆
			var alpha:Sprite = addSlider("waterAlpha", "不透明度", 0, 1, 1, 2);
			
			// 角度滑杆
			var angle:Sprite = addSlider("waterAngle", "角度", -180, 180, 0);
		}
		
		private function loadComplete(e:Event):void {
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadComplete);
			var bmpData:BitmapData = new BitmapData(_loader.width, _loader.height, true, 0xFFFFFF);
			bmpData.draw(_loader);
			addWater(bmpData);
		}
		
		override public function get panelName():String {
			return "WATER";
		}
		
		public function addWater(bmpData:BitmapData, pos:uint = 4, alpha:Number = -1):void {
			unAssoc();
			var water:Water = new Water(bmpData, _container, this, alpha);
			Overlay.add(water, _container, this);
			water.setPosition(pos);
		}
	}
}