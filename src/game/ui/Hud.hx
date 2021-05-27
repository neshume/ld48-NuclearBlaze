package ui;

class Hud extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;

	// var flow : h2d.Flow;
	var invalidated = true;
	var notifications : Array<h2d.Flow> = [];
	var notifTw : dn.Tweenie;
	var inventory : h2d.Flow;
	var upgrades: h2d.Flow;
	var curUp: Null<h2d.Flow>;
	var water: h2d.Object;
	var waterBg: h2d.Bitmap;
	var waterBar: h2d.ScaleGrid;
	var waterSurface: HSprite;
	var waterBlink: h3d.Vector;

	var debugText : h2d.Text;
	var permanentTf : Null<h2d.Text>;
	var lastRadio : Null<h2d.Object>;
	var dict = Assets.tilesDict;

	public function new() {
		super(Game.ME);

		createRootInLayers(game.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering
		notifications = [];
		notifTw = new Tweenie(Const.FPS);

		inventory = new h2d.Flow(root);
		inventory.filter = new dn.heaps.filter.PixelOutline();
		inventory.verticalAlign = Middle;
		inventory.minHeight = 16;
		inventory.horizontalSpacing = 2;

		upgrades = new h2d.Flow(root);
		upgrades.filter = new dn.heaps.filter.PixelOutline();
		upgrades.verticalAlign = Middle;
		upgrades.minHeight = 16;
		upgrades.horizontalSpacing = 2;

		water = new h2d.Object(root);
		waterBg = Assets.tiles.getBitmap(dict.waterAmmoBg, water);
		waterBar = new h2d.ScaleGrid(Assets.tiles.getTile(dict.waterAmmoBar), 3,1, 3,2, water );
		waterSurface = Assets.tiles.h_getAndPlay(dict.waterAmmoSurface, water);
		waterSurface.anim.setSpeed(0.15);
		waterSurface.setCenterRatio(0,1);
		waterBg.colorAdd = waterBlink = new h3d.Vector();
		setWater(0);

		debugText = new h2d.Text(Assets.fontSmall, root);
		clearDebug();
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.UI_SCALE);

		if( curUp!=null )
			curUp.minWidth = Std.int( w()/Const.UI_SCALE );

		if( permanentTf!=null ) {
			permanentTf.x = Std.int( 0.5*w()/Const.UI_SCALE - 0.5*permanentTf.textWidth*permanentTf.scaleX );
			permanentTf.y = 8;
		}
	}

	public function clear() {
		clearDebug();
		clearNotifications();
		clearUpgradeMessage();
		clearPermanentText();
		clearRadio();
		setInventory([]);
	}

	/** Clear debug printing **/
	public inline function clearDebug() {
		debugText.text = "";
		debugText.visible = false;
	}


	public function upgradeFound(i:Enum_Items) {
		clearUpgradeMessage();
		var name : Null<LocaleString> = null;
		var desc : Null<LocaleString> = null;
		switch i {
			case Key, GreenCard, BlueCard:
			case WaterSpray:

			case UpWaterLadder:
				name = L.t._("LADDER GRIP!");
				desc = L.t._("You can now use water from ladders.");

			case UpWaterUp:
				name = L.t._("SUPER FIRE HOSE!");
				desc = L.t._("Hold [UP] while watering to aim up.");

			case UpShield:
				name = L.t._("SHOWERING!");
				desc = L.t._("Hold [DOWN] while watering to protect yourself.");

			case UpWaterTank:
				name = L.t._("WATER TANK");
				desc = L.t._("More water!");

			case UpDodge:
				name = L.t._("DODGING");
				desc = L.t._("Tactical hazard escape!");
		}

		if( name!=null ) {
			curUp = new h2d.Flow(root);
			curUp.layout = Horizontal;
			curUp.horizontalAlign = Middle;
			curUp.verticalAlign = Middle;
			curUp.horizontalSpacing = 4;

			var halo = Assets.tiles.h_get(Assets.tilesDict.upHalo, curUp);
			halo.anim.playAndLoop(Assets.tilesDict.upHalo).setSpeed(0.3);
			var icon = new h2d.Bitmap(Assets.getItem(i), halo);
			icon.tile.setCenterRatio(0.5,0.5);
			icon.setPosition( Std.int(halo.tile.width*0.5), Std.int(halo.tile.height*0.5) );

			var f = new h2d.Flow(curUp);
			f.layout = Vertical;

			var tf = new h2d.Text(Assets.fontPixelOutline, f);
			tf.text = name;

			var tf = new h2d.Text(Assets.fontPixelOutline, f);
			tf.textColor = 0xffcc00;
			tf.text = desc;

			curUp.y = h()/Const.UI_SCALE;
			tw.createS(curUp.y, h()/Const.UI_SCALE - curUp.outerHeight - 3, TElasticEnd, 0.5 );
			dn.Process.resizeAll();
		}
	}

	public inline function clearUpgradeMessage() {
		if( curUp!=null ) {
			curUp.remove();
			tw.terminateWithoutCallbacks(curUp.y);
			curUp = null;
		}
	}

	/** Display a debug string **/
	public inline function debug(v:Dynamic, clear=true) {
		if( clear )
			debugText.text = Std.string(v);
		else
			debugText.text += "\n"+v;
		debugText.visible = true;
		debugText.x = Std.int( w()/Const.UI_SCALE - 4 - debugText.textWidth );
	}

	public function clearPermanentText() {
		if( permanentTf!=null ) {
			tw.terminateWithoutCallbacks(permanentTf.y);
			permanentTf.remove();
			permanentTf = null;
		}

	}
	public function setPermanentText(str:LocaleString, color=0xffcc00) {
		clearPermanentText();
		permanentTf = new h2d.Text(Assets.fontPixelOutline, root);
		permanentTf.text = str;
		permanentTf.textColor = color;
		onResize();
		var ty = permanentTf.y;
		tw.createS(permanentTf.y, -10>ty, 0.5);
	}

	public function clearRadio() {
		if( lastRadio!=null ) {
			lastRadio.remove();
			lastRadio = null;
		}
	}

	public function radio(msg:String, color=0x4a5462) {
		clearRadio();

		var left = 32;

		var wrapper = new h2d.Object(root);
		lastRadio = wrapper;
		wrapper.scaleX = 0.1;
		wrapper.filter = new h2d.filter.Nothing();

		var mic = Assets.tiles.h_get(dict.radioMic,0, 0.5,0.5, wrapper);
		mic.setPosition(Std.int(mic.tile.width*0.5), Std.int(mic.tile.height*0.5));

		var bubble = new h2d.ScaleGrid( Assets.tiles.getTile(Assets.tilesDict.radioBubble), 4,4, wrapper );
		bubble.tileBorders = true;
		var pad = 8;
		bubble.color.setColor( C.addAlphaF(color) );

		var link = Assets.tiles.h_get(dict.radioBubbleLink,0, 1, 0.5, wrapper);
		link.colorize(color);

		var tf = new h2d.Text(Assets.fontPixel, wrapper);
		tf.setPosition(pad+left,pad);
		tf.text = msg;
		tf.maxWidth = w()/Const.UI_SCALE - 32;

		bubble.x = left;
		bubble.width = pad*2 + tf.textWidth;
		bubble.height = pad*2 + tf.textHeight-4;
		link.x = bubble.x+8;
		link.y = Std.int(bubble.height*0.5);

		cd.setS("radioBubbleShaking",0.4);
		cd.setS("keepRadio", 3 + msg.length*0.05, true);
		cd.setS("radioMicTalking", cd.getS("keepRadio")*0.3, true);
		createChildProcess( (p)->{
			if( wrapper.parent==null ) {
				p.destroy();
				return;
			}
			wrapper.scaleX += (1-wrapper.scaleX ) * M.fmin(1, 0.2*tmod);
			wrapper.x = 3;
			wrapper.y = 24;
			if( cd.has("radioMicTalking") &&!cd.has("radioMicShakingLock") ) {
				cd.setS("radioMicShaking", rnd(0.2,0.4));
				cd.setS("radioMicShakingLock", rnd(0.2,0.5),true);
			}
			if( !cd.has("radioMicShaking") )
				mic.setScale( mic.scaleX + (1-mic.scaleX)*0.3 );
			else
				mic.setScale( 1.1 + 0.1 * cd.getRatio("radioMicShaking") * Math.sin(1+ftime*2.8) );
			// mic.y = 1 * cd.getRatio("radioMicShaking") * Math.sin(1+ftime*2.8);
			bubble.y = 3 + 2 * cd.getRatio("radioBubbleShaking")*Math.sin(2+ftime*2.8);

			if( !cd.has("keepRadio") ) {
				wrapper.alpha -= 0.03*tmod;
				if( wrapper.alpha<=0 ) {
					clearRadio();
					p.destroy();
				}
			}
		}, true);

		return cd.getS("keepRadio");
	}

	/** Pop a quick s in the corner **/
	public function notify(str:String, color=0xA56DE7) {
		// Bg
		var t = Assets.tiles.getTile( Assets.tilesDict.uiBar );
		var f = new dn.heaps.FlowBg(t, 2, root);
		f.colorizeBg(color);
		f.paddingHorizontal = 6;
		f.paddingBottom = 4;
		f.paddingTop = 2;
		f.paddingLeft = 9;
		f.y = 4;

		// Text
		var tf = new h2d.Text(Assets.fontPixel, f);
		tf.text = str;
		tf.maxWidth = 0.6 * w()/Const.UI_SCALE;
		tf.textColor = 0xffffff;

		// Notification lifetime
		var durationS = 2 + str.length*0.04;
		var p = createChildProcess();
		notifications.insert(0,f);
		p.tw.createS(f.x, -f.outerWidth>-2, TEaseOut, 0.1);
		p.onUpdateCb = ()->{
			if( f.parent==null )
				p.destroy();

			if( p.stime>=durationS && !p.cd.hasSetS("done",Const.INFINITE) )
				p.tw.createS(f.x, -f.outerWidth, 0.2).end( p.destroy );
		}
		p.onDisposeCb = ()->{
			notifications.remove(f);
			f.remove();
		}

		// Move existing notifications
		var y = 4;
		for(f in notifications) {
			notifTw.terminateWithoutCallbacks(f.y);
			notifTw.createS(f.y, y, TEaseOut, 0.2);
			y+=f.outerHeight+1;
		}

	}

	public function clearNotifications() {
		for(e in notifications)
			e.remove();
		notifications = [];
	}

	public function setInventory(items:Array<Enum_Items>) {
		inventory.removeChildren();
		cd.setS("shakeInv",1);
		for(i in items)
			new h2d.Bitmap( Assets.getItem(i), inventory );
		inventory.reflow();
		updatePos();
	}

	public function setUpgrades(ups:Map<Enum_Items,Bool>) {
		// upgrades.removeChildren();
		// cd.setS("shakeUps",2);
		// for( i in ups.keys() )
		// 	new h2d.Bitmap( Assets.getItem(i), upgrades );
		// flow.reflow();
		// updatePos();
	}

	public function setWater(cur:Float, bottles=1) {
		waterBar.height = M.fmax(0, (waterBg.tile.height-9)  * cur );
		waterBar.x = 2;
		waterBar.y = waterBg.tile.height-2 - waterBar.height;
		waterSurface.x = waterBar.x;
		waterSurface.y = cur<=0 ? waterBar.y : waterBar.y+1;
	}

	public inline function shakeWater(depleted=false) {
		if( depleted )
			cd.setS("shakeWaterDepleted",0.1);
		else
			cd.setS("shakeWaterNormal",0.1);
	}

	public inline function blinkWater(c:UInt, ?keep=0.03) {
		waterBlink.setColor(c);
		cd.setS("keepWaterBlink",keep);
	}

	public inline function invalidate() invalidated = true;

	function render() {}

	public function onLevelStart() {}

	override function preUpdate() {
		super.preUpdate();
		notifTw.update(tmod);
	}

	function updatePos() {
		inventory.setPosition( w()/Const.UI_SCALE-inventory.outerWidth-3, 3 );
		if( cd.has("shakeInv") )
			inventory.y += Math.cos(uftime*0.4) * 3 * cd.getRatio("shakeInv");

		upgrades.setPosition( w()/Const.UI_SCALE - upgrades.outerWidth-3, 3 );

		water.setPosition( w()/Const.UI_SCALE-16, h()/Const.UI_SCALE-waterBg.tile.height );
		water.visible = game.level!=null && !game.level.data.f_isGameMenu;
		if( cd.has("shakeWaterNormal") )
			water.y += Math.cos(uftime*0.6) * 1 * cd.getRatio("shakeWaterNormal");
		if( cd.has("shakeWaterDepleted") )
			water.x += Math.cos(uftime*1.3) * 4 * cd.getRatio("shakeWaterDepleted");
	}


	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}

		if( !cd.has("keepWaterBlink") ) {
			waterBlink.r *= Math.pow(0.5,tmod);
			waterBlink.g *= Math.pow(0.55,tmod);
			waterBlink.b *= Math.pow(0.8,tmod);
		}

		updatePos();
	}
}
