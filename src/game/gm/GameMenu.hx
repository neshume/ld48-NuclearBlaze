package gm;

typedef MenuItem ={ f:h2d.Flow, active:Bool, cb:Void->Void }

class GameMenu extends dn.Process {
	static var ME : GameMenu;

	var items : Array<MenuItem> = [];
	var menu : h2d.Flow;

	var curIdx = 0;
	var cur(get,never) : MenuItem;

	var ca : ControllerAccess;

	public function new() {
		super(Game.ME);
		if( ME!=null )
			ME.destroy();
		ME = this;
		createRootInLayers(Game.ME.root, Const.DP_TOP);

		ca = App.ME.controller.createAccess("menu");

		menu = new h2d.Flow(root);
		menu.layout = Vertical;
		menu.verticalSpacing = 2;
		menu.horizontalAlign = Middle;

		addItem( L.t._("New game"), ()->{
			Game.ME.fadeToBlack();
			Game.ME.kidMode = false;
			Game.ME.delayer.addS( Game.ME.nextLevel, 0.6 );
			destroy();
		} );

		addItem( L.t._("Kid mode"), ()->{
			Game.ME.fx.flashBangS(0xff0000, 0.5);
			// Game.ME.fadeToBlack();
			// Game.ME.delayer.addS( Game.ME.nextLevel, 0.6 );
			// Game.ME.kidMode = true;
			// destroy();
		} );

		var hasSave = false;
		addItem( L.t._("Continue"), hasSave, ()->{
			if( !hasSave ) {
				Game.ME.fx.flashBangS(0xff0000, 0.5);
				return;
			}
			// Game.ME.fadeToBlack();
			// Game.ME.delayer.addS( Game.ME.nextLevel, 0.6 );
			// destroy();
		} );

		#if !js
		addItem( L.t._("Exit"), ()->{
			App.ME.exit();
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

	function addItem(label:LocaleString, active=true, cb:Void->Void) {
		var f = new h2d.Flow(menu);
		var tf = new h2d.Text(Assets.fontPixel, f);
		tf.textColor = 0xffff77;
		tf.text = label.toUpperCase();
		tf.alpha = active ? 1 : 0.33;

		items.push({
			f: f,
			active: active,
			cb: cb,
		});
	}

	override function onResize() {
		super.onResize();
		menu.setScale(Const.SCALE);
		menu.x = Std.int( w()*0.5 - menu.outerWidth*0.5*menu.scaleX );
		menu.y = Std.int( h() - 16*Const.SCALE - menu.outerHeight*menu.scaleY );
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
			e.f.filter = null;
		cur.f.filter = new dn.heaps.filter.PixelOutline( C.hexToInt("#78a5ff") );
		// cur.f.filter = new h2d.filter.Group([
		// 	new dn.heaps.filter.PixelOutline(0x0),
		// 	new dn.heaps.filter.PixelOutline(0xffcc00),
		// ]);
	}

	override function update() {
		super.update();

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
			App.ME.exit();
		#end
	}
}