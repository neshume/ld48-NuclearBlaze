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

			if( !cd.hasSetS("warn",0.25) )
				fx.explosionWarning(centerX, centerY, 1-timerS/Const.db.ExplosiveTimer_1);

			if( !fs.isBurning() )
				deactivate();
			else if( timerS<=0 ) {
				// BOOM
				var r = Std.int( Const.db.ExplosiveRadius_1 );
				fx.largeExplosion(centerX, centerY, r*Const.GRID);
				camera.shakeS(4, 0.7);
				fx.flashBangS(0xffcc00, 0.2, 3);
				deactivate();
				level.getFireState(cx,cy).clear();
				game.addSlowMo("explosion", 0.6, 0.1);

				// Wipe fire
				dn.Bresenham.iterateDisc( cx,cy, r, (x,y)->{
					if( !level.isBurning(x,y) )
						return;

					var fs = level.getFireState(x,y);
					if( distCase(x,y)<=Const.db.ExplosiveRadius_2 )
						fs.clear();
					else {
						if( Std.random(100)<=66 )
							fs.clear();
						else {
							fs.level = M.imin(fs.level, 1);
							fs.lr = 0;
							fs.control();
						}
					}
					if( !fs.isBurning() )
						fx.fireExtinguished( (x+0.5)*Const.GRID, (y+0.5)*Const.GRID, centerX, centerY );
					fs.extinguished = true;
				});

				if( distCase(hero)<=r*1.1 ) {
					if( distCase(hero)<=Const.db.ExplosiveRadius_3 )
						hero.kill(this);

					var a = Math.atan2(hero.centerY-centerY, hero.centerX-centerX);
					hero.cancelVelocities();
					hero.bdx = Math.cos(a)*0.9;
					hero.bdy = -R.around(0.3);
					hero.lockControlsS(1);
				}
			}
		}
	}
}