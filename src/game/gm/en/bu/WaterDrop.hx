package gm.en.bu;

class WaterDrop extends Bullet {
	var lastTailX = 0.;
	var lastTailY = 0.;
	var elapsedDist = 0.;
	public var power = 1.0;

	public function new(xx:Float, yy:Float, ang:Float) {
		super(xx,yy);

		gravityMul = 0.8;
		frictX = 0.99;
		frictY = 0.93;
		collides = false;

		lastTailX = sprX;
		lastTailY = sprY;

		final spd = 0.7 * rnd(0.9,1.1);
		dx = Math.cos(ang)*spd;
		dy = Math.sin(ang)*spd;

		spr.set(dict.empty);
	}

	function getElapsedFactor() {
		return isDelayed() ? 0 : elapsedDist/180;
	}

	override function postUpdate() {
		super.postUpdate();

		if( !isDelayed() && !cd.hasSetS("tail",0.04) ) {
			if( elapsedDist>16 )
				tailFxTo(sprX,sprY);
			else {
				lastTailX = sprX;
				lastTailY = sprY;
			}
		}
	}

	override function onHitCollision() {
		super.onHitCollision();
		tailFxTo(sprX, sprY);
		fx.wallSplash(lastFixedUpdateX, lastFixedUpdateY);
	}

	inline function tailFxTo(x:Float,y:Float) {
		fx.waterTail(lastTailX, lastTailY, x,y, getElapsedFactor(), cd.has("touchedFire") ? Const.WATER_COLOR_OFF : Const.WATER_COLOR);
		lastTailX = x;
		lastTailY = y;
	}

	override function fixedUpdate() {
		if( isDelayed() )
			return;

		var lastX = centerX;
		var lastY = centerY;

		super.fixedUpdate();

		elapsedDist += M.dist(lastX, lastY, centerX, centerY);
		if( getElapsedFactor()>=1 ) {
			tailFxTo(sprX,sprY);
			fx.waterVanish(centerX, centerY);
			destroy();
			return;
		}


		// Reduce fire
		if( !cd.has("lock") ) {
			var x = cx;
			for(y in cy-1...cy+2) {
				var fs = level.getFireState(x,y);
				if( fs==null )
					continue;

				if( fs.isBurning() ) {
					var before = fs.level;
					fs.decrease( Const.db.WaterFireDecrease_1*power );
					if( fs.level<=0 ) {
						fs.clear();
						fs.extinguished = true;
						if( before>0 )
							fx.fireVanish(x,y, fs.strongFx);
					}

					if( fs.level>=1 ) {
						fx.fireSplash( (x+rnd(0.2,0.8))*Const.GRID, (y+rnd(0.2,0.8))*Const.GRID);
						cd.setS("lock", Const.INFINITE);
						cd.setS("touchedFire", Const.INFINITE);
					}
				}
				fs.underControlS = Const.db.ControlDuration_1 * ( 1 - fs.resistance );
				if( fs.quickFire )
					fs.underControlS*=0.25;
			}
		}
	}
}