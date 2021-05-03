package ui;

class Hud extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;

	var flow : h2d.Flow;
	var invalidated = true;
	var notifications : Array<h2d.Flow> = [];
	var notifTw : dn.Tweenie;
	var inventory : h2d.Flow;
	var upgrades: h2d.Flow;
	var curUp: Null<h2d.Flow>;

	var debugText : h2d.Text;

	public function new() {
		super(Game.ME);

		createRootInLayers(game.root, Const.DP_UI);
		root.filter = new h2d.filter.Nothing(); // force pixel perfect rendering
		notifications = [];
		notifTw = new Tweenie(Const.FPS);

		flow = new h2d.Flow(root);

		inventory = new h2d.Flow(flow);
		inventory.filter = new dn.heaps.filter.PixelOutline();
		inventory.verticalAlign = Middle;
		inventory.minHeight = 16;
		inventory.horizontalSpacing = 2;

		upgrades = new h2d.Flow(flow);
		upgrades.filter = new dn.heaps.filter.PixelOutline();
		upgrades.verticalAlign = Middle;
		upgrades.minHeight = 16;
		upgrades.horizontalSpacing = 2;

		debugText = new h2d.Text(Assets.fontSmall, root);
		clearDebug();
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.UI_SCALE);
		if( curUp!=null )
			curUp.minWidth = Std.int( w()/Const.UI_SCALE );
	}

	public function clear() {
		clearDebug();
		clearNotifications();
		clearUpgradeMessage();
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
			case Key, RedCard, BlueCard:
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

			var tf = new h2d.Text(Assets.fontPixel, f);
			tf.text = name;

			var tf = new h2d.Text(Assets.fontPixel, f);
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
		flow.reflow();
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

	public inline function invalidate() invalidated = true;

	function render() {}

	public function onLevelStart() {}

	override function preUpdate() {
		super.preUpdate();
		notifTw.update(tmod);
	}

	function updatePos() {
		inventory.setPosition(3,3);
		// if( cd.has("shakeInv") )
		// 	inventory.y += Math.cos(uftime*0.4) * 3 * cd.getRatio("shakeInv");

		upgrades.setPosition( w()/Const.UI_SCALE - upgrades.outerWidth-3, 3 );
		// if( cd.has("shakeUps") )
		// 	upgrades.y += Math.cos(uftime*0.4) * 3 * cd.getRatio("shakeUps");
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}

		updatePos();
	}
}
