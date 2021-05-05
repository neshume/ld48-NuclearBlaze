package gm.en;

class Explosive extends Entity {
	public static var ALL : Array<Explosive> = [];

	public var data : Entity_Explosive;
	var active = false;
	var timerS = 0.;
	var tf : h2d.Text;
	var seen = false;

	public function new(d:Entity_Explosive) {
		super(0,0);
		ALL.push(this);
		data = d;
		setPosPixel(data.pixelX, data.pixelY);
		gravityMul = 0;
		collides = false;
		pivotY = 0.5;

		spr.set(dict.error);
		game.scroller.add(spr,Const.DP_BG);

		level.getFireState(cx,cy, true); // Force firestate here

		tf = new h2d.Text(Assets.fontSmall);
		game.scroller.add(tf, Const.DP_UI);
		tf.visible = false;
		tf.blendMode = Add;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		tf.remove();
	}

	override function postUpdate() {
		super.postUpdate();
		updateTextPos();
	}

	public function activate() {
		if( active )
			return;

		active = true;
		timerS = data.f_timer;

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

	function updateTextPos() {
		var tfX = 0.;
		var tfY = 0.;
		var tfS = 1.;
		if( !isOnScreen(-24) ) {
			var a = Math.atan2(centerY-hero.centerY, centerX-hero.centerX);
			tfX = hero.centerX + Math.cos(a)*camera.pxHei*0.4;
			tfY = hero.centerY + Math.sin(a)*camera.pxHei*0.4;
			tfS = 1;
		}
		else {
			tfX = centerX;
			tfY = centerY;
			tfS = 2;
		}
		tfX -= tf.textWidth*tf.scaleX * 0.5;
		tfY -= tf.textHeight*tf.scaleY * 0.5;
		tf.x += ( tfX-tf.x ) * M.fmin(1, 0.2*tmod);
		tf.y += ( tfY-tf.y ) * M.fmin(1, 0.2*tmod);
		tf.setScale( tf.scaleX + ( tfS-tf.scaleX ) * M.fmin(1, 0.2*tmod) );

		if( cd.has("shaking") )
			tf.y += Math.cos(ftime*1.3) * 1;
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		// First sight trigger
		if( !seen && !cd.hasSetS("sighCheck",0.3) && distCase(hero)<=25 && sightCheck(hero) ) {
			seen = true;
			if( data.f_cameraCinematic ) {
				level.suspendFireForS(3);
				dn.Bresenham.iterateDisc(cx,cy,2, (x,y)->level.revealFog(x,y));
				camera.cinematicTrack(centerX, centerY, 1.2);
			}
		}
		if( !seen )
			return;

		// Check for fire
		if( !active && !cd.hasSetS("fireCheck",0.4) && !cd.has("lock") )
			dn.Bresenham.iterateDisc(cx,cy, 2, (x,y)->{
				if( level.getFireLevel(x,y)>=2 )
					activate();
			});

		// Countdown
		if( active ) {
			var r = Std.int( Const.db.ExplosiveRadius_1 );

			var fs = level.getFireState(cx,cy);
			timerS -= 1/Const.FIXED_UPDATE_FPS * ( fs.isUnderControl() ? 0.9 : 1 );
			tf.visible = true;
			tf.textColor = fs.isUnderControl() ? 0xc6ff30 : 0xff8a64;
			tf.blendMode = fs.isUnderControl() ? Alpha : Add;
			if( fs.isUnderControl() )
				cd.setS("shaking",0.1);
			tf.text = Std.string( M.ceil(timerS) );
			updateTextPos();

			if( !cd.hasSetS("warn",0.25) ) {
				fx.explosionWarning(centerX, centerY, 1-timerS/data.f_timer);
				if( timerS<=3 )
					fx.announceRadius(centerX, centerY, Const.db.ExplosiveRadius_3*Const.GRID, 0xff0000);
			}

			if( !fs.isBurning() ) {
				deactivate();
				cd.setS("lock", R.around(2));
			}
			else if( timerS<=0 ) {
				// BOOM
				fx.largeExplosion(centerX, centerY, r*Const.GRID);
				camera.shakeS(4, 0.7);
				if( distCase(hero)<=r )
					fx.flashBangS(0xffdd77, 0.8, 0.3);
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

				if( distCase(hero)<=r ) {
					var dr = 0.3 + 0.7*(1-distCase(hero)/r);
					if( distCase(hero)<=Const.db.ExplosiveRadius_3 ) {
						hero.kill(this);
						hero.dir = hero.dirTo(this);
					}

					var a = Math.atan2(hero.centerY-centerY, hero.centerX-centerX);
					hero.cancelVelocities();
					hero.bdx = Math.cos(a)*0.9 * dr;
					hero.bdy = -R.around(0.3) * dr;
					hero.lockControlsS(1);
				}
			}
		}
	}
}