package gm.en.bu;

class WaterDrop extends Bullet {
	var lastDropTailX = 0.;
	var lastDropTailY = 0.;
	var elapsedDist = 0.;
	public var power = 1.0;
	public var ignoreResist = false;
	public var ignoreCollisionsUntilY : Float = -Const.INFINITE;

	public function new(xx:Float, yy:Float, ang:Float) {
		super(xx,yy);

		gravityMul = 0.8;
		frictX = 0.99;
		frictY = 0.93;
		collides = false;

		lastDropTailX = sprX;
		lastDropTailY = sprY;

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
				lastDropTailX = sprX;
				lastDropTailY = sprY;
			}
		}
	}

	override function onHitCollision() {
		super.onHitCollision();
		tailFxTo(sprX, sprY);
		if( isOnScreenCenter() )
			fx.wallSplash(lastFixedUpdateX, lastFixedUpdateY);
	}

	inline function tailFxTo(x:Float,y:Float) {
		if( isOnScreenCenter() )
			fx.waterTail(lastDropTailX, lastDropTailY, x,y, getElapsedFactor(), cd.has("touchedFire") ? Const.WATER_COLOR_OFF : Const.WATER_COLOR);
		lastDropTailX = x;
		lastDropTailY = y;
	}

	override function checkCollision() {
		if( attachY >= ignoreCollisionsUntilY )
			super.checkCollision();
	}

	override function fixedUpdate() {
		if( isDelayed() )
			return;

		var lastX = centerX;
		var lastY = centerY;

		super.fixedUpdate();

		// Distance limit
		elapsedDist += M.dist(lastX, lastY, centerX, centerY);
		if( getElapsedFactor()>=1 ) {
			tailFxTo(sprX,sprY);
			if( isOnScreenCenter() )
				fx.waterVanish(centerX, centerY);
			destroy();
			return;
		}

		// Mobs
		if( !cd.has("lock") )
			for(e in gm.en.Mob.ALL)
				if( e.inBounds(centerX, centerY) ) {
					cd.setS("lock", 0.1);
					cd.setS("touchedFire", Const.INFINITE);
					e.hit(1,this);
				}


		// Reduce level fire
		if( !cd.has("lock") ) {
			var x = cx;
			for(y in cy-1...cy+2) {
				var fs = level.getFireState(x,y);
				if( fs==null || fs.infinite )
					continue;

				if( fs.isBurning() ) {
					var before = fs.level;
					fs.decrease( Const.db.WaterFireDecrease * power, ignoreResist );
					if( fs.level<=0 ) {
						fs.clear();
						fs.extinguished = true;
						if( before>0 && isOnScreenCenter() )
							fx.fireExtinguishedByWater(x,y, fs.strongFx);
					}

					if( fs.level>=1 ) {
						if( isOnScreenCenter() && !cd.hasSetS("fireSplash",0.4) )
							fx.fireSplash( (x+rnd(0.2,0.8))*Const.GRID, (y+rnd(0.2,0.8))*Const.GRID);
						cd.setS("lock", 0.1);
						cd.setS("touchedFire", Const.INFINITE);
					}
				}
				fs.control(ignoreResist);
				if( fs.oil )
					fs.underControlS*=0.25;
			}
		}
	}
}