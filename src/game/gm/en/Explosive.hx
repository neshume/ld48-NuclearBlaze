package gm.en;

class Explosive extends Entity {
	public static var ALL : Array<Explosive> = [];

	public var data : Entity_Explosive;
	var active = false;
	var timerS = 0.;
	var tf : h2d.Text;

	public function new(d:Entity_Explosive) {
		super(0,0);
		ALL.push(this);
		data = d;
		setPosPixel(data.pixelX, data.pixelY);
		gravityMul = 0;
		collides = false;

		spr.set(dict.error);
		game.scroller.add(spr,Const.DP_BG);

		level.getFireState(cx,cy, true); // Force firestate here

		tf = new h2d.Text(Assets.fontPixel, spr);
		tf.visible = false;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function postUpdate() {
		super.postUpdate();
	}

	public function activate() {
		if( active )
			return;

		active = true;
		timerS = Const.db.ExplosiveTimer_1;

		var fs = level.getFireState(cx,cy);
		fs.level = FireState.MAX;
		fs.resistance = 0.93;
		fs.smokePower = 2;
		fs.oil = true;
		fs.strongFx = true;
	}

	public function deactivate() {
		if( !active )
			return;
		active = false;
		tf.visible = false;
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		// Check for fire
		if( !active && !cd.hasSetS("fireCheck",0.4) )
			dn.Bresenham.iterateDisc(cx,cy, 2, (x,y)->{
				if( level.getFireLevel(x,y)>=2 )
					activate();
			});

		// Countdown
		if( active ) {
			var fs = level.getFireState(cx,cy);
			if( !fs.isUnderControl() )
				timerS -= 1/Const.FIXED_UPDATE_FPS;
			tf.visible = true;
			tf.textColor = fs.isUnderControl() ? 0x1e9eff : 0xff0000;
			tf.text = Std.string( M.ceil(timerS) );
			tf.x = Std.int( -tf.textWidth*0.5 );
			tf.y = Std.int( -tf.textHeight );

			if( !fs.isBurning() )
				deactivate();
			else if( timerS<=0 ) {
				// BOOM
				fx.largeExplosion(centerX, centerY, Const.db.ExplosiveRadius_1*Const.GRID);
				camera.shakeS(4, 0.7);
				fx.flashBangS(0xffcc00, 0.2, 3);
				deactivate();
				dn.Bresenham.iterateDisc( cx,cy, Std.int(Const.db.ExplosiveRadius_1), (x,y)->{
					if( !level.isBurning(x,y) )
						return;

					var fs = level.getFireState(x,y);
					if( sightCheck(x,y) )
						fs.clear();
					else {
						fs.decrease( -R.around(1.5) );
						if( fs.level==0 )
							fs.clear();
					}
					fs.extinguished = true;
				});
			}
		}
	}
}