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
package cmstop.ui {
	
	import cmstop.FocusManager;
	import cmstop.Global;
	import cmstop.Uploader;
	import cmstop.XLoader;
	import cmstop.events.ImageEvent;
	
	import com.adobe.images.JPGEncoder;
	import com.adobe.images.PNGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	public class ImageEditor extends Sprite {
		[Embed (source = "/assets/top-panel.png")]
		private const TOP_PANEL:Class;
		private var _bgTopPanel:BitmapData;
		[Embed (source = "/assets/left-panel.png")]
		private const LEFT_PANEL:Class;
		private var _bgLeftPanel:BitmapData;
		
		[Embed (source = "/assets/icon-save.png")]
		private const ICON_SAVE:Class;
		
		[Embed (source = "/assets/icon-crop.png")]
		private const ICON_CROP:Class;
		[Embed (source = "/assets/icon-resize.png")]
		private const ICON_RESIZE:Class;
		[Embed (source = "/assets/icon-rotate.png")]
		private const ICON_ROTATE:Class;
		[Embed (source = "/assets/icon-water.png")]
		private const ICON_WATER:Class;
		[Embed (source = "/assets/icon-text.png")]
		private const ICON_TEXT:Class;
		[Embed (source = "/assets/icon-quality.png")]
		private const ICON_QUALITY:Class;
		
		[Embed (source = "/assets/icon-undo.png")]
		private const ICON_UNDO:Class;
		[Embed (source = "/assets/icon-redo.png")]
		private const ICON_REDO:Class;
		[Embed (source = "/assets/icon-fullscreen.png")]
		private const ICON_FULLSCREEN:Class;
		[Embed (source = "/assets/icon-close.png")]
		private const ICON_CLOSE:Class;
		
		[Embed (source = "/assets/icon-zoomin.png")]
		private const ICON_ZOOMIN:Class;
		[Embed (source = "/assets/icon-zoomout.png")]
		private const ICON_ZOOMOUT:Class;
		[Embed (source = "/assets/icon-adapt.png")]
		private const ICON_ADAPT:Class;
		[Embed (source = "/assets/cmstop.png")]
		private const CMSTOP:Class;
		
		[Embed (source = "/assets/info-size.png")]
		private const INFO_SIZE:Class;
		
		private var _stageWidth:Number;
		private var _stageHeight:Number;
		
		private var _topPanel:Sprite;
		private var _leftPanel:Sprite;
		private var _bottomPanel:Sprite;
		private var _container:CanvasContainer;
		private var _canvas:Canvas;
		private var _topLeftArea:Sprite;
		private var _tabArea:Sprite;
		private var _topRightArea:Sprite;
		private var _controlArea:Sprite;
		private var _copyArea:Sprite;
		
		private var _topPanelWidth:Number = 0;
		private var _topPanelHeight:Number = 0;
		private var _leftPanelWidth:Number = 0;
		private var _bottomPanelHeight:Number = 0;
		private var _bottomPanelWidth:Number = 0;
		
		private var _setupTimer:Timer = new Timer(500, 0);
		
		private var _tabOrder:Array = ["CROP", "RESIZE", "WATER", "TEXT", "ROTATE", "QUALITY"];
		private var _tabGroup:Object = {
			ROTATE  : "旋转",
			CROP    : "裁剪",
			RESIZE  : "缩放",
			WATER   : "水印",
			TEXT    : "文字",
			QUALITY : "品质"
		};
		
		private var _saveType:String = "JPEG";
		private var _uploader:Uploader = null;
		private var _inUpload:Boolean = false;
		
		private var _focusedTab:String = null;
		
		private var _willTextActived:Boolean = false;
		
		public function ImageEditor() {
			Security.allowDomain("*");
            Security.allowInsecureDomain("*");
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			Global.params = stage.loaderInfo.parameters;
			
			var menu:ContextMenu= new ContextMenu();
			menu.hideBuiltInItems();
			var menuItem:ContextMenuItem = new ContextMenuItem("CmsTop Image Editor 0.92", false, true);
			menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, goCmsTop);
			menu.customItems.push(menuItem);
			this.contextMenu = menu;
			
			_setupTimer.addEventListener(TimerEvent.TIMER, setupExternalInterface);
			_setupTimer.start();
			stage.stageWidth > 0 && setupExternalInterface();
		}
		
		private function setup():void {
			MsgBox.getInstance(stage).loading();
			var client:Array = null;
			try {
				client = ExternalInterface.call('eval', '(function(){return [document.cookie, location.host, location.protocol, location.pathname];})()') as Array;
			} catch (e:Error) {}
			if (client == null) {
				MsgBox.getInstance(stage).confirm("无法与浏览器交互，请检查配置");
				return;
			}
			Global.authCookie = client[0];
			Global.clientHost = client[2] + "//" + client[1];
			Global.clientPath = client[3];
			
			var request:URLRequest = new URLRequest(Global.getClientUrl(Global.params.config || 'imageEditor.conf'));
			
			XLoader.load(XLoader.TEXT, request, function(config:Object):void {
				var fields:Array = [
					"authFieldName", "readFieldName", "uploadFieldName", "sizeListUrl",
					"ratioListUrl", "waterListUrl", "saveUrl", "readUrl", "defaultQuality" ];
				for each (var key:String in fields) {
					if ((key in config) && config[key]) {
						Global[key] = String(config[key]);
					}
				}
				init();
			}, function(type:String, text:String):void{
				MsgBox.getInstance(stage).confirm("配置失败 ["+type+":"+text+"]");
			});
		}
		
		
		private function init():void {
			FocusManager.init(root.stage);
			
			_topPanel = new Sprite();
			_leftPanel = new Sprite();
			_bottomPanel = new Sprite();
			_container = new CanvasContainer();
			_topLeftArea = new Sprite();
			_tabArea =  new Sprite();
			_topRightArea = new Sprite();
			_controlArea = new Sprite();
			_copyArea = new Sprite();
			
			Global.editor = this;
			Global.container = _container;
			
			_bgTopPanel = (new TOP_PANEL() as Bitmap).bitmapData;
			_bgLeftPanel = (new LEFT_PANEL() as Bitmap).bitmapData;
			_topPanelHeight = _bgTopPanel.height;
			_leftPanelWidth = _bgLeftPanel.width;
			_bottomPanelHeight = 28;
			
			addChild(_container);
			addChild(_topPanel);
			addChild(_leftPanel);
			addChild(_bottomPanel);
			_leftPanel.y = _topPanelHeight;
			_container.x = _leftPanelWidth;
			_container.y = _topPanelHeight;
			
			_topPanel.addChild(_topLeftArea);
			_topPanel.addChild(_tabArea);
			_topPanel.addChild(_topRightArea);
			_bottomPanel.addChild(_controlArea);
			_bottomPanel.addChild(_copyArea);
			
			_topLeftArea.x = 5;
			
			setStageSize();
			
			drawPanel();
			initTopRightArea();
			initCopyArea();
			
			adaptWindow();
			
			stage.addEventListener(Event.RESIZE, function():void {
				setStageSize();
				drawPanel();
				adaptWindow();
			});
			
			MsgBox.getInstance(stage).hide();
			var file:String = String(Global.params.file);
			
			if (!file) {
				MsgBox.getInstance(stage).confirm("没有对象");
				return;
			}
			var i:int = file.lastIndexOf('.');
			if (i > 0 && file.substr(i + 1).toLowerCase() == "png") {
				_saveType = "PNG";
				_tabOrder.pop();
			} else {
				_saveType = "JPEG";
			}
			var data:URLVariables = new URLVariables();
			data[Global.readFieldName] = file;
			data[Global.authFieldName] = Global.authCookie;
			_container.loadPicture(Global.getClientUrl(Global.readUrl, data));
			_container.addEventListener(ImageEvent.CANVAS_INITED, function():void {
				_canvas = _container.canvas;
				
				initTopLeftArea();
				initTabArea();
				initInfoArea();
				initControlArea();
				adaptWindow();
				
				focusTab("CROP");
				_canvas.addEventListener(MouseEvent.MOUSE_DOWN, onCanvasDown);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			});
		}
		private function setStageSize():void {
			_stageHeight = stage.stageHeight;
			if (_stageHeight < 500) {
				_stageHeight = 500;
			}
			_stageWidth = stage.stageWidth;
			if (_stageWidth < 700) {
				_stageWidth = 700;
			}
		}
		
		private function drawPanel():void {
			_topPanelWidth = _stageWidth;
			_bottomPanelWidth = _stageWidth;
			_topPanel.graphics.clear();
			_topPanel.graphics.beginBitmapFill(_bgTopPanel);
			_topPanel.graphics.drawRect(0, 0, _topPanelWidth, _topPanelHeight);
			_topPanel.graphics.endFill();
			_topPanel.scrollRect = new Rectangle(0, 0, _topPanelWidth, _topPanelHeight);
			_leftPanel.graphics.clear();
			_leftPanel.graphics.beginBitmapFill(_bgLeftPanel);
			_leftPanel.graphics.drawRect(0, 0, _leftPanelWidth, _stageHeight);
			_leftPanel.graphics.endFill();
			_bottomPanel.graphics.clear();
			_bottomPanel.graphics.beginFill(0x222222);
			_bottomPanel.graphics.drawRect(0, 0, _bottomPanelWidth , _bottomPanelWidth);
			_bottomPanel.graphics.endFill();
			_bottomPanel.scrollRect = new Rectangle(0, 0, _bottomPanelWidth, _bottomPanelHeight);
		}
		
		private function adaptWindow(e:Event=null):void {
			_bottomPanel.y = _stageHeight - _bottomPanelHeight;
			_container.setSize(_stageWidth - _leftPanelWidth, _stageHeight - _bottomPanelHeight - _topPanelHeight);
			_tabArea.x = (_topPanelWidth - _tabArea.width) / 2;
			_topRightArea.x = (_topPanelWidth - _topRightArea.width - 5);
			_controlArea.x = (_bottomPanelWidth - _leftPanelWidth - _controlArea.width) / 2 + _leftPanelWidth;
			_copyArea.x = _bottomPanelWidth - _copyArea.width - 5;
		}
		
		private function initTopLeftArea():void {
			var btn:Button = new Button(new ICON_SAVE() as Bitmap);
			_topLeftArea.addChild(btn);
			btn.y = (_topPanelHeight - btn.height) / 2;
			btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				doSave();
				e.updateAfterEvent();
			});
		}
		
		private function initTopRightArea():void {
			var undo:Button = new Button(new ICON_UNDO() as Bitmap, 3);
			undo.addState(Button.STATE_HOVER, null, -1, 1).addState(Button.STATE_DISABLED, null, -1, 2);
			_topRightArea.addChild(undo);
			undo.y = (_topPanelHeight - undo.height) / 2;
			undo.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_container.undo();
				e.updateAfterEvent();
			});
			undo.state = Button.STATE_DISABLED;
			
			
			var redo:Button = new Button(new ICON_REDO() as Bitmap, 3);
			redo.addState(Button.STATE_HOVER, null, -1, 1).addState(Button.STATE_DISABLED, null, -1, 2);
			_topRightArea.addChild(redo);
			redo.y = (_topPanelHeight - redo.height) / 2;
			redo.x = undo.width;
			redo.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_container.redo();
				e.updateAfterEvent();
			});
			redo.state = Button.STATE_DISABLED;
			
			_container.addEventListener(ImageEvent.HISTORY_CHANGE, function():void{
				undo.state = _container.canUndo() ? Button.STATE_DEFAULT : Button.STATE_DISABLED;
				redo.state = _container.canRedo() ? Button.STATE_DEFAULT : Button.STATE_DISABLED;
			});
			
			var fullscreen:Button = new Button(new ICON_FULLSCREEN() as Bitmap, 4);
			fullscreen.addState(Button.STATE_HOVER, null, -1, 1)
				.addState(Button.STATE_ACTIVED, null, -1, 2)
				.addState(Button.STATE_ACTIVED_HOVER, null, -1, 3);
			_topRightArea.addChild(fullscreen);
			fullscreen.addEventListener(MouseEvent.CLICK, function():void{
				switch(stage.displayState) {
				case StageDisplayState.NORMAL:
					stage.displayState = StageDisplayState.FULL_SCREEN;    
					break;
				case StageDisplayState.FULL_SCREEN: default:
					stage.displayState = StageDisplayState.NORMAL;    
					break;
				}
			});
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, function():void{
				fullscreen.state = stage.displayState == StageDisplayState.FULL_SCREEN ? Button.STATE_ACTIVED : Button.STATE_DEFAULT;
			});
			fullscreen.y = (_topPanelHeight - fullscreen.height) / 2;
			fullscreen.x = redo.x + redo.width + 5;
			
			var close:Button = new Button(new ICON_CLOSE() as Bitmap, 2);
			close.addState(Button.STATE_HOVER, null, -1, 1);
			_topRightArea.addChild(close);
			close.y = (_topPanelHeight - close.height) / 2;
			close.x = fullscreen.x + fullscreen.width + 5;
			close.addEventListener(MouseEvent.CLICK, onClickClose);
		}
		
		private function initInfoArea():void {
			var infoSZ:Bitmap = new INFO_SIZE() as Bitmap;
			_bottomPanel.addChild(infoSZ);
			infoSZ.x = 8;
			infoSZ.y = (_bottomPanelHeight - infoSZ.height) / 2;
			var infoSize:TextField = new TextField();
			infoSize.selectable = false;
			infoSize.autoSize = TextFieldAutoSize.LEFT;
			infoSize.defaultTextFormat = Global.textWhiteFormat;
			infoSize.text = _canvas.bmpWidth + '×' + _canvas.bmpHeight + ' px';
			_bottomPanel.addChild(infoSize);
			infoSize.x = 28;
			infoSize.y = (_bottomPanelHeight - infoSize.textHeight) / 2;
			_container.addEventListener(ImageEvent.BITMAPDATA_CHANGE, function():void{
				infoSize.text = _canvas.bmpWidth + '×' + _canvas.bmpHeight + ' px';
			});
		}
		
		private function initCopyArea():void {
			var copy:Bitmap = new CMSTOP() as Bitmap;
			_copyArea.addChild(copy);
			_copyArea.buttonMode = true;
			copy.y = (_bottomPanelHeight - copy.height) / 2;
			_copyArea.addEventListener(MouseEvent.CLICK, goCmsTop);
		}
		
		private function goCmsTop(e:Event):void {
			navigateToURL(new URLRequest("http://www.cmstop.com"), "_blank");
		}
		
		private function initControlArea():void {
			
			var zoomout:Button = new Button(new ICON_ZOOMOUT() as Bitmap, 2);
			zoomout.addState(Button.STATE_HOVER, null, -1, 1);
			_controlArea.addChild(zoomout);
			zoomout.y = (_bottomPanelHeight - zoomout.height) / 2;
			zoomout.addEventListener(MouseEvent.CLICK, function():void {
				_container.setScale(_container.scale - 0.1);
			});
			
			var zoom:Slider = new Slider();
			zoom.addEventListener(ImageEvent.SLIDER_CHANGE, function(e:ImageEvent):void {
				_container.setScale((e.data as Number) * (_container.maxScale - _container.minScale) + _container.minScale, zoom);
			});
			_controlArea.addChild(zoom);
			zoom.y = _bottomPanelHeight / 2;
			zoom.x = zoomout.width + 12;
			
			var zoomin:Button = new Button(new ICON_ZOOMIN() as Bitmap, 2);
			zoomin.addState(Button.STATE_HOVER, null, -1, 1);
			_controlArea.addChild(zoomin);
			zoomin.y = (_bottomPanelHeight - zoomin.height) / 2;
			zoomin.x = zoom.x + zoom.width;
			zoomin.addEventListener(MouseEvent.CLICK, function():void {
				_container.setScale(_container.scale + 0.1);
			});
			
			var adapt:Button = new Button(new ICON_ADAPT() as Bitmap, 4);
			adapt.addState(Button.STATE_HOVER, null, -1, 1)
				.addState(Button.STATE_ACTIVED, null, -1, 2)
				.addState(Button.STATE_ACTIVED_HOVER, null, -1, 3);
			_controlArea.addChild(adapt);
			adapt.y = (_bottomPanelHeight - adapt.height) / 2;
			adapt.x = zoomin.x + zoomin.width + 15;
			adapt.addEventListener(MouseEvent.CLICK, function():void {
				switch(adapt.state) {
				case Button.STATE_DEFAULT:
					adapt.state = Button.STATE_ACTIVED;
					_container.setScale(1, adapt);
					break;
				case Button.STATE_HOVER:
					adapt.state = Button.STATE_ACTIVED_HOVER;
					_container.setScale(1, adapt);
					break;
				case Button.STATE_ACTIVED:
					adapt.state = Button.STATE_DEFAULT;
					_container.setScale(_container.minScale, adapt);
					break;
				case Button.STATE_ACTIVED_HOVER: default:
					adapt.state = Button.STATE_HOVER;
					_container.setScale(_container.minScale, adapt);
					break;
				}
			});
			
			_container.addEventListener(ImageEvent.SCALE_CHANGE, function(e:ImageEvent):void {
				var t:DisplayObject = e.where as DisplayObject;
				if (t==null || !zoom.contains(t)) {
					zoom.percent = (_container.scale - _container.minScale) / (_container.maxScale - _container.minScale);
				}
				if (t==null || !adapt.contains(t)) {
					if (_container.scale == _container.minScale) {
						adapt.state = Button.STATE_DEFAULT;
					} else {
						adapt.state = Button.STATE_ACTIVED;
					}
				}
			});
		}
		private function initTabArea():void {
			for (var i:uint = 0; i < _tabOrder.length; i++) {
				initTab(_tabOrder[i]);
			}
		}
		
		private function initTab(label:String):void {
			var button:Button = createTabButton(label, _tabGroup[label]);
			_tabGroup[label] = {
				button:button,
				panel:null
			};
			button.addEventListener(MouseEvent.CLICK, function():void {
				focusTab(label);
			});
		}
		
		private function createTabButton(label:String, text:String):Button {
			var icon:Bitmap = new this["ICON_" + label]() as Bitmap;
			var button:Button = new Button(65, 30);
			button.setIconImage(icon, 3)
			   .setText(text, Global.tabFormat)
			   .addState(Button.STATE_HOVER, Global.tabHoverFormat, 1)
			   .addState(Button.STATE_DISABLED, Global.tabDisabledFormat, 2);
			var numChildren:uint = _tabArea.numChildren;
			if (numChildren > 0) {
				var lastChild:DisplayObject = _tabArea.getChildAt(numChildren - 1);
				button.x = lastChild.x + lastChild.width + 2;
			} else {
				button.x = 0;
			}
			button.y = (_topPanelHeight - button.height) / 2;
			_tabArea.addChild(button);
			return button;
		}
		
		public function focusTab(label:String):void {
			if (label == _focusedTab) {
				return;
			}
			if (_focusedTab) {
				(_tabGroup[_focusedTab].panel as ControlPanel).visible = false;
				(_tabGroup[_focusedTab].button as Button).state = Button.STATE_DEFAULT;
				if (_tabGroup[_focusedTab].blur is Function) {
					_tabGroup[_focusedTab].blur();
				}
			}
			var panel:ControlPanel = _tabGroup[label].panel as ControlPanel;
			if (panel == null) {
				panel = this["init" + label + "Panel"]();
				_tabGroup[label].panel = panel;
			} else {
				panel.visible = true;
			}
			if (_tabGroup[label].focus is Function) {
				_tabGroup[label].focus();
			}
			(_tabGroup[label].button as Button).state = Button.STATE_DISABLED;
			_focusedTab = label;
		}
		
		private function initCROPPanel():CropControlPanel {
			var panel:CropControlPanel = new CropControlPanel();
			_leftPanel.addChild(panel);
			return panel;
		}
		private function initRESIZEPanel():ResizeControlPanel {
			var panel:ResizeControlPanel = new ResizeControlPanel();
			_leftPanel.addChild(panel);
			return panel;
		}
		private function initROTATEPanel():RotateControlPanel {
			var panel:RotateControlPanel = new RotateControlPanel();
			_leftPanel.addChild(panel);
			return panel;
		}
		private function initWATERPanel():WaterControlPanel {
			var panel:WaterControlPanel = new WaterControlPanel();
			_leftPanel.addChild(panel);
			return panel;
		}
		private function initTEXTPanel():TextControlPanel {
			var panel:TextControlPanel = new TextControlPanel();
			_tabGroup["TEXT"].blur = onBlurText;
			_tabGroup["TEXT"].focus = onFocusText;
			_leftPanel.addChild(panel);
			return panel;
		}
		private function initQUALITYPanel():QualityControlPanel {
			var panel:QualityControlPanel = new QualityControlPanel();
			_leftPanel.addChild(panel);
			return panel;
		}
		private function onFocusText():void {
			_canvas.addEventListener(MouseEvent.MOUSE_OVER, wantText);
		}
		private function onBlurText():void {
			_canvas.removeEventListener(MouseEvent.MOUSE_OVER, wantText);
			(_tabGroup["TEXT"].panel as ControlPanel).unAssoc();
			activeWantText(false);
		}
		private function wantText(e:MouseEvent):void {
			var hasCapture:Boolean = _canvas.hasCapture(e);
			var noAssoc:Boolean = !(_tabGroup["TEXT"].panel as ControlPanel).hasAssoc();
			var focusNotInLay:Boolean = stage.focus == null || !(_canvas.overlayContainer.contains(stage.focus) || _container.controlay.contains(stage.focus));
			if (hasCapture && noAssoc && focusNotInLay && !_willTextActived && !_container.inDrag()) {
				activeWantText(true);
			} else if (!hasCapture && _willTextActived) {
				activeWantText(false);
			}
		}
		private function activeWantText(flag:Boolean):void {
			if (flag) {
				_willTextActived = true;
				setTimeout(function():void {
					Cursor.setCursor("TEXT");
				}, 3);
				_canvas.addEventListener(MouseEvent.ROLL_OUT, unWantText);
				_canvas.addEventListener(MouseEvent.MOUSE_DOWN, prepareText);
			} else {
				_willTextActived = false;
				_canvas.removeEventListener(MouseEvent.ROLL_OUT, unWantText);
				_canvas.removeEventListener(MouseEvent.MOUSE_DOWN, prepareText);
				setTimeout(function():void {
					if (Cursor.getCursor() == "TEXT") {
						Cursor.reset();
					}
				}, 3);
			}
		}
		private function unWantText(e:MouseEvent):void {
			activeWantText(false);
		}
		private function prepareText(e:MouseEvent):void {
			activeWantText(false);
			if (!_container.canMove()) {
				stokeText(e);
				return;
			}
			var cX:Number = e.stageX, cY:Number = e.stageY;
			_canvas.addEventListener(MouseEvent.MOUSE_UP, stokeText);
			_canvas.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void {
				if (Math.pow(e.stageX - cX, 2) + Math.pow(e.stageY - cY, 2) < 25) {
					return;
				}
				_canvas.removeEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
				_canvas.removeEventListener(MouseEvent.MOUSE_UP, stokeText);
			});
		}
		private function stokeText(e:MouseEvent):void {
			_canvas.removeEventListener(MouseEvent.MOUSE_UP, stokeText);
			(_tabGroup["TEXT"].panel as TextControlPanel).addText(new Point(e.stageX, e.stageY));
		}
		
		private function onCanvasDown(e:MouseEvent):void {
			if (_canvas.hasCapture(e)) {
				var panel:ControlPanel;
				panel = _tabGroup["TEXT"].panel as ControlPanel;
				if (panel && panel.hasAssoc()) {
					panel.unAssoc();
				}
				panel = _tabGroup["WATER"].panel as ControlPanel;
				if (panel && panel.hasAssoc()) {
					panel.unAssoc();
				}
			}
			if (_focusedTab == "TEXT") {
				wantText(e);
			}
		}
		
		private function doSave():void {
			if (_inUpload) {
				return;
			}
			_inUpload = true;
			MsgBox.getInstance(stage).loading("正在准备图片...");
			setTimeout(doUpload, 1);
		}
		private function doUpload():void {
			_uploader == null && initUploader();
			var data:URLVariables = new URLVariables();
			data[Global.authFieldName] = Global.authCookie;
			data["ORIGINAL_FILE"] = Global.params.file;
			var bytes:ByteArray, ext:String;
			if (_saveType == "PNG") {
				bytes = PNGEncoder.encode(_container.newBitmapData);
				ext = "png";
			} else {
				var quality:Number = (_tabGroup["QUALITY"].panel is ControlPanel) ? (_tabGroup["QUALITY"].panel as QualityControlPanel).quality : 80;
				bytes = (new JPGEncoder(quality)).encode(_container.newBitmapData);
				ext = "jpg";
			}
			MsgBox.getInstance(stage).loading("正在保存图片...");
			_uploader.upload("image." + ext, bytes, data);
		}
		
		private function initUploader():void {
			_uploader = new Uploader(Global.uploadFieldName, Global.getClientUrl(Global.saveUrl));
			_uploader.addEventListener(ImageEvent.UPLOAD_COMPLETE, function(e:ImageEvent):void{
				_inUpload = false;
				try {
					var json:Object = JSON.parse(e.data as String);
				} catch (err:Error) {
					MsgBox.getInstance(stage).tip("返回信息解析错误");
					return;
				}
				if (json.state) {
					_container.savePoint();
					MsgBox.getInstance(stage).confirm("保存成功，关闭窗口?", function():void{
						Global.trigger('close');
					}, function():void{});
					Global.trigger('saved', json);
				} else {
					MsgBox.getInstance(stage).tip(json.error || "未知错误");
				}
			});
			_uploader.addEventListener(ImageEvent.UPLOAD_ERROR, function(e:ImageEvent):void{
				_inUpload = false;
				var err:Object = e.data as Object;
				MsgBox.getInstance(stage).tip(err.type + ":" +err.text);
			});
		}
		
		private function onKeyDown(e:KeyboardEvent):void {
			if (e.ctrlKey) {
				switch (e.keyCode) {
				case 83://  case 115:S
					doSave();
					break;
				case 90://  case 122:Z
					_container.undo();
					break;
				case 89://  case 121:Y
					_container.redo();
					break;
				}
			}
			else if (e.keyCode == 122 && stage.displayState != StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.FULL_SCREEN;
			}
			e.updateAfterEvent();
		}
		
		private function onClickClose(e:MouseEvent):void {
			if (_container.hasModified()) {
				MsgBox.getInstance(stage).confirm("当前修改未保存，确定要关闭?", function():void{
					Global.trigger('close');
				}, function():void{});
			} else {
				Global.trigger('close');
			}
		}
		
		private function testExternalInterface():void {
			_setupTimer.stop();
			_setupTimer.removeEventListener(TimerEvent.TIMER, setupExternalInterface);
			_setupTimer = null;
			setup();
		}
		private function setupExternalInterface(e:TimerEvent = null):void {
			try {
				ExternalInterface.addCallback('testExternalInterface', testExternalInterface);
			} catch (e:Error) { return; }
			ExternalInterface.call('ImageEditor.testExternalInterface("' + Global.params.guid + '")');
		}
	}
}
