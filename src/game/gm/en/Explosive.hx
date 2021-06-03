package gm.en;

class Explosive extends Entity {
	public static var ALL : Array<Explosive> = [];

	public var data : Entity_Explosive;
	var active = false;
	var timerS = 0.;
	var tf : h2d.Text;
	var seen = false;
	var pointer : HSprite;
	var needTriggerFirst = false;

	var tempBg : HSprite;
	var tempBar : HSprite;

	public function new(d:Entity_Explosive) {
		super(0,0);
		data = d;
		ALL.push(this);
		setPosPixel(data.pixelX, data.pixelY);
		gravityMul = 0;
		collides = false;
		pivotY = 0.5;
		seen = data.f_startActive || !data.f_requireSight;

		triggerId = data.f_triggerId;
		if( triggerId>=0 )
			needTriggerFirst = true;

		spr.set(dict.explosiveCore);
		// game.scroller.add(spr,Const.DP_EXPLOSIVE);

		tempBg = Assets.tiles.h_get(dict.explosiveTempBg, 0, 0.5,1);
		game.scroller.add(tempBg, Const.DP_ENTITY_FRONT);

		tempBar = Assets.tiles.h_get(dict.explosiveTempBar,0, 0.5,1);
		game.scroller.add(tempBar, Const.DP_ENTITY_FRONT);

		level.getFireState(cx,cy, true); // Force firestate here

		tf = new h2d.Text(Assets.fontPixel);
		game.scroller.add(tf, Const.DP_UI);
		tf.filter = new dn.heaps.filter.PixelOutline();
		tf.visible = false;
		tf.setPosition(centerX, centerY);

		pointer = Assets.tiles.h_get(dict.pointer,0, 0.5, 0.5);
		game.scroller.add(pointer, Const.DP_UI);
		pointer.smooth = true;
		// pointer.filter = new dn.heaps.filter.PixelOutline();
		// pointer.colorize(0xff8a64);
		pointer.setPosition(centerX, centerY);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		tf.remove();
		pointer.remove();
		tempBg.remove();
		tempBar.remove();
	}

	override function postUpdate() {
		super.postUpdate();
		updateText();

		tempBg.setPosition(centerX + 11*data.f_tempDir, bottom+2);
		tempBar.setPosition(centerX + 11*data.f_tempDir, bottom-1);

		if( level.isBurning(cx,cy) )
			tempBar.scaleY = level.getFireState(cx,cy).getRatio();
		else
			tempBar.scaleY = 0;

		if( cd.has("shaking") ) {
			tempBg.y += Math.cos(ftime*1.3) * 1;
			tempBar.y += Math.cos(ftime*1.3) * 1;
		}
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

	override function trigger() {
		super.trigger();
		activate();
		needTriggerFirst = false;
	}

	public function deactivate() {
		if( !active )
			return;
		active = false;
		tf.visible = false;
	}

	function updateText() {
		if( camera.hasCinematicTracking() || !active ) {
			tf.visible = false;
			pointer.visible = false;
			return;
		}

		var ang = Math.atan2(centerY-hero.centerY, centerX-hero.centerX);
		var tfX = 0.;
		var tfY = 0.;
		var tfS = 1.;
		if( !isOnScreenCenter(-20) ) {
			tfX = hero.centerX + Math.cos(ang)*camera.pxHei*0.4;
			tfY = hero.centerY + Math.sin(ang)*camera.pxHei*0.4;
			tfS = 2;
			pointer.visible = true;
		}
		else {
			tfX = centerX;
			tfY = centerY;
			pointer.visible = false;
			pointer.alpha = 0;
		}
		tf.text = M.ceil(timerS)+"s";
		tfX -= tf.textWidth*tf.scaleX * 0.5;
		tfY -= tf.textHeight*tf.scaleY * 0.5;
		tf.x += ( tfX-tf.x ) * M.fmin(1, 0.2*tmod);
		tf.y += ( tfY-tf.y ) * M.fmin(1, 0.2*tmod);
		tf.x = Std.int(tf.x);
		tf.y = Std.int(tf.y);
		tf.setScale( tf.scaleX + ( tfS-tf.scaleX ) * M.fmin(1, 0.2*tmod) );
		tf.visible = true;

		if( pointer.visible ) {
			pointer.alpha += (1-pointer.alpha) * M.fmin(1, 0.2*tmod);
			pointer.rotation = ang;
			pointer.x = tf.x + tf.textWidth*0.5 + Math.cos(ang)*16;
			pointer.y = tf.y + tf.textHeight*0.5 + Math.sin(ang)*16;
		}

		if( cd.has("shaking") )
			tf.y += Math.cos(ftime*1.3) * 1;
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		// First sight trigger
		if( !seen && !cd.hasSetS("sighCheck",0.3) && distCase(hero)<=25 && sightCheck(hero) ) {
			seen = true;
		}
		if( !seen )
			return;

		// Cinematic reveal
		if( active && data.f_cinematicReveal && !cd.hasSetS("cineRevealed",Const.INFINITE) ) {
			level.suspendFireForS(3);
			dn.Bresenham.iterateDisc(cx,cy,2, (x,y)->level.revealFog(x,y));
			camera.cinematicTrack(centerX, centerY, 1.2);
		}

		// Check for fire
		if( !active && !cd.hasSetS("fireCheck",0.4) && !cd.has("lock") && !needTriggerFirst )
			dn.Bresenham.iterateDisc(cx,cy, 2, (x,y)->{
				if( level.getFireLevel(x,y)>=2 )
					activate();
			});

		// Countdown
		if( active ) {
			final r = Std.int( Const.db.ExplosiveFxRadius );

			var fs = level.getFireState(cx,cy);
			timerS -= 1/Const.FIXED_UPDATE_FPS * ( fs.isUnderControl() ? 0.9 : 1 );
			tf.visible = true;
			tf.textColor = fs.isUnderControl() ? 0xc6ff30 : 0xffffff;
			if( fs.isUnderControl() )
				cd.setS("shaking",0.1);
			updateText();

			if( !cd.hasSetS("warn",0.25) ) {
				fx.explosionWarning(centerX, centerY, 1-timerS/data.f_timer);
				if( timerS<=10 )
					fx.announceRadius(centerX, centerY, Const.db.ExplosiveFxRadius*Const.GRID, 0xff0000);
			}


			if( !fs.isBurning() ) {
				deactivate();
				cd.setS("lock", R.around(2));
			}
			else if( timerS<=0 ) {
				// BOOM!
				fx.largeExplosion(centerX, centerY, r*Const.GRID);
				camera.shakeS(6, 0.9);
				if( distCase(hero)<=r )
					fx.flashBangS(0xffdd77, 0.8, 0.3);
				fx.flashBangS(0xffcc00, 0.2, 3);
				deactivate();
				level.getFireState(cx,cy).clear();
				game.addSlowMo("explosion", 0.6, 0.1);

				// Ignire fire
				dn.Bresenham.iterateDisc( cx,cy, r, (x,y)->{
					level.ignite(x,y);
				});

				hero.kill(this);
			}
		}
	}
}