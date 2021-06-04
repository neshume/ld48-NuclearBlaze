package gm.en;

class FireStarter extends Entity {
	public var data : Entity_FireStarter;

	public function new(d:Entity_FireStarter) {
		data = d;
		super(data.cx, data.cy);
		triggerId = data.f_triggerId;
		gravityMul = 0;
		collides = false;
		spr.set("empty");

		if( triggerId<0 )
			trigger();
	}

	override function trigger() {
		super.trigger();

		if( data.f_startDelay<=0 )
			startFire();
		else {
			cd.setS("triggered", Const.INFINITE);
			cd.setS("startFireLock", data.f_startDelay);
		}
	}

	function startFire() {
		dn.Bresenham.iterateDisc( cx, cy, data.f_range, (x,y)->{
			var fs = level.getFireState(x,y);
			if( fs!=null )
				fs.underControlS = 0;
			level.ignite(x,y, data.f_startFireLevel);
			if( fs!=null ) {
				fs.magic = data.f_magic;
				fs.resistance = data.f_resistance;
			}
		});

		if( data.f_explodesOnTrigger ) {
			camera.shakeS(1, 0.4);
			game.addSlowMo("fireStarterExplosion", 1, 0.5);
			fx.flashBangS(0xffcc00, 0.3, 1);
			fx.explosion(centerX, centerY);
		}

		destroy();
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		// Delayed start
		if( cd.has("triggered") && !cd.has("startFireLock") )
			startFire();
	}
}