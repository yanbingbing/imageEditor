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
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.setTimeout;
	
	public class CropControlPanel extends ControlPanel 
	{
		private var _container:CanvasContainer;
		private var _crop:Cropper;
		private var _canvas:Canvas;
		private var _w:TextField = null;
		private var _h:TextField;
		private var _ow:uint;
		private var _oh:uint;
		private var _r:CheckBox;
		private var _inited:Boolean = false;
		private var _visibleInited:Boolean = false;
		
		public function CropControlPanel(width:Number=210) 
		{
			super(width);
			_container = Global.container;
			if (_container.canvas) {
				initAfterCanvas();
			} else {
				_container.addEventListener(ImageEvent.CANVAS_INITED, initAfterCanvas);
			}
		}
		private function initAfterCanvas(e:ImageEvent = null):void {
			_canvas = _container.canvas;
			_inited = true;
			if (this.visible) {
				_crop = _container.showCrop();
				initOnceVisible();
			}
		}	
		private function initOnceVisible():void {
			_visibleInited = true;
			addTitle("裁剪区域");
			_w = addPxInput("宽");
			_h = addPxInput("高");
			var clip:Rectangle = _crop.clip;
			_ow = uint(clip.width);
			_oh = uint(clip.height);
			var nw:Number = _ow;
			var nh:Number = _oh;
			_w.text = _ow.toString();
			_h.text = _oh.toString();
			_crop.addEventListener(ImageEvent.PROP_CHANGE, function():void {
				clip = _crop.clip;
				_w.text = uint(clip.width).toString();
				_h.text = uint(clip.height).toString();
			});
			var ratio:Number = 0;
			_w.addEventListener(Event.CHANGE, function():void {
				nw = uint(_w.text);
				if (nw == _ow || nw <= 0 || nw > _canvas.bmpWidth || (ratio && (nw / ratio) > _canvas.bmpHeight)) {
					return;
				}
				_ow = nw;
				if (ratio && stage.focus != _h) {
					_oh = Math.round(_ow / ratio);
					_h.text = _oh.toString();
				}
				_container.showCrop(_ow * _canvas.scale, _oh * _canvas.scale);
			});
			_w.addEventListener(FocusEvent.FOCUS_OUT, function():void {
				nw = uint(_w.text);
				if (nw <= 0 || nw > _canvas.bmpWidth || (ratio && (nw / ratio) > _canvas.bmpHeight)) {
					_w.text = _ow.toString();
				} else {
					_w.text = uint(nw).toString();
				}
			});
			_h.addEventListener(Event.CHANGE, function():void {
				nh = uint(_h.text);
				if (nh == _oh || nh <= 0 || nh > _canvas.bmpHeight || (ratio && (nh * ratio) > _canvas.bmpWidth)) {
					return;
				}
				_oh = nh;
				if (ratio && stage.focus != _w) {
					_ow = Math.round(_oh * ratio);
					_w.text = _ow.toString();
				}
				_container.showCrop(_ow * _canvas.scale, _oh * _canvas.scale);
			});
			_h.addEventListener(FocusEvent.FOCUS_OUT, function():void {
				nh = uint(_h.text);
				if (nh <= 0 || nh > _canvas.bmpHeight || (ratio && (nh * ratio) > _canvas.bmpWidth)) {
					_h.text = _oh.toString();
				} else {
					_h.text = uint(nh).toString();
				}
			});
			
			_r = new CheckBox("约束比例");
			addChild(_r);
			_r.x = _margin + 8;
			_r.y = (_top += _marginV);
			_r.addEventListener(ImageEvent.VALUE_CHANGE, function():void {
				if (_r.checked) {
					ratio = _crop.fixRatio(true);
				} else {
					_crop.fixRatio(false);
					ratio = 0;
				}
			});
			var btn:Button = createButton("应用裁剪");
			btn.addEventListener(MouseEvent.CLICK, function() {
				if (_container.cropVisible) {
					_container.applyCrop();
				} else {
					_container.showCrop();
					clip = _crop.clip;
					_r.checked = false;
					_ow = uint(clip.width);
					_oh = uint(clip.height);
					_w.text = _ow.toString();
					_h.text = _oh.toString();
				}
			});
			addChild(btn);
			btn.x = _margin + 110;
			btn.y = _top;
			_top += btn.height;
			
			/*
			addSeprator();
			addTitle("预设尺寸");
			addTextList(Global.SIZE_LIST_URL, function(value:String):void{
				var size:Array = value.split('*');
				nw = Number(size[0]);
				nh = Number(size[1]);
				if (nw <= 0 || nh <= 0 || nw > _canvas.bmpWidth || nh > _canvas.bmpHeight) {
					return;
				}
				var c:Boolean = _r.checked;
				_r.checked = false;
				_w.text = toPrecision(nw);
				_h.text = toPrecision(nh);
				_ow = nw;
				_oh = nh;
				_container.showCrop(_ow * _canvas.scale, _oh * _canvas.scale);
				_r.checked = c;
			}, Global.DEFAULT_SIZES);
			*/
			
			addSeprator();
			addTitle("预设比例");
			addTextList(Global.ratioListUrl, function(value:String):void{
				var size:Array = value.split(':');
				nw = Number(size[0]);
				nh = Number(size[1]);
				if (nw <= 0 || nh <= 0) {
					return;
				}
				_r.checked = false;
				ratio = nw / nh;
				_container.showCrop(0, 0, ratio);
				clip = _crop.clip;
				_ow = uint(clip.width);
				_oh = uint(clip.height);
				_w.text = _ow.toString();
				_h.text = _oh.toString();
				_r.checked = true;
			}, Global.DEFAULT_RATIOS);
		}
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (_inited) {
				if (value) {
					_crop = _container.showCrop();
					if (_visibleInited) {
						var clip:Rectangle = _crop.clip;
						_r.checked = false;
						_ow = uint(clip.width);
						_oh = uint(clip.height);
						_w.text = _ow.toString();
						_h.text = _oh.toString();
					} else {
						initOnceVisible();
					}
				} else {
					_container.hideCrop();
				}
			}
		}
	}
}