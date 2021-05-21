package gm;

typedef MenuItem ={ f:h2d.Flow, tf:h2d.Text, active:Bool, cb:Void->Void }

class GameMenu extends dn.Process {
	static var ME : GameMenu;

	public var app(get,never) : App; inline function get_app() return App.ME;
	public var game(get,never) : Game; inline function get_game() return Game.ME;

	var items : Array<MenuItem> = [];
	var menu : h2d.Flow;

	var curIdx = 0;
	var cur(get,never) : MenuItem;
	var curBg : h2d.Bitmap;

	var ca : ControllerAccess;

	public function new() {
		super(game);

		if( ME!=null )
			ME.destroy();
		ME = this;
		createRootInLayers(game.root, Const.DP_TOP);

		ca = app.controller.createAccess("menu");

		curBg = new h2d.Bitmap( h2d.Tile.fromColor( C.hexToInt("#1f314f"), 0.66), root );

		menu = new h2d.Flow(root);
		menu.layout = Vertical;
		menu.verticalSpacing = 2;
		// menu.horizontalAlign = Middle;

		if( !app.save.exists() )
			curIdx = 1;

		addItem( L.t._("Continue"), app.save.exists(), ()->{
			if( !app.save.exists() ) {
				// Error
				game.fx.flashBangS(0xff0000, 0.5);
				return;
			}

			if( !setLock() )
				return;

			var data = Assets.worldData.getLevel(app.save.state.levelId);
			if( data==null ) {
				game.hud.notify( L.t._("Error: level not found ::name::", { name:app.save.state.levelId}), 0xff00);
				return;
			}
			// Upgrades
			for(uk in app.save.state.upgrades) {
				var u = try Enum_Items.createByName(uk) catch(_) null;
				if( u!=null )
					game.unlockUpgrade(u);
			}
			// Start level
			game.fadeToBlack(()->{
				game.kidMode = false;
				game.startLevel(data);
				destroy();
			});
		} );

		addItem( L.t._("New game"), ()->{
			if( app.save.exists() && !cd.hasSetS("newConfirm",8) ) {
				game.hud.radio(L.t._("Warning, this will erase previous progression. Confirm again to proceed."), 0xff6600);
				return;
			}

			if( !setLock() )
				return;

			game.fadeToBlack(()->{
				game.kidMode = false;
				game.delayer.addS( game.nextLevel, 0.6 );
				destroy();
			});
		} );

		addItem( L.t._("Kid mode"), ()->{
			if( !setLock() )
				return;

			game.fx.flashBangS(0xff0000, 0.5); // TODO
		} );

		#if !js
		addItem( L.t._("Exit"), ()->{
			app.exit();
			destroy();
		} );
		#end

		tw.createS(menu.alpha, 0>1, 1);
		onCurChange();
		dn.Process.resizeAll();
	}

	inline function get_cur() {
		return items[curIdx];
	}

	inline function setLock() {
		if( cd.has("locked") )
			return false;
		else {
			cd.setS("locked",Const.INFINITE);
			return true;
		}
	}

	function addItem(label:LocaleString, active=true, cb:Void->Void) {
		var f = new h2d.Flow(menu);
		var tf = new h2d.Text(Assets.fontPixel, f);
		tf.textColor = 0xffff77;
		tf.text = label.toUpperCase();
		tf.alpha = active ? 1 : 0.33;

		items.push({
			f: f,
			tf: tf,
			active: active,
			cb: cb,
		});
	}

	override function onResize() {
		super.onResize();
		menu.setScale(Const.SCALE);
		menu.x = Std.int( w()*0.7 + 8*Const.SCALE );
		menu.y = Std.int( h() - 16*Const.SCALE - menu.outerHeight*menu.scaleY );

		curBg.x = w()*0.7;
		curBg.scaleX = w()*0.3;
		curBg.scaleY = 16 * Const.SCALE;
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;

		ca.dispose();
		ca = null;
	}

	function onCurChange() {
		for(e in items)
			e.tf.textColor = 0xffcc00;
		cur.tf.textColor = 0xffffff;
	}

	override function preUpdate() {
		super.preUpdate();

		if( !game.level.data.f_isGameMenu )
			destroy();
	}

	override function update() {
		super.update();

		curBg.y += ( menu.y + cur.f.y*Const.SCALE - curBg.y ) * 0.4;
		curBg.scaleY = (cur.f.outerHeight+3)*Const.SCALE;

		if( ca.isKeyboardPressed(K.ENTER) )
			cur.cb();

		if( ca.isKeyboardPressed(K.UP) && curIdx>0 ) {
			curIdx--;
			while( curIdx>0 && !cur.active )
				curIdx--;
			onCurChange();
		}

		if( ca.isKeyboardPressed(K.DOWN) && curIdx<items.length-1 ) {
			curIdx++;
			while( curIdx<items.length-1 && !cur.active )
				curIdx++;
			onCurChange();
		}

		#if !js
		if( ca.isKeyboardPressed(K.ESCAPE) )
			app.exit();
		#end
	}
}