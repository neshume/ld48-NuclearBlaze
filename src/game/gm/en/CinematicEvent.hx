package gm.en;

class CinematicEvent extends Entity {
	var data : Entity_CinematicEvent;

	public function new(d:Entity_CinematicEvent) {
		data = d;
		super(data.cx, data.cy);
		triggerId = data.f_triggerId;
		gravityMul = 0;
		collides = false;
		spr.set("empty");
	}

	override function trigger() {
		super.trigger();

		if( data.f_triggerDelay>0 && !cd.has("triggered") ) {
			cd.setS("triggered", Const.INFINITE);
			cd.setS("triggerLock", data.f_triggerDelay);
		}
		else if( data.f_triggerDelay<=0 )
			executeEvent();
	}

	function executeEvent() {
		switch data.f_eventType {
			case ShieldHero:
				hero.setShield(data.f_duration, false);

			case LockControlsUntilLand:
				hero.cd.setS("fallLock", 99);

			case BumpAndLockHero:
				if( hero.climbing )
					hero.stopClimbing();
				hero.cancelVelocities();
				hero.bump( data.f_x, data.f_y );
				if( data.f_duration>0 ) {
					hero.lockControlsS(data.f_duration);
					hero.cd.setS("dirLock", data.f_duration);
				}

			case LockHero:
				hero.lockControlsS(data.f_duration);
				hero.cd.setS("dirLock", data.f_duration);


			case Explosion:
				fx.explosion(data.pixelX, data.pixelY);
				camera.shakeS(1, 0.4);
				game.addSlowMo("cinematicExplosion", 1, 0.5);
				fx.flashBangS(0xffcc00, 0.3, 1);

			case CamShake:
				camera.shakeS(data.f_duration, data.f_power);

			case CamShoulder:
				camera.setShoulderIntensity(data.f_power);

			case ForceFastFall:
				hero.forceFastFall();
		}

		destroy();
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		// Self triggering
		if( data.f_selfTriggerDist>0 && hero.isAlive() && distCase(hero)<=data.f_selfTriggerDist )
			trigger();

		// Delayed trigger
		if( cd.has("triggered") && !cd.has("triggerLock") )
			executeEvent();
	}
}